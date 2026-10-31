# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "optparse"
require "rbconfig"
require "tempfile"
require "time"
require "tmpdir"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "arpaka"
require_relative "compatibility/normalizer"

module Compatibility
  class ConfigurationError < StandardError; end

  class Runner
    STATUSES = %w[match accepted_mismatch mismatch unverified parse_failure timeout error].freeze
    VERSION = 2

    def initialize(ruby_source:, corpora:, timeout: 10, ruby: RbConfig.ruby, progress: nil, reference_cache: nil, threads: 1, parallel: :thread, disable_gc: false, frontend: nil)
      @ruby_source = File.expand_path(ruby_source)
      @corpora = corpora.map { |name, path| [name, File.expand_path(path)] }
      @timeout = timeout
      @ruby = ruby
      @progress = progress
      @reference_cache_path = reference_cache && File.expand_path(reference_cache)
      @reference_cache = load_reference_cache
      @threads = Integer(threads)
      @parallel = parallel.to_sym
      @disable_gc = disable_gc
      @frontend = frontend && File.expand_path(frontend)
    end

    def run
      validate!
      @started_at = Time.now.utc.iso8601
      @measurement_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @gc_before = GC.stat
      if @frontend
        @frontend_class = load(@frontend).then { Object.const_get(:CompatibilityFrontend) }
        results = run_comparison(@frontend)
        [results, metadata(@frontend, results)]
      else
        generated = Arpaka.generate(ruby_source: @ruby_source, class_name: "CompatibilityFrontend")
        Dir.mktmpdir("arpaka-compatibility-") do |directory|
          frontend = File.join(directory, "frontend.rb")
          File.write(frontend, generated)
          @frontend_class = load(frontend).then { Object.const_get(:CompatibilityFrontend) }
          results = run_comparison(frontend)
          [results, metadata(frontend, results)]
        end
      end
    end

    def run_comparison(frontend)
      results = @corpora.flat_map do |name, path|
        files = corpus_files(name, path)
        @progress&.call("#{name}: comparing #{files.length} Ruby files")
        compare_files(name, path, files, frontend)
      end
      results
    end

    def self.emit(results, metadata, report_path: nil, output: $stdout)
      summary = metadata.merge("type" => "summary", "version" => VERSION,
        "counts" => STATUSES.to_h { |status| [status, results.count { |result| result.fetch("status") == status }] },
        "parsing" => %w[rubyvm arpaka].to_h do |side|
          outcomes = results.map { |file| file.fetch("outcomes").fetch(side) }
          [side, { "succeeded" => outcomes.count { |value| value["parsed"] == true },
            "failed" => outcomes.count { |value| value["parsed"] == false },
            "unknown" => outcomes.count { |value| !value.key?("parsed") } }]
        end,
        "total" => results.length,
        "corpora" => results.group_by { |result| result.fetch("corpus") }.transform_values do |files|
          { "total" => files.length,
            "counts" => STATUSES.to_h { |status| [status, files.count { |file| file.fetch("status") == status }] } }
        end,
        "full_match_rate" => results.empty? ? 0.0 : results.count { |result| result.fetch("status") == "match" }.fdiv(results.length),
        "match_or_accepted_rate" => results.empty? ? 0.0 : results.count do |result|
          %w[match accepted_mismatch].include?(result.fetch("status"))
        end.fdiv(results.length))
      lines = results.map { |result| JSON.generate(json_safe(result), max_nesting: false) } +
        [JSON.generate(json_safe(summary), max_nesting: false)]
      if report_path
        File.write(report_path, lines.join("\n") + "\n")
        output.puts JSON.generate(json_safe(summary), max_nesting: false)
      else
        output.puts lines
      end
      !results.empty? && results.all? { |result| %w[match accepted_mismatch].include?(result.fetch("status")) } ? 0 : 1
    end

    def self.json_safe(value)
      case value
      when String then value.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�")
      when Array then value.map { |item| json_safe(item) }
      when Hash then value.to_h { |key, item| [json_safe(key), json_safe(item)] }
      else value
      end
    end

    private

    def validate!
      raise ConfigurationError, "Ruby source does not exist: #{@ruby_source}" unless File.directory?(@ruby_source)
      if @frontend
        raise ConfigurationError, "frontend does not exist: #{@frontend}" unless File.file?(@frontend)
      end
      raise ConfigurationError, "at least one --corpus NAME=PATH is required" if @corpora.empty?
      names = @corpora.map(&:first)
      raise ConfigurationError, "corpus names must be unique" unless names.uniq.length == names.length
      @corpora.each do |name, path|
        raise ConfigurationError, "invalid corpus name: #{name}" unless name.match?(/\A[a-zA-Z0-9_.-]+\z/)
        raise ConfigurationError, "corpus does not exist: #{path}" unless File.exist?(path)
        raise ConfigurationError, "corpus has no Ruby files: #{path}" if corpus_files(name, path).empty?
      end
      raise ConfigurationError, "timeout must be finite and positive" unless @timeout.finite? && @timeout.positive?
      raise ConfigurationError, "threads must be positive" unless @threads.positive?
      raise ConfigurationError, "reference cache is required for verification" unless @reference_cache_path
      raise ConfigurationError, "parallel must be thread or ractor" unless %i[thread ractor].include?(@parallel)
    end

    def corpus_files(_name, path)
      return [File.expand_path(path)] if File.file?(path) && path.end_with?(".rb")
      Dir.glob(File.join(path, "**", "*.rb")).sort
    end

    def compare_files(name, root, files, frontend)
      return compare_files_with_threads(name, root, files, frontend) if @parallel == :thread

      compare_files_with_ractors(name, root, files, frontend)
    end

    def compare_files_with_threads(name, root, files, frontend)
      batches = files.each_slice((files.length.fdiv(@threads)).ceil).to_a
      workers = batches.map { |batch| Thread.new { compare_batch(name, root, batch, frontend) } }
      results = []
      workers.each do |worker|
        results.concat(worker.value)
        report_progress(name, results.length, files.length)
      end
      results
    end

    def compare_files_with_ractors(name, root, files, frontend)
      batches = files.each_slice((files.length.fdiv(@threads)).ceil).to_a
      frontend_class = @frontend_class
      port = Ractor::Port.new
      workers = batches.each_with_index.map do |batch, index|
        Ractor.new(port, index, name, root, batch, frontend_class, @disable_gc) do |result_port, job_index, job_name, job_root, job_files, job_frontend_class, disable_gc|
          begin
            GC.disable if disable_gc
            normalizer = Compatibility::Normalizer.new
            batch_results = job_files.to_h do |file|
              started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              begin
                source = File.binread(file).force_encoding(Encoding::UTF_8)
                tree = job_frontend_class.parse(source, filename: file)
                # Match the JSON boundary used by the subprocess worker. In
                # particular, symbols in the canonical tree become strings.
                canonical = JSON.parse(JSON.generate(normalizer.arpaka(tree), max_nesting: false))
                arpaka = { status: "ok", parsed: true, tree: canonical,
                  elapsed: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
                  runtime: RUBY_DESCRIPTION, ruby_box: false }
              rescue Compatibility::Unsupported => error
                arpaka = { status: "unverified", parsed: true,
                  elapsed: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
                  side: error.side, reason: error.detail }
              rescue SyntaxError, StandardError => error
                arpaka = { status: "parse_failure", parsed: false,
                  elapsed: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
                  reason: "#{error.class}: #{error.message}" }
              end
              [file, arpaka]
            end
          rescue Exception => error
            batch_results = job_files.to_h do |file|
              [file, { status: "error", parsed: false, elapsed: 0.0,
                reason: "Ractor worker: #{error.class}: #{error.message} (#{error.backtrace&.first(3)&.join(" | ")})" }]
            end
          end
          result_port.send([job_index, batch_results])
        end
      end
      results = Array.new(batches.length)
      completed = 0
      watchdog = Thread.new do
        sleep(@timeout * files.length + 5)
        port.send([:timeout, []])
      end
      begin
        batches.length.times do
          index, batch_results = port.receive
          raise ConfigurationError, "Ractor batch exceeded timeout" if index == :timeout
        results[index] = batch_results.map do |file, arpaka|
          runner = self
          runner.__send__(:compare_direct, name, root, file, arpaka)
        end
          completed += batch_results.length
          report_progress(name, completed, files.length)
        end
      ensure
        watchdog.kill
        workers.each { |worker| worker.close rescue nil }
      end
      results.flatten
    end

    def compare_batch(name, root, files, frontend)
      entries = files.to_h do |file|
        rel = File.file?(root) ? File.basename(file) : file.delete_prefix(File.expand_path(root) + File::SEPARATOR)
        source = File.binread(file)
        [file, [rel, Digest::SHA256.hexdigest(source)]]
      end
      manifest = Tempfile.new(["compatibility-manifest-", ".jsonl"])
      files.each { |file| manifest.puts JSON.generate("path" => file, "filename" => file) }
      manifest.flush
      arpaka = invoke_many("arpaka", frontend, manifest.path, files)
      files.map do |file|
        rel, sha256 = entries.fetch(file)
        reference = @reference_cache[[name, rel, sha256]]
        reference ||= { status: "error", elapsed: 0.0, reason: "reference cache miss" }
        compare(name, root, file, frontend, worker_results: [reference, arpaka.fetch(file)])
      end
    ensure
      manifest&.close!
    end

    def report_progress(name, completed, total)
      @progress&.call("#{name}: #{completed}/#{total} compared") if completed % 250 == 0 || completed == total
    end

    def compare(name, root, file, frontend, worker_results: nil)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      rel = File.file?(root) ? File.basename(file) : file.delete_prefix(File.expand_path(root) + File::SEPARATOR)
      source = File.binread(file)
      input_hash = Digest::SHA256.hexdigest(source)
      vm, arpaka = worker_results || raise(ConfigurationError, "comparison requires worker results")
      outcomes = { "rubyvm" => outcome(vm), "arpaka" => outcome(arpaka) }
      statuses = [vm, arpaka].map { |side| side[:status] }
      unverified_reason = comparison_limit(vm[:tree], arpaka[:tree]) if statuses == ["ok", "ok"]
      status = if statuses.include?("error") then "error"
      elsif statuses.include?("timeout") then "timeout"
      elsif statuses.include?("parse_failure") then "parse_failure"
      elsif statuses.include?("unverified") then "unverified"
      elsif statuses != ["ok", "ok"] then "error"
      elsif unverified_reason then "unverified"
      else
        comparison, = compare_trees(vm[:tree], arpaka[:tree])
        comparison.to_s
      end
      result = { "type" => "file", "corpus" => name, "path" => rel, "sha256" => input_hash,
        "status" => status, "elapsed_seconds" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
        "outcomes" => outcomes }
      result["reason"] = unverified_reason if unverified_reason
      if %w[accepted_mismatch mismatch].include?(status)
        difference = status == "mismatch" ? first_mismatch(vm[:tree], arpaka[:tree]) : nil
        path, expected, actual = difference || first_difference(vm[:tree], arpaka[:tree])
        result["difference"] = { "path" => path, "rubyvm" => excerpt(expected), "arpaka" => excerpt(actual) }
        result["reason"] = "keyword arguments are represented as HASH in RubyVM AST" if status == "accepted_mismatch"
      end
      result
    rescue SystemCallError => error
      reason = "#{error.class}: #{error.message}"
      { "type" => "file", "corpus" => name, "path" => rel, "sha256" => nil,
        "status" => "error", "elapsed_seconds" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
        "outcomes" => %w[rubyvm arpaka].to_h do |side|
          [side, { "status" => "error", "stage" => "input", "reason" => reason }]
        end }
    end

    def compare_direct(name, root, file, arpaka)
      rel = File.file?(root) ? File.basename(file) : file.delete_prefix(File.expand_path(root) + File::SEPARATOR)
      input_hash = Digest::SHA256.hexdigest(File.binread(file))
      reference = @reference_cache[[name, rel, input_hash]] ||
        { status: "error", elapsed: 0.0, reason: "reference cache miss" }
      compare(name, root, file, nil, worker_results: [reference, arpaka])
    end

    def load_reference_cache
      return {} unless @reference_cache_path && File.file?(@reference_cache_path)

      each_reference_line.each_with_object({}) do |line, cache|
        record = JSON.parse(line, max_nesting: false)
        next unless record["type"] == "reference"
        value = record.transform_keys(&:to_sym)
        value[:elapsed] = value.delete(:elapsed_seconds)
        cache[[record["corpus"], record["path"], record["sha256"]]] = value
      rescue JSON::ParserError
        next
      end
    end

    def invoke_many(mode, frontend, manifest, files)
      out = Tempfile.new("compatibility-batch-out")
      err = Tempfile.new("compatibility-batch-err")
      env = { "RUBY_BOX" => nil, "RUBYOPT" => nil }
      env["ARPAKA_DISABLE_GC"] = "1" if @disable_gc
      command = [@ruby, "--disable-gems", File.expand_path("compatibility/worker.rb", __dir__), mode, frontend, manifest, "--manifest"]
      pid = Process.spawn(env, *command, out: out, err: err)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + (@timeout * files.length)
      loop do
        break if Process.waitpid(pid, Process::WNOHANG)
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          Process.kill("TERM", -pid) rescue nil
          Process.kill("KILL", -pid) rescue nil
          Process.waitpid(pid) rescue nil
          raise ConfigurationError, "#{mode} batch exceeded timeout"
        end
        sleep 0.01
      end
      out.rewind
      parsed = out.each_line.map { |line| JSON.parse(line, symbolize_names: true, max_nesting: false) }
      parsed.to_h do |value|
        value[:elapsed] = value.delete(:elapsed_seconds)
        [value.fetch(:path), value]
      end.tap do |results|
        files.each do |file|
          results[file] ||= { status: :error, elapsed: 0.0, reason: "worker omitted result" }
        end
      end
    ensure
      out&.close!
      err&.close!
    end

    def each_reference_line
      return enum_for(__method__) unless block_given?

      if @reference_cache_path.end_with?(".xz")
        IO.popen(["xz", "-dc", "--", @reference_cache_path], err: File::NULL) do |input|
          input.each_line { |line| yield line }
        end
      else
        File.foreach(@reference_cache_path) { |line| yield line }
      end
    rescue Errno::ENOENT => error
      raise ConfigurationError, "xz is required to read #{@reference_cache_path}: #{error.message}"
    end

    def outcome(value)
      { "status" => value[:status], "elapsed_seconds" => value[:elapsed] }.tap do |result|
        %i[reason side stage parsed runtime ruby_box].each do |key|
          result[key.to_s] = value[key] if value.key?(key)
        end
      end
    end

    def first_difference(left, right, path = "$")
      return [path, left, right] unless left.class == right.class
      return [path, left, right] unless left.is_a?(Array)
      [left.length, right.length].min.times do |index|
        next if left[index] == right[index]
        return first_difference(left[index], right[index], "#{path}[#{index}]")
      end
      if left.length != right.length
        index = [left.length, right.length].min
        absent = { "missing_element" => true }
        return ["#{path}[#{index}]", left.fetch(index, absent), right.fetch(index, absent)]
      end
      [path, left, right]
    end

    def first_mismatch(left, right, path = "$", keyword_argument: false)
      return if left == right

      if keyword_argument && keyword_arguments_as_hash?(left, right)
        return first_mismatch(left[1], right[1], "#{path}[1]")
      end

      if call_node?(left) && call_node?(right)
        (1..3).each do |index|
          difference = first_mismatch(left[index], right[index], "#{path}[#{index}]")
          return difference if difference
        end
        return first_argument_mismatch(left[4], right[4], "#{path}[4]")
      end

      unless left.is_a?(Array) && right.is_a?(Array) && left.length == right.length
        return [path, left, right]
      end

      left.each_index do |index|
        difference = first_mismatch(left[index], right[index], "#{path}[#{index}]")
        return difference if difference
      end
      nil
    end

    def first_argument_mismatch(left, right, path)
      unless left.is_a?(Array) && right.is_a?(Array) && left.length == right.length
        return [path, left, right]
      end

      left.each_index do |index|
        difference = first_mismatch(left[index], right[index], "#{path}[#{index}]", keyword_argument: true)
        return difference if difference
      end
      nil
    end

    def compare_trees(left, right, path = "$", keyword_argument: false)
      return [:match, nil] if left == right

      if keyword_argument && keyword_arguments_as_hash?(left, right)
        status, = compare_trees(left[1], right[1], "#{path}[1]")
        return status == :mismatch ? [:mismatch, nil] : [:accepted_mismatch, path]
      end

      if call_node?(left) && call_node?(right)
        fixed_statuses = (1..3).map do |index|
          compare_trees(left[index], right[index], "#{path}[#{index}]").first
        end
        return [:mismatch, nil] if fixed_statuses.include?(:mismatch)

        arguments_status = compare_argument_lists(left[4], right[4], "#{path}[4]")
        return [:mismatch, nil] if arguments_status == :mismatch
        return [:accepted_mismatch, path] if arguments_status == :accepted_mismatch || fixed_statuses.include?(:accepted_mismatch)
        return [:match, nil]
      end

      return [:mismatch, nil] unless left.is_a?(Array) && right.is_a?(Array) && left.length == right.length

      statuses = left.each_index.map { |index| compare_trees(left[index], right[index], "#{path}[#{index}]").first }
      return [:mismatch, nil] if statuses.include?(:mismatch)
      return [:accepted_mismatch, path] if statuses.include?(:accepted_mismatch)
      [:match, nil]
    end

    def compare_argument_lists(left, right, path)
      return :mismatch unless left.is_a?(Array) && right.is_a?(Array) && left.length == right.length
      statuses = left.each_index.map do |index|
        compare_trees(left[index], right[index], "#{path}[#{index}]", keyword_argument: true).first
      end
      return :mismatch if statuses.include?(:mismatch)
      return :accepted_mismatch if statuses.include?(:accepted_mismatch)
      :match
    end

    def call_node?(value)
      value.is_a?(Array) && value.length == 5 && tag?(value.first, :call)
    end

    def keyword_arguments_as_hash?(left, right)
      left.is_a?(Array) && right.is_a?(Array) && left.length == 2 && right.length == 2 &&
        ((tag?(left.first, :keyword_arguments) && tag?(right.first, :hash)) ||
          (tag?(left.first, :hash) && tag?(right.first, :keyword_arguments)))
    end

    def tag?(value, expected)
      value == expected || value == expected.to_s
    end

    # The frontend cannot express these fields. If the reference also needs no
    # value, absence alone does not establish a semantic defect or agreement.
    def comparison_limit(reference, candidate)
      if reference == ["unknown", "options"] && candidate.is_a?(Array) && candidate.first == "known"
        return "interpolated regexp options are absent from RubyVM AST"
      end
      if reference == ["unknown", "encoding"] && candidate.is_a?(Array) && candidate.first == "known"
        return "interpolated regexp encoding is absent from RubyVM AST"
      end
      if reference == ["retained_arguments", []] && candidate == ["missing"]
        return "block parameter information is absent; the reference has no parameters"
      end
      return unless reference.is_a?(Array) && candidate.is_a?(Array)
      [reference.length, candidate.length].min.times do |index|
        reason = comparison_limit(reference[index], candidate[index])
        return reason if reason
      end
      nil
    end

    def excerpt(value)
      text = JSON.generate(self.class.json_safe(value), max_nesting: false)
      text.length > 400 ? text[0, 397] + "..." : text
    end

    def metadata(frontend, results)
      manifests = @corpora.to_h do |name, _path|
        pairs = results.select { |file| file.fetch("corpus") == name }.map { |file| [file.fetch("path"), file.fetch("sha256")] }
        [name, Digest::SHA256.hexdigest(JSON.generate(pairs))]
      end
      inputs = %w[parse.y defs/id.def COPYING BSDL].to_h do |relative|
        [relative, Digest::SHA256.file(File.join(@ruby_source, relative)).hexdigest]
      end
      root = File.expand_path("..", __dir__)
      implementation = [__FILE__, *Dir.glob(File.join(__dir__, "compatibility", "*.rb"))].sort.to_h do |file|
        [file.delete_prefix(root + File::SEPARATOR), Digest::SHA256.file(file).hexdigest]
      end
      { "runtime" => RUBY_DESCRIPTION, "ruby_source" => @ruby_source,
        "started_at" => @started_at, "completed_at" => Time.now.utc.iso8601,
        "elapsed_seconds" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - @measurement_started,
        "gc" => gc_delta,
        "ruby_source_files" => inputs, "ruby_source_sha256" => Digest::SHA256.hexdigest(JSON.generate(inputs)),
        "generated_sha256" => Digest::SHA256.file(frontend).hexdigest,
        "frontend" => frontend,
        "benchmark_files_sha256" => implementation,
        "git_commit" => git("rev-parse", "HEAD"), "git_dirty" => !git("status", "--porcelain").to_s.empty?,
        "corpus_sources" => @corpora.to_h do |name, path|
          directory = File.directory?(path) ? path : File.dirname(path)
          [name, { "path" => path, "git_commit" => git("rev-parse", "HEAD", directory: directory) }]
        end,
        "timeout_seconds" => @timeout, "timeout_scope" => "worker startup, parsing and normalization",
        "disable_gc" => @disable_gc,
        "corpus_manifest_sha256" => manifests, "file_count" => results.length }
    end

    def gc_delta
      before = @gc_before || {}
      after = GC.stat
      keys = %i[heap_live_slots heap_allocated_pages total_allocated_objects minor_gc_count major_gc_count]
      keys.to_h { |key| [key.to_s, after.fetch(key) - before.fetch(key, 0)] }
    end

    def git(*args, directory: File.expand_path("..", __dir__))
      output, status = Open3.capture2("git", *args, chdir: directory, err: File::NULL)
      status.success? ? output.strip : nil
    rescue StandardError
      nil
    end
  end

  class CLI
    def self.run(argv)
      corpora = []
      options = { ruby_source: File.expand_path("../vendor/ruby", __dir__), timeout: 10, threads: 1, parallel: :thread, disable_gc: false, frontend: nil }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: RUBY_BOX=1 bundle exec ruby benchmark/compatibility.rb --corpus NAME=PATH [options]"
        opts.on("--corpus NAME=PATH", "Corpus directory or Ruby file; repeatable") do |value|
          name, path = value.split("=", 2)
          raise ConfigurationError, "expected NAME=PATH for --corpus" unless name && path && !name.empty? && !path.empty?
          corpora << [name, File.expand_path(path)]
        end
        opts.on("--report PATH", "Write per-file JSONL and summary to PATH (default: stdout)") { |value| options[:report] = value }
        opts.on("--reference-cache PATH", "Read/write RubyVM normalized AST JSONL cache") { |value| options[:reference_cache] = value }
        opts.on("--frontend PATH", "Use a pre-generated frontend instead of generating one") { |value| options[:frontend] = value }
        opts.on("--threads N", Integer, "Number of concurrent comparisons (default: 1)") { |value| options[:threads] = value }
        opts.on("--parallel MODE", %w[thread ractor], "Parallel mode (default: thread)") { |value| options[:parallel] = value.to_sym }
        opts.on("--disable-gc", "Disable GC in Ractor workers (default: enabled)") { options[:disable_gc] = true }
        opts.on("--ruby-source PATH", "Ruby source tree (default: vendor/ruby)") { |value| options[:ruby_source] = value }
        opts.on("--timeout SECONDS", Float, "Timeout per parser and file (default: 10)") { |value| options[:timeout] = value }
        opts.on("-h", "--help", "Show help") { puts opts; return 0 }
      end
      parser.parse!(argv)
      raise ConfigurationError, "unexpected arguments: #{argv.join(' ')}" unless argv.empty?
      results, metadata = Runner.new(ruby_source: options[:ruby_source], corpora: corpora,
        timeout: options[:timeout], reference_cache: options[:reference_cache],
        threads: options[:threads],
        parallel: options[:parallel],
        disable_gc: options[:disable_gc],
        frontend: options[:frontend],
        progress: ->(message) { warn message }).run
      Runner.emit(results, metadata, report_path: options[:report])
    rescue ConfigurationError, OptionParser::ParseError => error
      warn "compatibility: #{error.message}"
      2
    rescue StandardError => error
      warn "compatibility: #{error.class}: #{error.message}"
      2
    end
  end
end

exit Compatibility::CLI.run(ARGV) if $PROGRAM_NAME == __FILE__

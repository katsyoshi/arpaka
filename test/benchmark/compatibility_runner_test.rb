# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "stringio"
require_relative "../../benchmark/compatibility"

class CompatibilityRunnerTest < Test::Unit::TestCase
  SOURCE = File.expand_path("../../vendor/ruby", __dir__)
  FIXTURES = File.expand_path("../../benchmark/fixtures", __dir__)

  test "real workers distinguish agreement, information loss, unsupported syntax and parse failure" do
    Dir.mktmpdir("compatibility-test-") do |directory|
      File.write(File.join(directory, "invalid.rb"), "def\n")
      File.write(File.join(directory, "empty_block.rb"), "items.each do\nend\n")
      File.write(File.join(directory, "plain_regexp.rb"), "/abc/\n")
      File.write(File.join(directory, "interpolated_regexp.rb"), "%r{prefix\#{value}suffix}im\n")
      results, metadata = Compatibility::Runner.new(ruby_source: SOURCE,
        corpora: [["examples", FIXTURES], ["invalid", directory]]).run
      examples = results.select { |file| file.fetch("corpus") == "examples" }.to_h do |file|
        [file.fetch("path"), file]
      end
      assert_equal("match", examples.fetch("basic_match.rb").fetch("status"))
      %w[splat.rb optional_default_one.rb optional_default_two.rb
        method_local_scope.rb].each do |file|
        assert_equal("mismatch", examples.fetch(file).fetch("status"), file)
        assert_not_nil(examples.fetch(file)["difference"])
      end
      assert_equal("match", examples.fetch("block_parameter.rb").fetch("status"))
      assert_equal("match", examples.fetch("ambiguous_self.rb").fetch("status"))
      file = results.find { |entry| entry.fetch("corpus") == "invalid" && entry.fetch("path") == "empty_block.rb" }
      assert_equal("match", file.fetch("status"))
      assert(file.fetch("outcomes").values.all? { |outcome| outcome.fetch("parsed") })
      regexp = results.find { |entry| entry.fetch("corpus") == "invalid" && entry.fetch("path") == "plain_regexp.rb" }
      assert_equal("match", regexp.fetch("status"))
      interpolated_regexp = results.find do |entry|
        entry.fetch("corpus") == "invalid" && entry.fetch("path") == "interpolated_regexp.rb"
      end
      assert_equal("unverified", interpolated_regexp.fetch("status"))
      assert_match(/options are absent from RubyVM AST/, interpolated_regexp.fetch("reason"))
      invalid = results.find { |file| file.fetch("corpus") == "invalid" && file.fetch("path") == "invalid.rb" }
      assert_equal("parse_failure", invalid.fetch("status"))
      invalid.fetch("outcomes").each_value do |outcome|
        assert_equal(false, outcome.fetch("parsed"))
        assert_include(outcome.fetch("reason"), "Error")
      end
      examples.each_value do |file|
        assert_equal(Digest::SHA256.file(File.join(FIXTURES, file.fetch("path"))).hexdigest,
          file.fetch("sha256"))
        file.fetch("outcomes").each_value do |outcome|
          assert_equal(false, outcome.fetch("ruby_box"))
          assert_equal(true, outcome.fetch("parsed"))
        end
      end
      assert_match(/\A[0-9a-f]{64}\z/, metadata.fetch("generated_sha256"))
      assert_match(/\A[0-9a-f]{64}\z/, metadata.fetch("corpus_manifest_sha256").fetch("examples"))
      assert_equal("parse.y", metadata.fetch("ruby_source_files").keys.first)
      report = File.join(directory, "report.jsonl")
      output = StringIO.new
      assert_equal(1, Compatibility::Runner.emit(results, metadata, report_path: report, output: output))
      records = File.readlines(report).map { |line| JSON.parse(line) }
      assert_equal(results.length + 1, records.length)
      summary = records.last
      assert_equal(results.length, summary.fetch("counts").values.sum)
      assert_equal(7, summary.fetch("counts").fetch("match"))
      assert_equal(1, summary.fetch("counts").fetch("parse_failure"))
      assert_equal(examples.length, summary.fetch("corpora").fetch("examples").fetch("total"))
    end
  end

  test "missing empty and duplicate corpus selections are configuration errors" do
    Dir.mktmpdir("compatibility-empty-") do |directory|
      [[], [["missing", File.join(directory, "absent")]], [["empty", directory]],
        [["duplicate", FIXTURES], ["duplicate", FIXTURES]]].each do |corpora|
        assert_raise(Compatibility::ConfigurationError) do
          Compatibility::Runner.new(ruby_source: SOURCE, corpora: corpora).run
        end
      end
    end
  end

  test "only keyword argument representation differences are accepted" do
    Dir.mktmpdir("compatibility-keyword-arguments-") do |directory|
      File.write(File.join(directory, "keyword_argument.rb"), "foo(name: 1)\n")
      File.write(File.join(directory, "hash_argument.rb"), "foo({name: 1})\n")
      results, metadata = Compatibility::Runner.new(ruby_source: SOURCE,
        corpora: [["arguments", directory]]).run
      files = results.to_h { |file| [file.fetch("path"), file] }

      accepted = files.fetch("keyword_argument.rb")
      assert_equal("accepted_mismatch", accepted.fetch("status"))
      assert_match(/keyword arguments/, accepted.fetch("reason"))
      assert_equal("match", files.fetch("hash_argument.rb").fetch("status"))

      output = StringIO.new
      assert_equal(0, Compatibility::Runner.emit(results, metadata, output: output))
      summary = JSON.parse(output.string.lines.last)
      assert_equal(1, summary.fetch("counts").fetch("accepted_mismatch"))
      assert_equal(1, summary.fetch("counts").fetch("match"))
    end
  end

  test "an internal normalization exception cannot turn two absent trees into agreement" do
    Dir.mktmpdir("compatibility-error-") do |directory|
      input = File.join(directory, "input.rb")
      frontend = File.join(directory, "frontend.rb")
      File.write(input, "1\n")
      File.write(frontend, <<~RUBY)
        class CompatibilityFrontend
          def self.parse(*)
            Object.new.tap do |node|
              def node.members
                raise "normalizer field access failed"
              end
            end
          end
        end
      RUBY
      runner = Compatibility::Runner.new(ruby_source: SOURCE, corpora: [["input", input]])
      outcome = runner.send(:invoke, "arpaka", frontend, input)
      assert_equal("error", outcome.fetch(:status))
      assert_equal("normalize", outcome.fetch(:stage))
      assert_equal(true, outcome.fetch(:parsed))
      assert_not_nil(outcome[:reason])

      failed_ruby = File.join(directory, "failed-ruby")
      File.write(failed_ruby, "#!#{RbConfig.ruby}\nputs %q({\"status\":\"error\",\"reason\":\"worker failed\"})\n")
      File.chmod(0o755, failed_ruby)
      failed_runner = Compatibility::Runner.new(ruby_source: SOURCE, corpora: [["input", input]], ruby: failed_ruby)
      result = failed_runner.send(:compare, "input", input, input, frontend)
      assert_equal("error", result.fetch("status"))
    end
  end

  test "a stalled worker is terminated and reported as a timeout" do
    Dir.mktmpdir("compatibility-timeout-") do |directory|
      executable = File.join(directory, "stalled-ruby")
      File.write(executable, "#!/bin/sh\nexec sleep 30\n")
      File.chmod(0o755, executable)
      runner = Compatibility::Runner.new(ruby_source: SOURCE, corpora: [["examples", FIXTURES]],
        ruby: executable, timeout: 0.05)
      outcome = runner.send(:invoke, "rubyvm", "unused", "unused")
      assert_equal("timeout", outcome.fetch(:status))
      assert_operator(outcome.fetch(:elapsed), :<, 2)
    end
  end

end

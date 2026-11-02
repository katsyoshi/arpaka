# frozen_string_literal: true

require "json"
require_relative "normalizer"

GC.disable if ENV["ARPAKA_DISABLE_GC"] == "1"

mode, frontend_path, input_path, filename = ARGV
abort "usage: worker.rb MODE FRONTEND INPUT [FILENAME]" unless %w[arpaka rubyvm].include?(mode) && input_path
inputs = if filename == "--manifest"
  File.foreach(input_path).map { |line| JSON.parse(line) }
else
  [{ "path" => input_path, "filename" => filename || input_path }]
end
normalizer = Compatibility::Normalizer.new
runtime = { runtime: RUBY_DESCRIPTION, ruby_box: Ruby::Box.enabled? }
emit = lambda do |input, outcome|
  puts JSON.generate(runtime.merge(outcome).merge("path" => input.fetch("path")), max_nesting: false)
end
diagnostic = lambda do |error|
  "#{error.class}: #{error.message}".encode(Encoding::UTF_8, invalid: :replace, undef: :replace)[0, 2_000]
end

raise "comparison worker must run with Ruby Box disabled" if Ruby::Box.enabled?
require frontend_path if mode == "arpaka"

inputs.each do |input|
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  source = File.binread(input.fetch("path")).force_encoding(Encoding::UTF_8).gsub("\r\n", "\n")
  begin
    tree = if mode == "arpaka"
      Object.const_get(:CompatibilityFrontend).parse(source, filename: input.fetch("filename"))
    else
      RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
    end
  rescue SyntaxError, StandardError => error
    emit.call(input, status: "parse_failure", stage: "parse", parsed: false, elapsed_seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, reason: diagnostic.call(error))
    next
  end

  begin
    canonical = if mode == "arpaka"
      normalizer.arpaka(tree)
    else
      unless tree.type == :SCOPE && tree.children.length == 3 && tree.children[1].nil?
        raise Compatibility::Unsupported.new(:rubyvm, "unsupported root scope shape")
      end
      value = normalizer.rubyvm(tree.children.fetch(2))
      value.is_a?(Array) && value.first == :sequence ? value : [:sequence, value.nil? ? [] : [value]]
    end
    emit.call(input, status: "ok", parsed: true, elapsed_seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, tree: canonical)
  rescue Compatibility::Unsupported => error
    emit.call(input, status: "unverified", stage: "normalize", parsed: true, elapsed_seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, side: error.side, reason: error.detail)
  rescue StandardError => error
    emit.call(input, status: "error", stage: "normalize", parsed: true, elapsed_seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, reason: diagnostic.call(error))
  end
end

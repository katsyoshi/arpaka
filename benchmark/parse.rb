# frozen_string_literal: true

require "rbconfig"

iterations = Integer(ENV.fetch("ITERATIONS", "100"))
raise ArgumentError, "ITERATIONS must be positive" unless iterations.positive?
sources = {
  small: "value = 1\n",
  medium: (1..100).map { |index| "value#{index} = #{index} * 2\n" }.join + "value100 + 1\n",
  large: (1..1_000).map { |index| "value#{index} = #{index} * 2\n" }.join + "value1000 + 1\n"
}

def measure(label, iterations = 1)
  GC.start
  started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  result = nil
  iterations.times { result = yield }
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  puts format("%-34s %9.6fs total, %9.3fms/call", label, elapsed, elapsed * 1000 / iterations)
  result
end

if ARGV.first == "--runtime"
  ast_path = File.expand_path(ARGV.fetch(1))
  structured_path = File.expand_path(ARGV.fetch(2))
  puts "Runtime: #{RUBY_DESCRIPTION}; Ruby Box: #{Ruby::Box.enabled?}"
  measure("load AST frontend") { require ast_path }
  measure("load Structural Tree frontend") { require structured_path }
  sources.each do |size, source|
    puts "#{size}: #{source.bytesize} bytes"
    measure("AST parse #{size} (first)") { BenchmarkRubyAst.parse(source) }
    10.times { BenchmarkRubyAst.parse(source) }
    measure("AST parse #{size} (warm)", iterations) { BenchmarkRubyAst.parse(source) }
    measure("Structural Tree parse #{size} (first)") { BenchmarkRubyStructured.parse(source) }
    10.times { BenchmarkRubyStructured.parse(source) }
    measure("Structural Tree parse #{size} (warm)", iterations) { BenchmarkRubyStructured.parse(source) }
  end

  if defined?(RubyVM::AbstractSyntaxTree)
    sources.each do |size, source|
      10.times { RubyVM::AbstractSyntaxTree.parse(source) }
      measure("RubyVM AST #{size}", iterations) { RubyVM::AbstractSyntaxTree.parse(source) }
    end
  end
  require "prism"
  puts "Prism: #{Prism::VERSION}"
  sources.each do |size, source|
    10.times { Prism.parse(source) }
    measure("Prism #{size}", iterations) { Prism.parse(source) }
  end
else
  require "arpaka"
  require "tmpdir"
  ruby_source = ENV.fetch("RUBY_SOURCE", File.expand_path("../vendor/ruby", __dir__))
  puts "Arpaka frontend benchmark"
  puts "Generator: #{RUBY_DESCRIPTION}"
  puts "Inputs: small/medium/large; iterations: #{iterations}; warmup: 10"
  code = {}
  code[:ast] = measure("generate AST frontend") do
    Arpaka.generate(ruby_source: ruby_source, class_name: "BenchmarkRubyAst",
      ast_type: :detailed)
  end
  code[:structured] = measure("generate Structural Tree frontend") do
    Arpaka.generate(ruby_source: ruby_source, class_name: "BenchmarkRubyStructured",
      ast_type: :structured)
  end
  Dir.mktmpdir("arpaka-benchmark-") do |directory|
    ast_path = File.join(directory, "ast_frontend.rb")
    structured_path = File.join(directory, "structured_frontend.rb")
    File.write(ast_path, code[:ast])
    File.write(structured_path, code[:structured])
    flags = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? ["--yjit"] : []
    success = system({ "RUBY_BOX" => nil, "RUBYOPT" => nil },
      RbConfig.ruby, *flags, File.expand_path(__FILE__), "--runtime", ast_path, structured_path)
    abort "Runtime benchmark failed" unless success
  end
end

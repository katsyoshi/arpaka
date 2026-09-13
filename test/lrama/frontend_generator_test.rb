# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"
require "arpaka/cli"
require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"
require "stringio"

class FrontendGeneratorTest < Test::Unit::TestCase
  def generated_source
    self.class.instance_variable_get(:@source) ||
      self.class.instance_variable_set(:@source,
        Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: "StandaloneRuby"))
  end

  test "one relocated file parses without gems, Box, or source files" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "frontend.rb")
      File.write(path, generated_source)
      script = <<~'RUBY'
        require File.expand_path("frontend.rb")
        abort "Box enabled" if Ruby::Box.enabled?
        abort "unexpected dependency" if defined?(Arpaka) || defined?(Lrama)
        tree = StandaloneRuby.parse("a = 1\na + 2")
        abort "wrong AST" unless tree.statements.last.left.name == :a
        abort "leaked state" unless StandaloneRuby.parse("a").statements.first.is_a?(StandaloneRuby::AST::BareCall)
        abort "token API is public" if StandaloneRuby.respond_to?(:parse_tokens)
        begin
          StandaloneRuby.parse('"unterminated', filename: "broken.rb")
          abort "missing lexer error"
        rescue StandaloneRuby::LexerError => error
          abort error.message unless error.message.include?("broken.rb:1:")
        end
      RUBY
      output, error, result = Open3.capture3(
        { "RUBY_BOX" => nil, "RUBYOPT" => nil, "RUBYLIB" => nil },
        RbConfig.ruby, "--disable-gems", "-e", script, chdir: directory)
      assert_predicate(result, :success?, output + error)
    end
  end

  test "independent generated classes coexist without Box" do
    namespace = Module.new
    namespace.module_eval(generated_source)
    namespace.module_eval(Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: "OtherRuby"))
    first = namespace.const_get(:StandaloneRuby)
    second = namespace.const_get(:OtherRuby)
    assert_not_equal(first::AST::Program, second::AST::Program)
    assert_equal(2, second.parse("2").statements.first.value)
    assert_equal(1, first.parse("1").statements.first.value)
  end

  test "generation is deterministic and preserves provenance and notices" do
    assert_equal(generated_source, Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: "StandaloneRuby"))
    assert_include(generated_source, "parse.y SHA256:")
    assert_include(generated_source, "Yukihiro Matsumoto")
    assert_include(generated_source, "Redistribution and use in source and binary forms")
  end

  test "missing inputs and invalid class names produce generation errors" do
    assert_raise(Arpaka::Error) { Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: "A::B") }
    Dir.mktmpdir do |directory|
      error = assert_raise(Arpaka::Error) { Arpaka.generate(ruby_source: directory) }
      assert_include(error.message, "parse.y")
    end
  end

  test "changed upstream input is rejected before actions are applied" do
    Dir.mktmpdir do |directory|
      FileUtils.cp_r(File.join(RUBY_SOURCE, "."), directory)
      File.open(File.join(directory, "parse.y"), "a") { |file| file.puts("/* changed */") }
      error = assert_raise(Arpaka::Error) { Arpaka.generate(ruby_source: directory) }
      assert_include(error.message, "Unsupported Ruby source change: parse.y")
      assert_include(error.message, "SHA256")
    end
  end

  test "CLI requires output and handles help" do
    out, err = StringIO.new, StringIO.new
    assert_equal(0, Arpaka::CLI.run(["--help"], out: out, err: err))
    assert_include(out.string, "--ruby-source")
    assert_equal(1, Arpaka::CLI.run(["generate", "--ruby-source", RUBY_SOURCE], out: out, err: err))
    assert_include(err.string, "--output")
  end

  test "CLI writes complete output and requires force to replace it" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "frontend.rb")
      args = ["generate", "--ruby-source", RUBY_SOURCE, "--class-name", "CliRuby", "--output", path]
      out, err = StringIO.new, StringIO.new
      assert_equal(0, Arpaka::CLI.run(args, out: out, err: err), err.string)
      assert_include(File.read(path), "class CliRuby")
      File.write(path, "existing\n")
      assert_equal(1, Arpaka::CLI.run(args, out: out, err: err))
      assert_equal("existing\n", File.read(path))
      assert_equal(0, Arpaka::CLI.run(args + ["--force"], out: out, err: err), err.string)
      assert_include(File.read(path), "class CliRuby")
      File.write(path, "keep on failure\n")
      bad = ["generate", "--ruby-source", directory, "--output", path, "--force"]
      assert_equal(1, Arpaka::CLI.run(bad, out: out, err: err))
      assert_equal("keep on failure\n", File.read(path))
    end
  end

  test "compile returns a source parsing frontend and isolates names" do
    frontend = Arpaka.compile(ruby_source: RUBY_SOURCE, class_name: "IsolatedRuby")
    assert_equal(42, frontend.parse("42").statements.first.value)
    assert_false(Object.const_defined?(:IsolatedRuby, false))
    assert_false(Arpaka.respond_to?(:parse))
    assert_false(Lrama::Ruby.respond_to?(:parse))
  end
end

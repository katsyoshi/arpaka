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

  test "namespaced generated classes define namespaces and compile returns the class" do
    class_name = "A::B::Parser"
    source = Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: class_name)
    assert_include(source, "module A")
    assert_include(source, "module B")
    assert_include(source, "class Parser")

    host = Module.new
    host.module_eval(source)
    generated = host.const_get(:A).const_get(:B).const_get(:Parser)
    assert_equal("Parser", generated.name.split("::").last)
    assert_equal(42, generated.parse("42").statements.first.value)

    frontend = Arpaka.compile(ruby_source: RUBY_SOURCE, class_name: class_name)
    assert_equal(class_name, frontend.name)
    assert_equal(42, frontend.parse("42").statements.first.value)
    assert_false(Object.const_defined?(:A, false))
  end

  test "generation is deterministic and preserves provenance and notices" do
    assert_equal(generated_source, Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: "StandaloneRuby"))
    assert_include(generated_source, "parse.y SHA256:")
    assert_include(generated_source, "Yukihiro Matsumoto")
    assert_include(generated_source, "Redistribution and use in source and binary forms")
  end

  test "missing inputs and invalid class names produce generation errors" do
    invalid_names = {
      "A::b" => "component 2 must start with an uppercase letter",
      "A:::B" => "component 2 is empty",
      "A::1" => "component 2 must start with an uppercase letter",
      "A::" => "component 2 is empty",
      "::A::B" => "component 1 is empty",
      "parser" => "component 1 must start with an uppercase letter",
      "" => "component 1 is empty"
    }
    invalid_names.each do |class_name, message|
      error = assert_raise(Arpaka::Error) { Arpaka.generate(ruby_source: RUBY_SOURCE, class_name: class_name) }
      assert_include(error.message, message)
    end
    Dir.mktmpdir do |directory|
      error = assert_raise(Arpaka::Error) { Arpaka.generate(ruby_source: directory) }
      assert_include(error.message, "parse.y")
    end
  end

  test "changed upstream input is accepted when actions still match" do
    Dir.mktmpdir do |directory|
      FileUtils.cp_r(File.join(RUBY_SOURCE, "."), directory)
      File.open(File.join(directory, "parse.y"), "a") { |file| file.puts("/* changed */") }
      assert_nothing_raised { Arpaka.generate(ruby_source: directory) }
    end
  end

  test "preprocesses id.def inside a Ruby Box" do
    source = "%token RUBY_TOKEN(tIDENTIFIER) RUBY_TOKEN(tINTEGER)\n%token RUBY_TOKEN(tUNKNOWN)\n"
    Dir.mktmpdir do |directory|
      id_def = File.join(directory, "id.def")
      File.write(id_def, '{ token_op: [["identifier", "", "tIDENTIFIER", 1], ["integer", "", "tINTEGER", 2]] }')
      assert_equal("%token 1 2\n%token RUBY_TOKEN(tUNKNOWN)\n",
        Arpaka::Ruby::Grammar.preprocess(source, id_def))
    end
  end

  test "generates from parse.y by preserving token names" do
    source = Arpaka.generate(parse_y: File.join(RUBY_SOURCE, "parse.y"), class_name: "StandaloneRuby")
    assert_include(source, "class StandaloneRuby")
    assert_include(source, "Ruby source profile: parse.y only")
    assert_include(source, "Redistribution and use in source and binary forms")
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

  test "CLI writes namespaced frontend definitions" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "frontend.rb")
      out, err = StringIO.new, StringIO.new
      args = ["generate", "--ruby-source", RUBY_SOURCE, "--class-name", "A::B::Parser", "--output", path]

      assert_equal(0, Arpaka::CLI.run(args, out: out, err: err), err.string)
      source = File.read(path)
      assert_include(source, "module A")
      assert_include(source, "module B")
      assert_include(source, "class Parser")
    end
  end

  test "compile returns a source parsing frontend and isolates names" do
    frontend = Arpaka.compile(ruby_source: RUBY_SOURCE, class_name: "IsolatedRuby")
    assert_equal(42, frontend.parse("42").statements.first.value)
    assert_false(Object.const_defined?(:IsolatedRuby, false))
    assert_false(Arpaka.respond_to?(:parse))
    assert_false(Lrama::Ruby.respond_to?(:parse))
  end

  test "public API delegates to the Ruby frontend" do
    options = { parse_y: File.join(RUBY_SOURCE, "parse.y"), class_name: "DelegatedRuby" }
    assert_equal(Arpaka::Ruby.generate(**options), Arpaka.generate(**options))

    frontend = Arpaka::Ruby.compile(**options)
    assert_equal(42, frontend.parse("42").statements.first.value)
  end

  test "public CLI delegates to the Ruby frontend CLI" do
    public_out, public_err = StringIO.new, StringIO.new
    ruby_out, ruby_err = StringIO.new, StringIO.new
    assert_equal(Arpaka::Ruby::CLI.run(["--help"], out: ruby_out, err: ruby_err),
      Arpaka::CLI.run(["--help"], out: public_out, err: public_err))
    assert_equal(ruby_out.string, public_out.string)
    assert_equal(ruby_err.string, public_err.string)
  end

  test "CLI generates from parse.y" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "frontend.rb")
      out, err = StringIO.new, StringIO.new
      args = ["generate", "--parse-y", File.join(RUBY_SOURCE, "parse.y"), "--output", path]
      assert_equal(0, Arpaka::CLI.run(args, out: out, err: err), err.string)
      assert_include(File.read(path), "class RubyParser")
    end
  end
end

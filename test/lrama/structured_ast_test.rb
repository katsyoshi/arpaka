# frozen_string_literal: true

require "generated_frontend_helper"
require "arpaka/cli"
require "open3"
require "rbconfig"
require "stringio"
require "tmpdir"

class StructuredAstTest < Test::Unit::TestCase
  Frontend = Arpaka.compile(ruby_source: RUBY_SOURCE,
    class_name: "StructuredFrontend", ast_type: :structured)
  Structured = Frontend::StructuredAST

  test "projects nested definitions and keeps reopen occurrences separate" do
    tree = Frontend.parse(<<~RUBY, filename: "definitions.rb")
      module Outer
        class Inner < Base
          def work; end
          def self.build; end
          def object.call; end
        end
        class Inner < Other::Base
          def reopened; end
        end
      end
    RUBY

    assert_instance_of(Structured::Source, tree)
    assert_equal("definitions.rb", tree.filename)
    outer = tree.children.fetch(0)
    assert_instance_of(Structured::ModuleDef, outer)
    assert_equal(:Outer, outer.name)
    first, second = outer.children
    assert_equal([:Inner, :Inner], outer.children.map(&:name))
    assert_equal(:Base, first.superclass)
    assert_equal("Other::Base", second.superclass)
    assert_equal([:work, :build, :call], first.children.map(&:name))
    assert_equal([:instance, :singleton, :singleton], first.children.map(&:kind))
    assert_equal([nil, :self, :object], first.children.map(&:receiver))
    assert_equal([:reopened], second.children.map(&:name))
    assert_equal([], second.children.fetch(0).children)
  end

  test "projects declarations in control flow and singleton class bodies" do
    tree = Frontend.parse(<<~RUBY)
      if enabled
        class Child < factory()
          include Helpers
          define_method(:dynamic) {}
          def static; end
          class << self
            def from_singleton_class; end
          end
        end
      end
    RUBY

    assert_equal("(ruby)", tree.filename)
    child = tree.children.fetch(0)
    assert_equal(:Child, child.name)
    assert_nil(child.superclass)
    assert_equal([:static, :from_singleton_class], child.children.map(&:name))
    assert_equal([:instance, :singleton], child.children.map(&:kind))
    assert_equal([nil, :self], child.children.map(&:receiver))
  end

  test "projects static constant paths and fresh empty roots" do
    tree = Frontend.parse("class A::B < ::Root::Base; end")
    node = tree.children.fetch(0)
    assert_equal("A::B", node.name)
    assert_equal("::Root::Base", node.superclass)

    first = Frontend.parse("")
    second = Frontend.parse("")
    assert_equal([], first.children)
    assert_equal([], second.children)
    assert_not_same(first.children, second.children)
  end

  test "namespaced frontend projects its own detailed AST nodes" do
    frontend = Arpaka.compile(ruby_source: RUBY_SOURCE,
      class_name: "A::B::Parser", ast_type: :structured)
    assert_equal("A::B::Parser", frontend.name)
    assert_false(Object.const_defined?(:A, false))

    tree = frontend.parse("module Outer; class Inner; def work; end; end; end",
      filename: "nested.rb")
    assert_instance_of(frontend::StructuredAST::Source, tree)
    assert_equal("nested.rb", tree.filename)
    assert_equal(:Outer, tree.children.first.name)
    assert_equal(:Inner, tree.children.first.children.first.name)
    assert_equal(:work, tree.children.first.children.first.children.first.name)

    ast = frontend::AST
    detailed = ast::Program.new([ast::ClassDef.new(:Direct, nil,
      [ast::Def.new(:example, [], [])])])
    projected = frontend::StructuredAST.project(detailed, filename: "direct.rb")
    assert_equal(:Direct, projected.children.first.name)
    assert_equal(:example, projected.children.first.children.first.name)
  end

  test "default detailed source is unchanged and structured source has projection overhead" do
    options = { ruby_source: RUBY_SOURCE, class_name: "A::B::Parser" }
    default_source = Arpaka.generate(**options)
    detailed_source = Arpaka.generate(**options, ast_type: :detailed)
    structured_source = Arpaka.generate(**options, ast_type: :structured)

    assert_equal(default_source, detailed_source)
    assert_include(default_source, "class Parser")
    assert_not_include(default_source, "module StructuredAST")
    assert_include(structured_source, "module StructuredAST")
    assert_operator(structured_source.bytesize, :>, default_source.bytesize)

    detailed_frontend = Arpaka.compile(**options)
    detailed_tree = detailed_frontend.parse("class Example; def work; end; end")
    assert_instance_of(detailed_frontend::AST::Program, detailed_tree)
    assert_instance_of(detailed_frontend::AST::ClassDef, detailed_tree.statements.first)
  end

  test "rejects unsupported AST types" do
    error = assert_raise(Arpaka::Error) do
      Arpaka.generate(ruby_source: RUBY_SOURCE, ast_type: :unknown)
    end
    assert_match(/ast_type must be detailed or structured/, error.message)
  end

  test "public generation supports structured output from parse.y" do
    source = Arpaka.generate(parse_y: File.join(RUBY_SOURCE, "parse.y"),
      class_name: "GeneratedStructured", ast_type: "structured")
    assert_include(source, "class GeneratedStructured")
    assert_include(source, "module StructuredAST")
    assert_include(source, "StructuredAST.project(result, filename: filename)")
  end

  test "CLI emits a standalone structured frontend" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "frontend.rb")
      out, err = StringIO.new, StringIO.new
      args = ["generate", "--ruby-source", RUBY_SOURCE, "--class-name", "CliStructured",
        "--ast-type", "structured", "--output", path]
      assert_equal(0, Arpaka::CLI.run(args, out: out, err: err), err.string)

      script = <<~RUBY
        require ARGV.fetch(0)
        tree = CliStructured.parse("module A; def example; end; end", filename: "standalone.rb")
        abort "wrong projection" unless tree.filename == "standalone.rb" &&
          tree.children.first.name == :A && tree.children.first.children.first.name == :example
        puts tree.class.name
      RUBY
      stdout, stderr, status = Open3.capture3(
        { "RUBY_BOX" => nil, "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil },
        RbConfig.ruby, "-e", script, path
      )
      assert(status.success?, stderr)
      assert_equal("CliStructured::StructuredAST::Source\n", stdout)

      invalid_err = StringIO.new
      assert_equal(1, Arpaka::CLI.run(args + ["--ast-type", "unknown"],
        out: StringIO.new, err: invalid_err))
      assert_match(/invalid argument/, invalid_err.string)
    end
  end
end

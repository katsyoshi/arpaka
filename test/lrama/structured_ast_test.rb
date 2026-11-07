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
  Structured = Frontend::AST

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
    assert_equal("StructuredFrontend::AST::Source", tree.class.name)
    assert_false(Frontend.const_defined?(:StructuredAST, false))
    assert_true(Structured.const_defined?(:Program, false))
    assert_equal("definitions.rb", tree.filename)
    outer = tree.children.fetch(0)
    assert_instance_of(Structured::Module, outer)
    assert_equal("StructuredFrontend::AST::Module", outer.class.name)
    assert_equal(:Outer, outer.name)
    first, second = outer.children
    assert_equal([:Inner, :Inner], outer.children.map(&:name))
    assert_equal("StructuredFrontend::AST::Class", first.class.name)
    assert_equal(:Base, first.superclass)
    assert_equal("Other::Base", second.superclass)
    assert_equal([:work, :build, :call], first.children.map(&:name))
    assert_equal("StructuredFrontend::AST::Method", first.children.first.class.name)
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

  test "structured parser resolves forwarded splat through its detailed builder" do
    tree = Frontend.parse("def forward(*); call(*); end")
    assert_equal([:forward], tree.children.map(&:name))
    assert_equal("StructuredFrontend::AST::Method", tree.children.first.class.name)
  end

  test "recognizes the Ruby 3.3 literal representation of self" do
    ast = Frontend::AST
    detailed = ast::Program.new([
      ast::SingletonMethodDef.new(ast::Literal.new(:self), :direct, [], []),
      ast::SingletonClassDef.new(ast::Literal.new(:self), [ast::Def.new(:nested, [], [])])
    ])

    methods = Structured.project(detailed, filename: "legacy.rb").children
    assert_equal([:direct, :nested], methods.map(&:name))
    assert_equal([:singleton, :singleton], methods.map(&:kind))
    assert_equal([:self, :self], methods.map(&:receiver))
  end

  test "projects definitions in method defaults before method bodies" do
    tree = Frontend.parse(<<~RUBY)
      def outer(x = (def first; end), y: (def second; end))
        def last; end
      end
      def self.singleton(x = (def before; end))
        def after; end
      end
    RUBY

    instance_method, singleton_method = tree.children
    assert_equal([:first, :second, :last], instance_method.children.map(&:name))
    assert_equal([:before, :after], singleton_method.children.map(&:name))
  end

  test "projects modifier conditions after their bodies and regular if in source order" do
    tree = Frontend.parse(<<~RUBY)
      (def if_body; end) if (def if_condition; end)
      (def unless_body; end) unless (def unless_condition; end)
      if (def regular_condition; end)
        (def regular_body; end)
      end
    RUBY

    assert_equal([:if_body, :if_condition, :unless_body, :unless_condition,
      :regular_condition, :regular_body], tree.children.map(&:name))
  end

  test "projects modifier loops and regular loops in source order" do
    tree = Frontend.parse(<<~RUBY)
      (def while_body; end) while (def while_condition; end)
      (def until_body; end) until (def until_condition; end)
      while (def regular_condition; end)
        (def regular_body; end)
      end
    RUBY

    assert_equal([:while_body, :while_condition, :until_body, :until_condition,
      :regular_condition, :regular_body], tree.children.map(&:name))
  end

  test "projects declarations in headers before their enclosing definitions" do
    parsed = Frontend.parse("class C < (def hidden; end); def visible; end; end")
    assert_equal([:hidden, :C], parsed.children.map(&:name))
    assert_equal([:visible], parsed.children.last.children.map(&:name))

    ast = Frontend::AST
    nested = ast::Program.new([
      ast::ClassDef.new(:C, ast::Def.new(:superclass_header, [], []),
        [ast::Def.new(:class_body, [], [])]),
      ast::SingletonClassDef.new(ast::Def.new(:singleton_class_receiver, [], []),
        [ast::Def.new(:singleton_class_body, [], [])]),
      ast::SingletonMethodDef.new(ast::Def.new(:method_receiver, [], []), :call, [],
        [ast::Def.new(:method_body, [], [])])
    ])

    nodes = Structured.project(nested, filename: "headers.rb").children
    assert_equal([:superclass_header, :C, :singleton_class_receiver,
      :singleton_class_body, :method_receiver, :call], nodes.map(&:name))
    assert_equal([:class_body], nodes[1].children.map(&:name))
    assert_equal([:method_body], nodes.last.children.map(&:name))
  end

  test "keeps singleton class context through nested method declarations" do
    tree = Frontend.parse(<<~RUBY)
      class A
        class << self
          def outer(x = (def in_default; end))
            def inner; end
            def self.explicit
              def inside_explicit; end
            end
          end
        end
      end
    RUBY

    outer = tree.children.first.children.first
    assert_equal([:singleton, :self], [outer.kind, outer.receiver])
    assert_equal([:in_default, :inner, :explicit], outer.children.map(&:name))
    assert_equal([:singleton, :singleton, :singleton], outer.children.map(&:kind))
    assert_equal([:self, :self, :self], outer.children.map(&:receiver))
    assert_equal([:singleton, :self],
      [outer.children.last.children.first.kind, outer.children.last.children.first.receiver])
  end

  test "namespaced frontend projects its own detailed AST nodes" do
    frontend = Arpaka.compile(ruby_source: RUBY_SOURCE,
      class_name: "A::B::Parser", ast_type: :structured)
    assert_equal("A::B::Parser", frontend.name)
    assert_false(Object.const_defined?(:A, false))

    tree = frontend.parse("module Outer; class Inner; def work; end; end; end",
      filename: "nested.rb")
    assert_instance_of(frontend::AST::Source, tree)
    assert_equal("A::B::Parser::AST::Source", frontend::AST::Source.name)
    assert_equal("A::B::Parser::AST::Source", tree.class.name)
    assert_equal("nested.rb", tree.filename)
    assert_equal(:Outer, tree.children.first.name)
    assert_equal(:Inner, tree.children.first.children.first.name)
    assert_equal(:work, tree.children.first.children.first.children.first.name)

    ast = frontend::AST
    detailed = ast::Program.new([ast::ClassDef.new(:Direct, nil,
      [ast::Def.new(:example, [], [])])])
    projected = frontend::AST.project(detailed, filename: "direct.rb")
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
    assert_not_include(structured_source, "module DetailedAST")
    assert_match(/module AST\n\s+Source = Data\.define/, structured_source)
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
    assert_include(source, "module AST\n  Source = Data.define")
    assert_include(source, "AST.project(detailed_ast, filename: filename, modifier_nodes: modifier_nodes)")
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
        abort "wrong AST namespace" unless tree.class.name == "CliStructured::AST::Source" &&
          tree.children.first.class.name == "CliStructured::AST::Module" &&
          tree.children.first.children.first.class.name == "CliStructured::AST::Method"
        puts tree.class.name
      RUBY
      stdout, stderr, status = Open3.capture3(
        { "RUBY_BOX" => nil, "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil },
        RbConfig.ruby, "-e", script, path
      )
      assert(status.success?, stderr)
      assert_equal("CliStructured::AST::Source\n", stdout)

      invalid_err = StringIO.new
      assert_equal(1, Arpaka::CLI.run(args + ["--ast-type", "unknown"],
        out: StringIO.new, err: invalid_err))
      assert_match(/invalid argument/, invalid_err.string)
    end
  end
end

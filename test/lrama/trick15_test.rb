# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class Trick15Test < Test::Unit::TestCase
  TRICK_ROOT = ENV["TRICK15_ROOT"]

  test "parses every trick15 Ruby file" do
    omit("set TRICK15_ROOT to run the external Trick 2015 corpus") unless TRICK_ROOT && Dir.exist?(TRICK_ROOT)

    files = Dir[File.join(TRICK_ROOT, "**", "*.rb")].sort

    assert_equal(13, files.length)
    files.each do |path|
      assert_nothing_raised("#{path}: generated frontend parses this file") do
        GeneratedRubyFrontend.parse(File.read(path), filename: path)
      end
    end
  end

  test "accepts undef with an operator method name" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("class Object; undef[]; end\n") }
  end

  test "accepts a percent method call followed by a percent literal" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value.% %%x%\n") }
  end

  test "accepts redo with a modifier" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("begin; redo if condition; end\n") }
  end

  test "ignores a newline before a method name after def" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def\n-(value) value end\n") }
  end

  test "represents an empty percent word array" do
    tree = GeneratedRubyFrontend.parse("value = %I{}\n")

    assert_kind_of(GeneratedRubyFrontend::AST::ArrayLiteral, tree.statements.first.value)
    assert_empty(tree.statements.first.value.elements)
  end
end

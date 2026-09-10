# frozen_string_literal: true

require "test_helper"

class Arpaka::CalculatorAstTest < Test::Unit::TestCase
  GRAMMAR = File.read(File.expand_path("../../examples/calculator_ast.y", __dir__))

  def setup
    @parser = Lrama::Ruby.compile(GRAMMAR, class_name: "CalculatorAst").new
  end

  test "numeric leaves and operator precedence are represented in the tree" do
    assert_equal([:number, 42], @parser.parse([[:NUMBER, 42]]))
    assert_equal(
      [:binary, :+, [:number, 2], [:binary, :*, [:number, 3], [:number, 4]]],
      @parser.parse([[:NUMBER, 2], ["+", nil], [:NUMBER, 3], ["*", nil], [:NUMBER, 4]])
    )
  end

  test "subtraction is left associative" do
    assert_equal(
      [:binary, :-, [:binary, :-, [:number, 8], [:number, 3]], [:number, 2]],
      @parser.parse([[:NUMBER, 8], ["-", nil], [:NUMBER, 3], ["-", nil], [:NUMBER, 2]])
    )
  end

  test "parentheses change grouping without adding AST nodes" do
    assert_equal(
      [:binary, :*, [:binary, :+, [:number, 2], [:number, 3]], [:number, 4]],
      @parser.parse([["(", nil], [:NUMBER, 2], ["+", nil], [:NUMBER, 3], [")", nil], ["*", nil], [:NUMBER, 4]])
    )
  end

  test "division is recorded without evaluation" do
    assert_equal(
      [:binary, :/, [:number, 1], [:number, 0]],
      @parser.parse([[:NUMBER, 1], ["/", nil], [:NUMBER, 0]])
    )
  end
end

# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class ArpakaRubyEscapeTest < Test::Unit::TestCase
  AST = GeneratedRubyFrontend::AST

  test "quoted and percent strings follow Ruby escape rules" do
    [
      "'a\\nb'",
      "'a\\\\b'",
      "'a\\'b'",
      '"a\\sb"',
      '"a\\b\\v"',
      '"\\c?\\C-?"',
      '"a\\\nb"',
      '"\\x41\\101\\u0042\\u{43 1f600}"',
      "%q{a\\nb}",
      "%q{a\\}b}",
      "%q(a\\(b)",
      '"雪\\é"'
    ].each do |source|
      expected = rubyvm_string(source)
      actual = parse(source).statements.fetch(0).value
      assert_equal(expected.b, actual.b, source)
      assert_equal(expected.encoding, actual.encoding, source)
    end
  end

  test "empty quoted strings retain UTF-8 encoding" do
    ["''", '""', "%q{}"].each do |source|
      actual = parse(source).statements.fetch(0).value
      assert_equal("".b, actual.b, source)
      assert_equal(Encoding::UTF_8, actual.encoding, source)
    end
  end

  test "escaped raw bytes remain UTF-8 tagged like Ruby strings" do
    ['"\\xFF"', '"\\377"'].each do |source|
      expected = rubyvm_string(source)
      actual = parse(source).statements.fetch(0).value
      assert_equal(expected.b, actual.b, source)
      assert_equal(expected.encoding, actual.encoding, source)
      assert_false(actual.valid_encoding?, source)
    end
  end

  test "percent word boundaries are identified before escapes are decoded" do
    [
      "%w[>\\s]",
      "%w[a\\ b c]",
      "%w[a\\\\b]",
      "%w[e,hi 愛媛県]",
      "%i[a\\ b c]"
    ].each do |source|
      expected = rubyvm_words(source)
      actual = parse(source).statements.fetch(0).elements.map do |element|
        element.is_a?(AST::StringLiteral) ? element.value : element
      end
      assert_equal(expected, actual, source)
      expected.zip(actual).each do |expected_word, actual_word|
        assert_equal(expected_word.to_s.b, actual_word.to_s.b, source)
        assert_equal(expected_word.to_s.encoding, actual_word.to_s.encoding, source)
      end
    end
  end

  test "interpolated percent words retain dynamic string and symbol nodes" do
    words = parse('%W[pre#{name}post plain]').statements.fetch(0)
    assert_equal(2, words.elements.length)
    assert_kind_of(AST::InterpolatedString, words.elements.fetch(0))
    assert_equal(["pre", AST::BareCall.new(:name), "post"],
      words.elements.fetch(0).parts)
    assert_equal("plain", words.elements.fetch(1).value)

    symbols = parse('%I[pre#{name}post plain]').statements.fetch(0)
    assert_equal(2, symbols.elements.length)
    assert_kind_of(AST::DynamicSymbol, symbols.elements.fetch(0))
    assert_equal(["pre", AST::BareCall.new(:name), "post"],
      symbols.elements.fetch(0).parts)
    assert_equal(:plain, symbols.elements.fetch(1))
  end

  test "percent regular expressions preserve regexp and delimiter escapes" do
    {
      "%r[\\d+]" => "\\d+",
      "%r{\\\\}" => "\\\\",
      "%r{\\{x\\}}" => "\\{x\\}",
      "%r[\\[]" => "\\[",
      "%r(a\\)b)" => "a\\)b",
      "%r!a\\!b!" => "a!b"
    }.each do |source, expected|
      tree = parse(source)
      assert_equal(expected, tree.statements.fetch(0).value, source)
    end
  end

  private

  def parse(source)
    GeneratedRubyFrontend.parse(source)
  end

  def rubyvm_string(source)
    node = RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2)
    assert_equal(:STR, node.type, source)
    node.children.fetch(0)
  end

  def rubyvm_words(source)
    node = RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2)
    assert_equal(:LIST, node.type, source)
    node.children.compact.map do |word|
      if word.type == :STR
        word.children.fetch(0)
      elsif [:LIT, :SYM].include?(word.type)
        word.children.fetch(0)
      else
        flunk("unexpected RubyVM word node #{word.type} for #{source}")
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class Trick25Test < Test::Unit::TestCase
  test "source lexer accepts trick25 method suffixes in compact code" do
    source = <<~'RUBY'
      h=*(p!unless(u);8.7*6.5;;[*eval(t[u,v])])
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "source lexer handles compact globals and indexing" do
    source = <<~'RUBY'
      $*.first
      $.
      $en[]
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "source lexer distinguishes shifts, labels, and ternaries" do
    source = <<~'RUBY'
      value = t<<050<<+98
      result = foo(From:pd)
      result = value ? f[items] : fallback
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "source lexer tracks BEGIN and END braces" do
    source = <<~'RUBY'
      BEGIN{value = 1}
      END{value = 2}
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "parenthesized statement sequences remain representable" do
    tree = GeneratedRubyFrontend.parse("value = (first; second)\n")

    assert_kind_of(GeneratedRubyFrontend::AST::Sequence, tree.statements.first.value)
    assert_equal(2, tree.statements.first.value.statements.length)
  end
end

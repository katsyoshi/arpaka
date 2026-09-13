# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class Trick18Test < Test::Unit::TestCase
  test "parses the kinaba keyword alias program" do
    source = <<~'RUBY'
      alias    BEGIN    for      unless   def      class
      super    true     or       return   defined? next
      break    while    begin    undef    do       end
      rescue   then     retry    else     undef    module
      nil      ensure   case     if       yield    __LINE__
      self     and      redo     elsif    not      __FILE__
      alias    END      in       end      when     __ENCODING__
      end      until    false    end
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "does not split equality after a receiver method" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value.__id__ == __id__\n") }
  end

  test "keeps unary operator method names together after def" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def -@; end\ndef +@; end\n") }
  end

  test "keeps unary operator method names together in aliases" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias +@ -@\nalias + -\n") }
  end

  test "ignores newlines inside array literals" do
    source = "value = [*self, nil, *items\n]\n"

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "continues comparisons across newlines" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = first >\nsecond\n") }
  end

  test "recognizes the slash special global variable" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("$/\n").each.to_a

    assert_equal(:tGVAR, tokens.first.first)
    assert_equal(:"$/", tokens.first.last)
  end

  test "uses indexing brackets for calls nested in arrays" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("values = [first, second [item]]\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("values = [first * index [0]]\n") }
  end

  test "uses regular parentheses for receiver method definitions" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def STDOUT.write (value); end\n") }
  end
end

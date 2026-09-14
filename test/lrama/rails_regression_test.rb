# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class RailsRegressionTest < Test::Unit::TestCase
  test "parses keyword arguments in ternary branches" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("value = first?(value: true) ? second(value: false) : value\n")
    end
  end

  test "preserves the method body after unary operator method definitions" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("def -@\n  Scalar.new(-value)\nend\n")
    end
  end

  test "preserves newlines after operator symbols in alias declarations" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("alias_method :minus_without_duration, :-\nalias_method :-, :minus_with_duration\n")
      GeneratedRubyFrontend.parse("alias_method :before?, :<\nalias_method :after?, :>\n")
    end
  end

  test "parses keyword arguments in block parameters" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("proc { |salt, secret_length:| \"\".ljust(secret_length, salt) }\n")
    end
  end

  test "parses keyword argument forwarding before a block" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("call blob:, variants: [{ resize_to_limit: [2, 2] }] do\nend\n")
    end
  end

  test "does not hide control-flow terminators inside array literals" do
    source = <<~'RUBY'
      values = [
        if condition
          value
        end,
        other
      ]
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end
end

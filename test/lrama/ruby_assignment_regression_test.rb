# frozen_string_literal: true

require_relative "../generated_frontend_helper"

class ArpakaAssignmentRegressionTest < Test::Unit::TestCase
  AST = GeneratedRubyFrontend::AST

  test "command assignment retains its right hand side" do
    expected = AST::LocalWrite.new(:req,
      AST::ReceiverCall.new(
        AST::ConstantPath.new(AST::Variable.new(:constant, :ActionDispatch), :Request),
        :".", :new, [AST::BareCall.new(:env)]))

    assert_equal(expected,
      GeneratedRubyFrontend.parse("req = ActionDispatch::Request.new env").statements.first)
  end

  test "local and instance operator assignments retain their operator and value" do
    expected = [
      AST::OpAssign.new(:x, :"||", AST::BareCall.new(:foo)),
      AST::OpAssign.new(AST::Variable.new(:instance, :@x), :"||", AST::BareCall.new(:foo)),
      AST::OpAssign.new(AST::Variable.new(:instance, :@x), :+, AST::BareCall.new(:foo))
    ]

    actual = GeneratedRubyFrontend.parse("x ||= foo; @x ||= foo; @x += foo").statements
    assert_equal(expected, actual)
  end

  test "multiple assignment retains all targets and the right hand side" do
    actual = GeneratedRubyFrontend.parse("@address, @mailbox_name = address, to").statements.first
    expected = AST::MultipleAssign.new(
      [AST::Variable.new(:instance, :@address), AST::Variable.new(:instance, :@mailbox_name)],
      AST::ArrayLiteral.new([AST::BareCall.new(:address), AST::BareCall.new(:to)]))
    assert_equal(expected, actual)

    single_target = GeneratedRubyFrontend.parse("values = 1, 2").statements.first
    assert_equal(AST::LocalWrite.new(:values,
      AST::ArrayLiteral.new([AST::Literal.new(1), AST::Literal.new(2)])), single_target)
  end
end

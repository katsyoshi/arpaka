# frozen_string_literal: true

require "test_helper"

class RubyReceiverCallTest < Test::Unit::TestCase
  AST = Arpaka::AST

  test "receiver calls retain their operator, method name and ordered arguments" do
    [".", "::", "&."].each do |operator|
      ["object#{operator}fetch(1, 2)", "object#{operator}fetch 1, 2"].each do |source|
        tree = Arpaka.parse_source(source).statements.fetch(0)
        assert_equal(AST::ReceiverCall.new(AST::BareCall.new(:object), operator.to_sym,
          :fetch, [AST::Literal.new(1), AST::Literal.new(2)]), tree, source)
        assert_predicate(tree.arguments, :frozen?)
      end
    end
  end

  test "parenthesized invocation without a method name means call" do
    [".", "::", "&."].each do |operator|
      source = "handler#{operator}(message)"
      expected = AST::ReceiverCall.new(AST::BareCall.new(:handler), operator.to_sym,
        :call, [AST::BareCall.new(:message)])
      assert_equal(AST::Program.new([expected]), Arpaka.parse_source(source), source)
    end
  end

  test "safe navigation allows keyword and operator method names" do
    ["class", "if", "[]"].each do |name|
      source = "object&.#{name}(1)"
      expected = AST::ReceiverCall.new(AST::BareCall.new(:object), :"&.",
        name.to_sym, [AST::Literal.new(1)])
      assert_equal(AST::Program.new([expected]), Arpaka.parse_source(source), source)
    end
  end

  test "receiver call trees agree with RubyVM for representative Rails expressions" do
    sources = [
      "self.class.to_s", "object&.class", "object&.if(1)", "object&.[](1)",
      "logger.warn \"deprecated\"", "File.join(\"a\", \"b\")",
      "File::join(\"a\", \"b\")", "File::join \"a\", \"b\"", "Object::name",
      "handler.(message)", "handler::(message)", "handler&.(message)",
      "object.fetch(1, transform(2))", "object&.fetch 1, 2",
      "object.fetch(1).to_s", "object&.fetch(1)&.to_s", "object.ready?"
    ]
    sources.each do |source|
      expected = normalize_rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalize_arpaka(Arpaka.parse_source(source).statements.fetch(0))
      assert_equal(expected, actual, source)
    end
  end

  private

  # This oracle deliberately covers only this test's expression slice. Unknown
  # nodes fail instead of making an incomplete comparison look successful.
  def normalize_rubyvm(node)
    children = node.children
    case node.type
    when :CALL, :QCALL
      receiver, name, arguments = children
      [:call, normalize_rubyvm(receiver), node.type == :QCALL, name, rubyvm_arguments(arguments)]
    when :FCALL
      [:call, nil, false, children[0], rubyvm_arguments(children[1])]
    when :VCALL
      [:bare_call, children.fetch(0)]
    when :CONST
      [:constant, children.fetch(0)]
    when :SELF
      [:literal, :self]
    when :STR
      [:string, children.fetch(0)]
    when :LIT, :INTEGER
      [:literal, children.fetch(0)]
    else
      flunk("Unmapped RubyVM node: #{node.type}")
    end
  end

  def rubyvm_arguments(node)
    return [] unless node
    assert_equal(:LIST, node.type)
    assert_nil(node.children.last)
    node.children[0...-1].map { |child| normalize_rubyvm(child) }
  end

  def normalize_arpaka(node)
    case node
    when AST::ReceiverCall
      [:call, normalize_arpaka(node.receiver), node.operator == :"&.", node.name,
        node.arguments.map { |argument| normalize_arpaka(argument) }]
    when AST::Call
      [:call, nil, false, node.name, node.arguments.map { |argument| normalize_arpaka(argument) }]
    when AST::BareCall
      [:bare_call, node.name]
    when AST::Variable
      assert_equal(:constant, node.kind)
      [:constant, node.name]
    when AST::StringLiteral
      [:string, node.value]
    when AST::Literal
      [:literal, node.value]
    else
      flunk("Unmapped Arpaka node: #{node.inspect}")
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"
require "open3"
require "rbconfig"

class ArpakaTest < Test::Unit::TestCase
  AST = GeneratedRubyFrontend::AST

  def parse(*tokens)
    GeneratedRubyFrontend.send(:parse_tokens, tokens)
  end

  def literal(value)
    AST::Literal.new(value)
  end

  test "generic parsers and Ruby ASTs coexist" do
    parser = Lrama::Ruby.compile("%%\nstart: %empty { $$ = 42 };").new
    assert_equal(AST::Program.new([]), parse)
    assert_equal(42, parser.parse([]))
    assert_false(Object.const_defined?(:RubyParser))
  end

  test "generated reductions retain readable rules and named actions" do
    source = Arpaka.generate(ruby_source: RUBY_SOURCE)
    assert_include(source, "# arg: arg '+' arg")
    assert_include(source, "@builder.binary(:+, ")
    assert_not_include(source, "@builder.reduce(")
  end

  test "failed parsing and concurrent calls do not share local state" do
    assert_raise(GeneratedRubyFrontend::ParseError) { GeneratedRubyFrontend.parse("a =") }
    threads = 4.times.map { Thread.new { GeneratedRubyFrontend.parse("a = 3") } }
    assert(threads.map(&:value).all? { |tree| tree.statements.first.value.value == 3 })
    assert_kind_of(AST::BareCall, GeneratedRubyFrontend.parse("a").statements.first)
  end

  test "empty program and literal statements" do
    assert_equal(AST::Program.new([]), parse)
    { tINTEGER: 3, tFLOAT: 1.5, keyword_nil: nil, keyword_true: true, keyword_false: false }.each do |token, value|
      assert_equal(AST::Program.new([literal(value)]), parse([token, value]))
    end
  end

  test "precedence and grouping" do
    tree = AST::Binary.new(:+, literal(2), AST::Binary.new(:*, literal(3), literal(4)))
    assert_equal(AST::Program.new([tree]), parse([:tINTEGER, 2], ["+", nil], [:tINTEGER, 3], ["*", nil], [:tINTEGER, 4]))
    grouped = AST::Binary.new(:*, AST::Binary.new(:+, literal(2), literal(3)), literal(4))
    assert_equal(AST::Program.new([grouped]), parse([:tLPAREN, nil], [:tINTEGER, 2], ["+", nil], [:tINTEGER, 3], [")", nil], ["*", nil], [:tINTEGER, 4]))
  end

  test "left associativity and division without evaluation" do
    tree = AST::Binary.new(:-, AST::Binary.new(:-, literal(8), literal(3)), literal(2))
    assert_equal(AST::Program.new([tree]), parse([:tINTEGER, 8], ["-", nil], [:tINTEGER, 3], ["-", nil], [:tINTEGER, 2]))
    assert_equal(AST::Program.new([AST::Binary.new(:/, literal(1), literal(0))]), parse([:tINTEGER, 1], ["/", nil], [:tINTEGER, 0]))
  end

  test "comparison and logical operators build binary ASTs" do
    expected = AST::Binary.new(:"&&", AST::Binary.new(:"<", literal(1), literal(2)), literal(true))
    assert_equal(AST::Program.new([expected]), parse([:tINTEGER, 1], ["<", nil], [:tINTEGER, 2], ["&&", nil], [:keyword_true, nil]))
    assert_equal(AST::Program.new([AST::Unary.new(:"!", literal(false))]), parse(["!", nil], [:keyword_false, nil]))
  end

  test "range literals preserve inclusive and exclusive operators" do
    inclusive = AST::RangeLiteral.new(:"..", literal(1), literal(3))
    exclusive = AST::RangeLiteral.new(:"...", literal(1), literal(3))
    assert_equal(AST::Program.new([inclusive]), parse([:tINTEGER, 1], ["..", nil], [:tINTEGER, 3]))
    assert_equal(AST::Program.new([exclusive]), parse([:tINTEGER, 1], ["...", nil], [:tINTEGER, 3]))
  end

  test "ternary expressions preserve all branches" do
    expected = AST::Ternary.new(literal(true), literal(1), literal(2))
    assert_equal(AST::Program.new([expected]), parse([:keyword_true, nil], ["?", nil], [:tINTEGER, 1], [":", nil], [:tINTEGER, 2]))
  end

  test "simple method calls preserve the method name and arguments" do
    expected = AST::Call.new(:f, [literal(1), literal(2)])
    assert_equal(AST::Program.new([expected]), parse([:tIDENTIFIER, :f], ["(", nil], [:tINTEGER, 1], [",", nil], [:tINTEGER, 2], [")", nil]))
    assert_equal(AST::Program.new([AST::Call.new(:f, [])]), parse([:tIDENTIFIER, :f], ["(", nil], [")", nil]))
  end

  test "simple method definitions preserve name and body" do
    expected = AST::Def.new(:foo, [], [literal(1)])
    tokens = [[:keyword_def, nil], [:tIDENTIFIER, :foo], [";", nil], [:tINTEGER, 1], [";", nil], [:keyword_end, nil]]
    assert_equal(AST::Program.new([expected]), parse(*tokens))
  end

  test "setter method definitions preserve the equals suffix" do
    expected = AST::Program.new([AST::Def.new(:"value=", :value, [AST::BareCall.new(:value)])])
    assert_equal(expected, GeneratedRubyFrontend.parse("def value=(value)\n  value\nend"))
    assert_nothing_raised { GeneratedRubyFrontend.parse("def self.value=; end") }
  end

  test "alias preserves bracket operator names" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias store []=") }
  end

  test "keywords after a receiver are method names" do
    receiver = AST::ReceiverCall.new(literal(:self), :".", :class, [])
    assert_equal(AST::Program.new([AST::ReceiverCall.new(receiver, :".", :to_s, [])]),
      GeneratedRubyFrontend.parse("self.class.to_s"))
  end

  test "operator calls use ordinary argument parentheses" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("handler.(message)").each.to_a
    assert_equal([".", "(", :tIDENTIFIER], tokens[1, 3].map(&:first))
  end

  test "class and module definitions preserve name and body" do
    class_tokens = [[:keyword_class, nil], [:tCONSTANT, :Foo], [";", nil], [:tINTEGER, 1], [";", nil], [:keyword_end, nil]]
    module_tokens = [[:keyword_module, nil], [:tCONSTANT, :Bar], [";", nil], [:tINTEGER, 2], [";", nil], [:keyword_end, nil]]
    assert_equal(AST::Program.new([AST::ClassDef.new(:Foo, nil, [literal(1)])]), parse(*class_tokens))
    assert_equal(AST::Program.new([AST::ModuleDef.new(:Bar, [literal(2)])]), parse(*module_tokens))
    assert_equal(AST::ClassDef.new(:Error, AST::Variable.new(:constant, :StandardError), []),
      GeneratedRubyFrontend.parse("class Error < StandardError\nend").statements.first)
    assert_equal(:TrixEditor,
      GeneratedRubyFrontend.parse("class Editor::TrixEditor\nend").statements.first.name)
  end

  test "simple string literals preserve their content" do
    expected = AST::StringLiteral.new("text")
    assert_equal(AST::Program.new([expected]), parse([:tSTRING_BEG, nil], [:tSTRING_CONTENT, "text"], [:tSTRING_END, nil]))
  end

  test "simple regexp literals preserve their content" do
    expected = AST::RegexpLiteral.new("text")
    assert_equal(AST::Program.new([expected]), parse([:tREGEXP_BEG, nil], [:tSTRING_CONTENT, "text"], [:tREGEXP_END, nil]))
  end

  test "simple xstring literals preserve their content" do
    expected = AST::XStringLiteral.new("echo")
    assert_equal(AST::Program.new([expected]), parse([:tXSTRING_BEG, nil], [:tSTRING_CONTENT, "echo"], [:tSTRING_END, nil]))
  end

  test "simple for loops preserve variable, enumerable and body" do
    variable = :i
    enumerable = AST::ArrayLiteral.new([literal(1)])
    expected = AST::For.new(variable, enumerable, [literal(2)])
    assert_equal(AST::Program.new([expected]), parse([:keyword_for, nil], [:tIDENTIFIER, :i], [:keyword_in, nil], [:tLBRACK, nil], [:tINTEGER, 1], ["]", nil], [:keyword_do_cond, nil], [:tINTEGER, 2], [:keyword_end, nil]))
  end

  test "simple symbol literals preserve their symbol value" do
    assert_equal(AST::Program.new([literal(:foo)]), parse([:tSYMBEG, nil], [:tIDENTIFIER, :foo]))
  end

  test "index access preserves receiver and index arguments" do
    receiver = AST::ArrayLiteral.new([literal(1), literal(2)])
    expected = AST::Index.new(receiver, [literal(0)])
    assert_equal(AST::Program.new([expected]), parse([:tLBRACK, nil], [:tINTEGER, 1], [",", nil], [:tINTEGER, 2], ["]", nil], ["[", nil], [:tINTEGER, 0], ["]", nil]))
    assert_equal(AST::Index.new(AST::BareCall.new(:values), [literal(0)]),
      GeneratedRubyFrontend.parse("values[0]").statements.first)
  end

  test "label hash entries build the same pair AST" do
    pair = AST::Pair.new(literal(:foo), literal(1))
    expected = AST::HashLiteral.new([pair])
    assert_equal(AST::Program.new([expected]), parse([:tLBRACE, nil], [:tLABEL, :foo], [:tINTEGER, 1], ["}", nil]))
  end

  test "while and until loops preserve condition and body" do
    while_tree = AST::Loop.new(:while, literal(true), [literal(1)])
    until_tree = AST::Loop.new(:until, literal(false), [literal(2)])
    assert_equal(AST::Program.new([while_tree]), parse([:keyword_while, nil], [:keyword_true, nil], [:keyword_do_cond, nil], [:tINTEGER, 1], [:keyword_end, nil]))
    assert_equal(AST::Program.new([until_tree]), parse([:keyword_until, nil], [:keyword_false, nil], [:keyword_do_cond, nil], [:tINTEGER, 2], [:keyword_end, nil]))
  end

  test "break and next become loop control nodes" do
    assert_equal(AST::Program.new([AST::Control.new(:break)]), parse([:keyword_break, nil]))
    assert_equal(AST::Program.new([AST::Control.new(:next)]), parse([:keyword_next, nil]))
  end

  test "redo and retry become loop control nodes" do
    assert_equal(AST::Program.new([AST::Control.new(:redo)]), parse([:keyword_redo, nil]))
    assert_equal(AST::Program.new([AST::Control.new(:retry)]), parse([:keyword_retry, nil]))
  end

  test "bare return becomes a control node" do
    assert_equal(AST::Program.new([AST::Control.new(:return)]), parse([:keyword_return, nil]))
  end

  test "self is preserved as a literal value" do
    assert_equal(AST::Program.new([literal(:self)]), parse([:keyword_self, nil]))
  end

  test "character, rational and imaginary literals preserve token values" do
    {tCHAR: "a", tRATIONAL: Rational(1, 3), tIMAGINARY: Complex(0, 2)}.each do |token, value|
      assert_equal(AST::Program.new([literal(value)]), parse([token, value]))
    end
  end

  test "instance, global and class variables preserve their kinds" do
    {tIVAR: :@value, tGVAR: :$value, tCVAR: :@@value}.each do |token, name|
      assert_equal(AST::Program.new([AST::Variable.new(token == :tIVAR ? :instance : token == :tGVAR ? :global : :class, name)]), parse([token, name]))
    end
  end

  test "constant references preserve their constant kind" do
    expected = AST::Variable.new(:constant, :Foo)
    assert_equal(AST::Program.new([expected]), parse([:tCONSTANT, :Foo]))
  end

  test "special keyword variables preserve their names" do
    {keyword__FILE__: :__FILE__, keyword__LINE__: :__LINE__, keyword__ENCODING__: :__ENCODING__}.each do |token, value|
      assert_equal(AST::Program.new([literal(value)]), parse([token, nil]))
    end
  end

  test "numbered and named back references preserve their values" do
    assert_equal(AST::Program.new([AST::Variable.new(:backref, 1)]), parse([:tNTH_REF, 1]))
    assert_equal(AST::Program.new([AST::Variable.new(:backref, :$&)]), parse([:tBACK_REF, "$&"]))
  end

  test "yield without arguments becomes a call node" do
    expected = AST::Call.new(:yield, [])
    assert_equal(AST::Program.new([expected]), parse([:keyword_yield, nil]))
  end

  test "super without arguments becomes a call node" do
    assert_equal(AST::Program.new([AST::Call.new(:super, [])]), parse([:keyword_super, nil]))
    assert_equal(AST::Program.new([AST::Call.new(:super, [])]), GeneratedRubyFrontend.parse("super()"))
  end

  test "parenthesized not becomes a logical negation" do
    expected = AST::Unary.new(:"!", literal(true))
    assert_equal(AST::Program.new([expected]), parse([:keyword_not, nil], ["(", nil], [:keyword_true, nil], [")", nil]))
  end

  test "unparenthesized not becomes a logical negation" do
    assert_equal(AST::Program.new([AST::Unary.new(:"!", literal(true))]), parse([:keyword_not, nil], [:keyword_true, nil]))
  end

  test "keyword and and or build binary ASTs" do
    assert_equal(AST::Program.new([AST::Binary.new(:and, literal(true), literal(false))]), parse([:keyword_true, nil], [:keyword_and, nil], [:keyword_false, nil]))
    assert_equal(AST::Program.new([AST::Binary.new(:or, literal(true), literal(false))]), parse([:keyword_true, nil], [:keyword_or, nil], [:keyword_false, nil]))
  end

  test "defined query becomes a call node" do
    expected = AST::Call.new(:defined, [literal(true)])
    assert_equal(AST::Program.new([expected]), parse([:keyword_defined, nil], ["(", nil], [:keyword_true, nil], [")", nil]))
  end

  test "unparenthesized defined query becomes a call node" do
    assert_equal(AST::Program.new([AST::Call.new(:defined, [literal(true)])]), parse([:keyword_defined, nil], [:keyword_true, nil]))
  end

  test "yield with an argument preserves the argument" do
    assert_equal(AST::Program.new([AST::Call.new(:yield, [literal(1)])]), parse([:keyword_yield, nil], [:tINTEGER, 1]))
  end

  test "super with an argument preserves the argument" do
    assert_equal(AST::Program.new([AST::Call.new(:super, [literal(1)])]), parse([:keyword_super, nil], [:tINTEGER, 1]))
  end

  test "command style method calls preserve their arguments" do
    assert_equal(AST::Program.new([AST::Call.new(:f, [literal(1)])]), parse([:tIDENTIFIER, :f], [:tINTEGER, 1]))
  end

  test "return with a value becomes a call node" do
    assert_equal(AST::Program.new([AST::Call.new(:return, [literal(1)])]), parse([:keyword_return, nil], [:tINTEGER, 1]))
  end

  test "break and next with values become call nodes" do
    assert_equal(AST::Program.new([AST::Call.new(:break, [literal(1)])]), parse([:keyword_break, nil], [:tINTEGER, 1]))
    assert_equal(AST::Program.new([AST::Call.new(:next, [literal(2)])]), parse([:keyword_next, nil], [:tINTEGER, 2]))
  end

  test "postfix condition and loop modifiers preserve statement order" do
    assert_equal(AST::Program.new([AST::If.new(literal(true), [literal(1)], nil)]), parse([:tINTEGER, 1], [:modifier_if, nil], [:keyword_true, nil]))
    assert_equal(AST::Program.new([AST::If.new(AST::Unary.new(:!, literal(false)), [literal(1)], nil)]), parse([:tINTEGER, 1], [:modifier_unless, nil], [:keyword_false, nil]))
  end

  test "rescue modifier preserves expression and fallback" do
    expected = AST::Rescue.new(literal(1), literal(2))
    assert_equal(AST::Program.new([expected]), parse([:tINTEGER, 1], [:modifier_rescue, nil], [:tINTEGER, 2]))
  end

  test "simple case and when build case AST nodes" do
    clause = AST::When.new([literal(1)], [literal(2)])
    expected = AST::Case.new(literal(true), [clause], nil)
    assert_equal(AST::Program.new([expected]), parse([:keyword_case, nil], [:keyword_true, nil], [:keyword_when, nil], [:tINTEGER, 1], [:keyword_then, nil], [:tINTEGER, 2], [:keyword_end, nil]))
  end

  test "case else body is preserved" do
    clause = AST::When.new([literal(1)], [literal(2)])
    expected = AST::Case.new(literal(true), [clause], [literal(3)])
    assert_equal(AST::Program.new([expected]), parse([:keyword_case, nil], [:keyword_true, nil], [:keyword_when, nil], [:tINTEGER, 1], [:keyword_then, nil], [:tINTEGER, 2], [:keyword_else, nil], [:tINTEGER, 3], [:keyword_end, nil]))
  end

  test "case without an expression preserves when clauses" do
    clause = AST::When.new([literal(true)], [literal(1)])
    expected = AST::Case.new(literal(nil), [clause], nil)
    assert_equal(AST::Program.new([expected]), parse([:keyword_case, nil], [:keyword_when, nil], [:keyword_true, nil], [:keyword_then, nil], [:tINTEGER, 1], [:keyword_end, nil]))
  end

  test "array and hash literals build structured AST nodes" do
    array = AST::ArrayLiteral.new([literal(1), literal(2)])
    assert_equal(AST::Program.new([array]), parse([:tLBRACK, nil], [:tINTEGER, 1], [",", nil], [:tINTEGER, 2], ["]", nil]))
    pair = AST::Pair.new(literal(1), literal(2))
    hash = AST::HashLiteral.new([pair])
    assert_equal(AST::Program.new([hash]), parse([:tLBRACE, nil], [:tINTEGER, 1], ["=>", nil], [:tINTEGER, 2], ["}", nil]))
    assert_equal(AST::Program.new([AST::ArrayLiteral.new([])]), parse([:tLBRACK, nil], ["]", nil]))
    assert_equal(AST::Program.new([AST::HashLiteral.new([])]), parse([:tLBRACE, nil], ["}", nil]))
  end

  test "command blocks accept block parameters" do
    assert_equal(AST::Program.new([AST::BlockCall.new(AST::Call.new(:each, []), [AST::BareCall.new(:value)])]),
      GeneratedRubyFrontend.parse("each { |value| value }"))
    assert_equal(AST::Program.new([AST::BlockCall.new(AST::Call.new(:each, []), [AST::BareCall.new(:value)])]),
      GeneratedRubyFrontend.parse("each do |value| value end"))
  end

  test "method bodies after splat arguments accept hash literals" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse('def decode(*) { foo: "decoded" } end')
    end
  end

  test "lambda blocks restore an enclosing do block" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("included do\n  value = ->(body) { body }\n  Mime[:html]\nend")
    end
  end

  test "heredoc suffixes retain literal expression context" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("value = <<~TEXT unless condition\n  body\nTEXT\n")
    end
  end

  test "singleton class endings preserve enclosing blocks" do
    source = <<~RUBY
      tests(Class.new(ActionController::Base) do
        class << self
          attr_accessor :last_parameters
        end

        def parse
        end
      end)
    RUBY
    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "method chains may continue after a newline before a dot" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = result\n  .first\n  .last") }
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("value = result\n  .first\n  # keep chaining\n  .last")
    end
  end

  test "conditional endings preserve enclosing blocks" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("include(Module.new do\n  define_method(:value) do\n    if condition\n      value\n    else\n      other\n    end\n  end\nend)")
    end
  end

  test "method endings preserve enclosing blocks" do
    source = <<~RUBY
      values = Array.new(3, Class.new do
        def create; end
        def update; end
      end)
    RUBY
    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "negative command arguments use a block do token" do
    assert_nothing_raised { GeneratedRubyFrontend.parse('assert_difference "x", -(value.count) do; value; end') }
  end

  test "operator method definitions do not start literals" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def %(other); end\ndef /(other); end") }
  end

  test "slash and percent symbols do not start literals" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("calculate(:/, value)\ncalculate(:%, value)") }
  end

  test "operator symbols end an alias expression" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias_method :regular_writer, :[]=\nunless condition\nend") }
  end

  test "ampersand symbols end an expression" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("name == :&\nname\n") }
  end

  test "Rails trick syntax remains parseable" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse(<<~RUBY)
        def source_location
          if line_number
            "on line"
          else
            "in "
          end + file_name
        end
      RUBY
      GeneratedRubyFrontend.parse(<<~RUBY)
        helper(Module.new do
          def render_from_helper
            from_test_case(suffix: "!")
          end
        end)
      RUBY
      GeneratedRubyFrontend.parse(<<~RUBY)
        def exec_queries
          super do |record|
            set_inverse(record)
            yield record if block_given?
          end
        end
      RUBY
      GeneratedRubyFrontend.parse(<<~RUBY)
        result
          .first
          # keep chaining
          .last
      RUBY
      GeneratedRubyFrontend.parse(<<~RUBY)
        def create_table(table_name, **options)
          if block_given?
            super { |table| yield compatible_table_definition(table) }
          else
            super
          end
        end
      RUBY
    end
  end

  test "source lexer recognizes lambda as a lambda expression" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = lambda do\n  work\nend\n") }
  end

  test "method bodies may start with an array literal after arguments" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def multi(a, b, c) [a, b, c] end") }
  end

  test "singleton method definitions may parenthesize their receiver" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def (object.foo).bar(value)\n  value\nend") }
  end

  test "if, unless, elsif and else build conditional AST nodes" do
    expected = AST::Program.new([AST::If.new(literal(true), [literal(1)], [literal(2)])])
    assert_equal(expected, parse([:keyword_if, nil], [:keyword_true, nil], [:keyword_then, nil], [:tINTEGER, 1], [:keyword_else, nil], [:tINTEGER, 2], [:keyword_end, nil]))
    unless_tree = AST::Program.new([AST::If.new(AST::Unary.new(:!, literal(true)), [literal(1)], nil)])
    assert_equal(unless_tree, parse([:keyword_unless, nil], [:keyword_true, nil], [:keyword_then, nil], [:tINTEGER, 1], [:keyword_end, nil]))
    nested = AST::Program.new([AST::If.new(literal(true), [literal(1)], AST::If.new(literal(false), [literal(2)], [literal(3)]))])
    assert_equal(nested, parse([:keyword_if, nil], [:keyword_true, nil], [:keyword_then, nil], [:tINTEGER, 1], [:keyword_elsif, nil], [:keyword_false, nil], [:keyword_then, nil], [:tINTEGER, 2], [:keyword_else, nil], [:tINTEGER, 3], [:keyword_end, nil]))
  end

  test "unary operators" do
    [[:tUPLUS, :+], [:tUMINUS, :-], [:tUMINUS_NUM, :-]].each do |token, operator|
      assert_equal(AST::Program.new([AST::Unary.new(operator, literal(2))]), parse([token, nil], [:tINTEGER, 2]))
    end
  end

  test "assignment and subsequent local reference" do
    [";", "\n"].each do |separator|
      expected = AST::Program.new([AST::LocalWrite.new(:a, literal(1)), AST::Binary.new(:+, AST::LocalRead.new(:a), literal(2))])
      assert_equal(expected, parse([:tIDENTIFIER, :a], ["=", nil], [:tINTEGER, 1], [separator, nil], [:tIDENTIFIER, :a], ["+", nil], [:tINTEGER, 2]))
    end
    assert_equal(AST::Program.new([AST::LocalWrite.new(:a, AST::LocalRead.new(:a))]), parse([:tIDENTIFIER, :a], ["=", nil], [:tIDENTIFIER, :a]))
  end

  test "bare names and parse state isolation" do
    expected = AST::Program.new([AST::BareCall.new(:a)])
    assert_equal(expected, parse([:tIDENTIFIER, "a"]))
    parse([:tIDENTIFIER, :a], ["=", nil], [:tINTEGER, 1])
    assert_equal(expected, parse([:tIDENTIFIER, :a]))
    assert_raise(GeneratedRubyFrontend::ParseError) { parse([:tIDENTIFIER, :a], ["=", nil]) }
    assert_equal(expected, parse([:tIDENTIFIER, :a]))
  end

  test "unsupported syntax reports its upstream rule" do
    inputs = []
    inputs.each do |tokens|
      error = assert_raise(GeneratedRubyFrontend::UnsupportedSyntax) { GeneratedRubyFrontend.send(:parse_tokens, tokens) }
      assert_kind_of(String, error.rule)
      assert_kind_of(Integer, error.line)
      assert_include(error.message, "upstream parse.y:")
    end
    assert_equal(AST::Program.new([literal(1)]), parse([:tINTEGER, 1]))
  end

  test "invalid token streams stop without recovery" do
    [[[:UNKNOWN, nil]], [[256, nil]], [[:tINTEGER, 1], ["+", nil]], [[:tINTEGER, 1], [:tINTEGER, 2]]].each do |tokens|
      assert_raise(GeneratedRubyFrontend::ParseError) { GeneratedRubyFrontend.send(:parse_tokens, tokens) }
    end
  end

  test "source input uses the Ruby lexer and preserves token parse results" do
    expected = AST::Program.new([
      AST::LocalWrite.new(:a, literal(1)),
      AST::Binary.new(:+, AST::LocalRead.new(:a), literal(2))
    ])
    assert_equal(expected, GeneratedRubyFrontend.parse("a = 1\na + 2", filename: "example.rb"))
    assert_equal(AST::Program.new([AST::Call.new(:f, [literal(1), literal(2)])]),
      GeneratedRubyFrontend.parse("f(1, 2)"))
    assert_equal(AST::Program.new([AST::StringLiteral.new("hello")]),
      GeneratedRubyFrontend.parse('"hello"'))
  end

  test "source lexer errors include source position" do
    error = assert_raise(GeneratedRubyFrontend::LexerError) { GeneratedRubyFrontend.parse('"unterminated', filename: "broken.rb") }
    assert_include(error.message, "broken.rb:1:")
  end

  test "source lexer preserves literal kinds" do
    assert_equal(AST::XStringLiteral.new("echo"), GeneratedRubyFrontend.parse("`echo`").statements.first)
    assert_equal(AST::RegexpLiteral.new("a[b]"), GeneratedRubyFrontend.parse("/a[b]/").statements.first)
    assert_equal(AST::StringLiteral.new("quiet"), GeneratedRubyFrontend.parse("%q(quiet)").statements.first)
    assert_equal(AST::ArrayLiteral.new([AST::StringLiteral.new("one"), AST::StringLiteral.new("two")]),
      GeneratedRubyFrontend.parse("%w(one two)").statements.first)
    assert_equal(AST::ArrayLiteral.new([:one, :two]),
      GeneratedRubyFrontend.parse("%i(one two)").statements.first)
    assert_equal(AST::RegexpLiteral.new("a"), GeneratedRubyFrontend.parse("%r(a)").statements.first)
  end

  test "source lexer preserves simple string interpolation" do
    assert_equal(AST::InterpolatedString.new([
      "hello ", AST::Binary.new(:+, literal(1), literal(2)), " world"
    ]), GeneratedRubyFrontend.parse('"hello #{1 + 2} world"').statements.first)
    assert_equal(AST::InterpolatedString.new([AST::BareCall.new(:name)]),
      GeneratedRubyFrontend.parse('"#{name}"').statements.first)
  end

  test "source lexer preserves interpolation in percent strings" do
    expected = AST::InterpolatedString.new(["hello ", AST::BareCall.new(:name)])
    assert_equal(expected, GeneratedRubyFrontend.parse('%Q(hello #{name})').statements.first)
    assert_equal(expected, GeneratedRubyFrontend.parse('%(hello #{name})').statements.first)
    assert_kind_of(AST::RegexpLiteral, GeneratedRubyFrontend.parse('%r(#{x})').statements.first)
  end

  test "source lexer handles heredoc indentation and line endings" do
    assert_equal(AST::StringLiteral.new("one\n  two\n"),
      GeneratedRubyFrontend.parse("<<~TEXT\n  one\n    two\n  TEXT\n").statements.first)
    assert_equal(AST::StringLiteral.new("  one\n"),
      GeneratedRubyFrontend.parse("<<-TEXT\n  one\n    TEXT\n").statements.first)
    assert_equal(AST::StringLiteral.new("one\r\ntwo\r\n"),
      GeneratedRubyFrontend.parse("<<TEXT\r\none\r\ntwo\r\nTEXT\r\n").statements.first)
    assert_equal(AST::XStringLiteral.new("echo\n"),
      GeneratedRubyFrontend.parse("<<`TEXT`\necho\nTEXT\n").statements.first)
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("warn(<<~MSG.squish)\n  warning\nMSG\naddress\n")
    end
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("warn <<~MSG\n  warning\nMSG\naddress\n")
    end
  end

  test "source lexer handles multiple heredocs on one line" do
    source = "value = <<FIRST, <<SECOND\nfirst\nFIRST\nsecond\nSECOND\n"
    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end

  test "source lexer distinguishes shifts and command symbols" do
    assert_equal(AST::Binary.new(:<<, literal(1), literal(2)),
      GeneratedRubyFrontend.parse("1 << 2").statements.first)
    assert_equal(AST::Literal.new(:bar),
      GeneratedRubyFrontend.parse("foo = :bar").statements.first.value)
    assert_equal(AST::RangeLiteral.new(:"...", literal(1), literal(3)),
      GeneratedRubyFrontend.parse("1...3").statements.first)
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("def f(...)").each.to_a
    assert_equal(:tBDOT3, tokens[3].first)
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("def f(value, ...)").each.to_a
    assert_equal(:tBDOT3, tokens[5].first)
  end

  test "source lexer preserves UTF-8 character literals" do
    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("?h ?あ")
    tokens = lexer.each.to_a
    assert_equal([:tCHAR, :tCHAR], tokens.first(2).map(&:first))
    assert_equal(["h", "あ"], tokens.first(2).map(&:last))
  end

  test "source lexer exposes parse-local lexical context" do
    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f(1)")
    assert_equal(:expr_beg, lexer.context.lex_state)
    assert_true(lexer.context.command_start)
    lexer.each.to_a
    assert_equal(:expr_end, lexer.context.lex_state)
    assert_false(lexer.context.command_start)
    assert_equal([], lexer.context.delimiter_stack)
    assert_equal([:tIDENTIFIER, "(", :tINTEGER, ")"], lexer.context.token_history)
    assert_equal([:tIDENTIFIER, "(", :tINTEGER, ")"],
      lexer.context.state_history.map { |entry| entry.fetch(:token) })
    assert_equal(1, lexer.context.state_history[1].fetch(:delimiter_depth))
    assert_equal(0, lexer.context.state_history.last.fetch(:delimiter_depth))

    hash_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("{a: 1}")
    hash_lexer.each.to_a
    hash_states = hash_lexer.context.state_history
    assert_equal(1, hash_states.find { |entry| entry.fetch(:token) == :tLBRACE }.fetch(:delimiter_depth))
    assert_equal(0, hash_states.find { |entry| entry.fetch(:token) == "}" }.fetch(:delimiter_depth))

    command_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f (1)")
    command_lexer.each.to_a
    command_states = command_lexer.context.state_history
    assert_equal(1, command_states.find { |entry| entry.fetch(:token) == :tLPAREN_ARG }.fetch(:cmdarg_depth))
    assert_equal(0, command_states.find { |entry| entry.fetch(:token) == ")" }.fetch(:cmdarg_depth))

    block_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f do; 1; end")
    block_lexer.each.to_a
    block_states = block_lexer.context.state_history
    assert_equal(1, block_states.find { |entry| entry.fetch(:token) == :keyword_do }.fetch(:block_depth))
    assert_equal(0, block_states.find { |entry| entry.fetch(:token) == :keyword_end }.fetch(:block_depth))

    scope_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("def f; end")
    scope_lexer.each.to_a
    scope_states = scope_lexer.context.state_history
    assert_equal(1, scope_states.find { |entry| entry.fetch(:token) == :keyword_def }.fetch(:scope_depth))
    assert_equal(0, scope_states.find { |entry| entry.fetch(:token) == :keyword_end }.fetch(:scope_depth))

    brace_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f { 1 }")
    brace_lexer.each.to_a
    brace_states = brace_lexer.context.state_history
    assert_equal(1, brace_states.find { |entry| entry.fetch(:token) == "{" }.fetch(:block_depth))
    assert_equal(0, brace_states.find { |entry| entry.fetch(:token) == "}" }.fetch(:block_depth))

    other = GeneratedRubyFrontend.const_get(:Lexer, false).new("value")
    assert_equal(:expr_beg, other.context.lex_state)
    assert_true(other.context.command_start)
    other.send(:next_token)
    assert_false(other.context.command_start)
    other.each.to_a
    assert_equal(:expr_end, other.context.lex_state)
    assert_false(other.context.command_start)
  end

  test "parser feeds shift and reduce events into source context" do
    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f(1)")
    GeneratedRubyFrontend.send(:parse_tokens, lexer.each, lexical_context: lexer.context)
    assert_true(lexer.context.parser_events.any? { |event| event.first == :shift })
    assert_true(lexer.context.parser_events.any? { |event| event.first == :reduce })
    assert_empty(lexer.context.parser_delimiter_stack)
    assert_empty(lexer.context.parser_cmdarg_stack)
    assert_empty(lexer.context.parser_block_stack)
    block_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f do; 1; end")
    GeneratedRubyFrontend.send(:parse_tokens, block_lexer.each, lexical_context: block_lexer.context)
    assert_empty(block_lexer.context.parser_block_stack)
    condition_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("while condition do; body; end")
    GeneratedRubyFrontend.send(:parse_tokens, condition_lexer.each, lexical_context: condition_lexer.context)
    assert_empty(condition_lexer.context.parser_condition_stack)
    scope_lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("def f; -> { 1 }; end")
    GeneratedRubyFrontend.send(:parse_tokens, scope_lexer.each, lexical_context: scope_lexer.context)
    assert_empty(scope_lexer.context.parser_scope_stack)
    pretokenized = GeneratedRubyFrontend.const_get(:Lexer, false).new("f(1)")
    tokens = pretokenized.each.to_a
    GeneratedRubyFrontend.send(:parse_tokens, tokens)
    assert_empty(pretokenized.context.parser_events)
  end

  test "source lexer enters fname state for definitions and aliases" do
    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("def value=; end")
    lexer.each.to_a
    def_name = lexer.context.state_history.find do |entry|
      entry.fetch(:token) == :tFID
    end
    assert_equal(:expr_fname, def_name.fetch(:lex_state))

    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("alias eql? ==")
    lexer.each.to_a
    alias_name = lexer.context.state_history.find do |entry|
      entry.fetch(:token) == :tFID
    end
    assert_equal(:expr_fname, alias_name.fetch(:lex_state))
  end

  test "source lexer distinguishes label and labeled states" do
    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("f at: 1")
    lexer.each.to_a
    states = lexer.context.state_history
    assert_equal(:expr_label, states.find { |entry| entry.fetch(:token) == :tLABEL }.fetch(:lex_state))
    assert_equal(:expr_labeled, states.find { |entry| entry.fetch(:token) == :tINTEGER }.fetch(:lex_state))
  end

  test "source lexer treats spaced empty brackets as an array literal" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("assert_equal [], value").each.to_a
    assert_equal([:tIDENTIFIER, :tLBRACK, "]", ",", :tIDENTIFIER, 0], tokens.map(&:first))
  end

  test "source lexer treats spaced bracket arguments as array literals" do
    tree = GeneratedRubyFrontend.parse("foo [1], name: 2").statements.first
    assert_equal(AST::ArrayLiteral.new([literal(1)]), tree.arguments.first)
    assert_equal(AST::Pair.new(AST::Literal.new(:name), literal(2)), tree.arguments.last)
  end

  test "source lexer treats predicate and bang methods as identifiers" do
    assert_equal(AST::Def.new(:stopping?, [], [literal(1)]),
      GeneratedRubyFrontend.parse("def stopping?; 1; end").statements.first)
    assert_equal(AST::Def.new(:halt!, [], [literal(1)]),
      GeneratedRubyFrontend.parse("def halt!; 1; end").statements.first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("value.match?(pattern)") }
  end

  test "source lexer handles contextual punctuation in Ruby expressions" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("f(foo?: true)").each.to_a
    assert_equal([:tIDENTIFIER, "(", :tLABEL, :keyword_true, ")", 0], tokens.map(&:first))
    assert_nothing_raised { GeneratedRubyFrontend.parse("f(foo?: true)") }

    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("list_tables[]").each.to_a
    assert_equal([:tIDENTIFIER, "[", "]", 0], tokens.map(&:first))
    assert_kind_of(AST::Index, GeneratedRubyFrontend.parse("list_tables[]").statements.first)

    assert_nothing_raised { GeneratedRubyFrontend.parse("x = if y; 'a'; else; 'b'; end + z") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("helper.({a: 1})") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("assert ?h.in?(\"hello\")") }
  end

  test "source lexer uses regular brace blocks for calls and proc values" do
    ["foo { 1 }", "[proc { 1 }]", "foo { 1 }.first", "foo { 1 } || bar"].each do |source|
      tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new(source).each.to_a
      assert_not_include(tokens.map(&:first), :tAMPER, source)
      assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
    end

    assert_nothing_raised { GeneratedRubyFrontend.parse("f(&block)") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("map(&:to_s)") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("a & b") }
  end

  test "source lexer keeps definition and block contexts for operators" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def ==(x); self.x == x; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("def []=(x); x; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("x = -> *args do; 1; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("def f; super do |x| x end; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("def f; super { |x| x }; end") }
  end

  test "source lexer distinguishes splat and block argument operators" do
    assert_equal(AST::Call.new(:f, [AST::BareCall.new(:args)]),
      GeneratedRubyFrontend.parse("f(*args)").statements.first)
    assert_equal(AST::Call.new(:map, AST::Literal.new(:to_s)),
      GeneratedRubyFrontend.parse("map(&:to_s)").statements.first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("f(1, *args)") }
  end

  test "symbols can be built from variable-shaped values" do
    builder = GeneratedRubyFrontend.const_get(:Builder, false).new
    assert_equal(AST::Literal.new(:value), builder.symbol(AST::Variable.new(:local, :value)))
  end

  test "source lexer accepts argumentless command blocks" do
    assert_equal(AST::BlockCall.new(AST::Call.new(:included, []), [literal(1)]),
      GeneratedRubyFrontend.parse("included do\n  1\nend").statements.first)
    assert_equal(AST::BlockCall.new(AST::ReceiverCall.new(AST::BareCall.new(:foo), :".", :bar, []), [literal(1)]),
      GeneratedRubyFrontend.parse("foo.bar do\n  1\nend").statements.first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("foo before: :bar do |value| value end\n") }
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("items << lambda do").each.to_a
    assert_equal([:tIDENTIFIER, :tLSHFT, :tIDENTIFIER, :keyword_do], tokens[0, 4].map(&:first))
    assert_nothing_raised { GeneratedRubyFrontend.parse("items << lambda do\n  work\nend\n") }
  end

  test "source lexer recognizes shorthand percent literals in command arguments" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("assert %(value)\n").each.to_a
    assert_equal([:tIDENTIFIER, :tSTRING_BEG, :tSTRING_CONTENT, :tSTRING_END], tokens[0, 4].map(&:first))
    assert_equal(AST::StringLiteral.new("value"), GeneratedRubyFrontend.parse("assert %(value)\n").statements.first.arguments.first)
  end

  test "source lexer recognizes beginless ranges" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("f in: ..range_end\n").each.to_a
    assert_equal(:tBDOT2, tokens.map(&:first)[2])
    assert_nothing_raised { GeneratedRubyFrontend.parse("f in: ..range_end\n") }
  end

  test "source lexer keeps special global variables intact" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new(%q{"pid #{$$}"\n}).each.to_a
    assert_equal([:tSTRING_BEG, :tSTRING_CONTENT, :tSTRING_DBEG, :tGVAR, :tSTRING_DEND, :tSTRING_END],
      tokens[0, 6].map(&:first))
    assert_equal(:"$$", tokens[3][1])
  end

  test "source lexer keeps the load path global intact" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("$:.unshift(\"lib\")\n").each.to_a
    assert_equal(:tGVAR, tokens.first.first)
    assert_equal(:"$:", tokens.first.last)
    assert_nothing_raised { GeneratedRubyFrontend.parse("$:.unshift(\"lib\")\n") }
  end

  test "source lexer treats keyword-shaped method names as fname tokens" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("def then(&block)\nend\n").each.to_a
    assert_equal(:tFID, tokens[1].first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("def then(&block)\nend\n") }
  end

  test "source lexer preserves newlines before terminators" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def empty\nend\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("if condition\nend\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("foo do\nend\n") }
  end

  test "source lexer preserves block newlines inside calls" do
    source = "Module.new {\n  define_method(:up) { yield(:up); super() }\n  define_method(:down) { yield(:down); super() }\n}\n"
    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
    assert_nothing_raised { GeneratedRubyFrontend.parse("Module.new do\n  define_method(:up) do\n    1\n  end\n  define_method(:down) do\n    2\n  end\nend\n") }
  end

  test "source lexer keeps block newlines at their owning delimiter" do
    source = "f(-> {\n  if condition\n    first\n  else\n    second\n  end\n})\n"
    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }

    nested = "f {\n  g(\n    first,\n    second\n  )\n}\n"
    assert_nothing_raised { GeneratedRubyFrontend.parse(nested) }
  end

  test "source lexer ignores newlines after operator assignments" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value ||=\n  if condition\n    fallback\n  end\n") }
  end

  test "source lexer uses ordinary do after parenthesized calls" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("each(1) do\nend").each.to_a
    assert_equal(:keyword_do, tokens.map(&:first)[-4])
    assert_equal(AST::BlockCall.new(AST::Call.new(:each, [literal(1)]), []),
      GeneratedRubyFrontend.parse("each(1) do\nend").statements.first)
  end

  test "source lexer does not carry conditional do across statements" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("while condition\n  body\nend\nfoo do\nend\n").each.to_a
    assert_equal(:keyword_do, tokens.map(&:first)[-5])
  end

  test "source lexer balances conditional context" do
    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("while condition do; body; end")
    tokens = lexer.each.to_a
    assert_includes(tokens.map(&:first), :keyword_do_cond)
    assert_empty(lexer.context.condition_stack)

    lexer = GeneratedRubyFrontend.const_get(:Lexer, false).new("until condition\nbody\nend")
    lexer.each.to_a
    assert_empty(lexer.context.condition_stack)
  end

  test "grammar precedence accepts block calls as parenthesized arguments" do
    tree = GeneratedRubyFrontend.parse("call(lambda do\nend)\n")
    assert_equal(AST::Call.new(:call, [AST::BlockCall.new(AST::Call.new(:lambda, []), [])]), tree.statements.first)

    assert_nothing_raised do
      GeneratedRubyFrontend.parse("subscribe(x, handler, lambda do\n  work\nend)\n")
    end
  end

  test "source lexer uses brace blocks after parenthesized calls" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("each(1) { |value| value }\n").each.to_a
    assert_equal("{", tokens.map(&:first)[4])
    assert_nothing_raised { GeneratedRubyFrontend.parse("each(1) { |value| value }\n") }
  end

  test "source lexer uses brace blocks after receiver method calls" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("mutex.synchronize { 1 }\n").each.to_a
    assert_equal("{", tokens.map(&:first)[3])
    assert_nothing_raised { GeneratedRubyFrontend.parse("mutex.synchronize { 1 }\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("mutex.synchronize {\n  first\n  second\n}\n") }
  end

  test "source lexer uses brace blocks after calls inside arguments" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("outer(1, inner { 2 })\n").each.to_a
    assert_equal("{", tokens.map(&:first)[5])
    assert_nothing_raised { GeneratedRubyFrontend.parse("outer(1, inner { 2 })\n") }
  end

  test "source lexer chains methods after assignment brace blocks" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("value = call { 1 }.dup\n").each.to_a
    assert_equal("{", tokens.map(&:first)[3])
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = call { 1 }.dup\n") }
  end

  test "source lexer uses regular brace blocks inside call arguments" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("outer(call { 1 })\n").each.to_a
    assert_equal("{", tokens.map(&:first)[3])
    assert_nothing_raised { GeneratedRubyFrontend.parse("outer(call { 1 })\n") }
  end

  test "source lexer starts one-line method bodies with array literals" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("def values() [1] end\n").each.to_a
    assert_equal(:tLBRACK, tokens.map(&:first)[4])
    assert_nothing_raised { GeneratedRubyFrontend.parse("def values() [1] end\n") }
  end

  test "source lexer uses regular brace blocks after ternary branches" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("touch ? callback { 1 } : fallback\n").each.to_a
    assert_equal("{", tokens.map(&:first)[3])
    assert_nothing_raised { GeneratedRubyFrontend.parse("touch ? callback { 1 } : fallback\n") }
  end

  test "source lexer preserves newlines inside command blocks" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("app = lambda { |env|\n  req = Request.new(env)\n  res = response(req)\n}\n")
    end
  end

  test "source lexer recognizes lambda bodies after lambda arguments" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("->(value) { value }\n").each.to_a
    assert_includes(tokens.map(&:first), :tLAMBEG)
    assert_nothing_raised { GeneratedRubyFrontend.parse("->(value) { value }\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("-> {\n  first\n  second\n}\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("f(&lambda { |value| value })\n") }
  end

  test "source lexer ignores newlines after logical operators" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("left &&\nright\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left ||\nright\n") }
  end

  test "source lexer recognizes modifiers after argumentless control keywords" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("return unless value\n").each.to_a
    assert_equal(:modifier_unless, tokens[1].first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("def stop\n  return unless value\nend\n") }
  end

  test "source lexer recognizes modifiers after block endings" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("foo do\nend unless value\n").each.to_a
    assert_equal(:modifier_unless, tokens[4].first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("foo do\nend unless value\n") }
  end

  test "source lexer accepts escaped newlines between expressions" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("\"left\" \\\n\"right\"\n").each.to_a
    assert_equal([:tSTRING_BEG, :tSTRING_CONTENT, :tSTRING_END, :tSTRING_BEG], tokens.map(&:first)[0, 4])
    assert_nothing_raised { GeneratedRubyFrontend.parse("\"left\" \\\n\"right\"\n") }
  end

  test "source lexer continues method chains after newlines" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value\n  .first\n  .to_s\n") }
  end

  test "source lexer ignores newlines before block parameters" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("call {\n  |value| value\n}\n") }
  end

  test "source lexer continues keyword arguments after label newlines" do
    assert_nothing_raised do
      GeneratedRubyFrontend.parse("parse(file, context:\n  build_context)\n")
    end
  end

  test "source lexer recognizes string hash labels" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("{ \"key\": value }\n") }
  end

  test "source lexer recognizes unary operator symbols" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias :-@ :deduplicate\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias_method :push, :<<\nalias_method :append, :<<\n") }
  end

  test "source lexer recognizes operator method names and top-level constants" do
    assert_equal(AST::Def.new(:[], :x, [AST::BareCall.new(:x)]),
      GeneratedRubyFrontend.parse("def [](x); x; end").statements.first)
    assert_nothing_raised { GeneratedRubyFrontend.parse("def /(other); other; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("def &(other); other; end") }
    assert_equal(:Foo, GeneratedRubyFrontend.parse("::Foo").statements.first)
  end

  test "source lexer preserves alias boundaries and symbol statement endings" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("alias foo= bar").each.to_a
    assert_equal([:keyword_alias, :tFID, :tIDENTIFIER, 0], tokens.map(&:first))
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias foo= bar") }

    source = "alias_method :eql?, :==\ndef hash; 1; end"
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new(source).each.to_a
    assert_include(tokens.map(&:first), "\n")
    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }

    assert_nothing_raised { GeneratedRubyFrontend.parse("undef_method :==, :!, :!=\ndef hash; 1; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias [] get") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias []= get") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias :eql? :==\n\ndef hash; 1; end") }
  end

  test "source lexer allows keyword-shaped receiver setters" do
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new("node.case = value").each.to_a
    assert_equal([:tIDENTIFIER, ".", :tIDENTIFIER, "=", :tIDENTIFIER, 0], tokens.map(&:first))
    assert_nothing_raised { GeneratedRubyFrontend.parse("node.case = value") }
  end

  test "source lexer accepts symbols after predicate-like identifiers" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias :merge! :update\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("alias :default_options= :default\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("block_given? ? yield : @default_render.call\n") }
  end

  test "source lexer accepts interpolated symbols" do
    assert_nothing_raised { GeneratedRubyFrontend.parse(':"#{name}_settings"') }
    assert_nothing_raised { GeneratedRubyFrontend.parse("super(:/, left, right)") }
  end

  test "source lexer scans slashes inside regexp interpolation" do
    source = '/#{value.sub(/x/, "")}/'
    tokens = GeneratedRubyFrontend.const_get(:Lexer, false).new(source).each.to_a
    assert_equal([:tREGEXP_BEG, :tSTRING_DBEG, :tIDENTIFIER, ".", :tIDENTIFIER,
      "(", :tREGEXP_BEG, :tSTRING_CONTENT, :tREGEXP_END, ",", :tSTRING_BEG,
      :tSTRING_END, ")", :tSTRING_DEND, :tREGEXP_END, 0], tokens.map(&:first))
    assert_kind_of(AST::RegexpLiteral, GeneratedRubyFrontend.parse(source).statements.first)
  end

  test "source lexer accepts ampersand operator symbols" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("items.reduce(:&)\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("delegate :[], :[]=, to: :paths\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left &\n  right\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left |\n  right\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left ^\n  right\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("foo *args\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("foo **options\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("first..\n  last\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left and\n  right\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left or\n  right\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("left ==\n  right\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("not\n  value\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("fn = ->\n  { 1 }\n") }
  end

  test "source lexer recognizes bitwise assignment operators" do
    %w[|= &= ^=].each do |operator|
      assert_nothing_raised { GeneratedRubyFrontend.parse("value #{operator} other\n") }
    end
  end

  test "source lexer recognizes class variables" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("@@templates = {}\n@@templates\n") }
  end

  test "source lexer recognizes punctuation global variables" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("-$`\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("$&\n") }
  end

  test "source lexer parses parenthesized yield arguments" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def each\n  yield(value, other)\nend\n") }
  end

  test "source lexer distinguishes modulo from percent literals" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = (left + right) % 3\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = %q(text)\n") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = %r{pattern}i\n") }
  end

  test "source lexer accepts percent literals as command arguments" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def f; assert_match %r{a}, value; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("def f; assert_equal %w[a b], value; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("test do; assert_equal %w[a b], value; end") }
  end

  test "source lexer keeps expression-ending keywords and globals together" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("test do; f __LINE__ + 1; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("module M; def f; yield if true; end; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("class C; def f; super if true; end; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("$?.exitstatus") }
  end

  test "source lexer distinguishes command argument delimiters and blocks" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("f ::Time, value") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("def f; assert_equal (count * 2) - 1, total; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = { xml: lambda { 1 } }") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("f(:x, proc { 1 })") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("f :x, lambda { 1 }") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("-> arg do; arg; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("test do; f only: A::B do; 1; end; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("f at: 30.days.from_now do; 1; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("travel_to Time.now + 3.seconds do; 1; end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("value = left || proc { 1 }") }
  end

  test "source lexer accepts lambda argument defaults" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("def [](x, y = nil); end") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("->(x = nil) { x }") }
  end

  test "source lexer ignores pending heredoc newlines in delimiters" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("f({a: <<~A,\nx\nA\nb: 1})") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("f unless\n  predicate") }
    assert_nothing_raised { GeneratedRubyFrontend.parse("f(\nproc { 1 }\n)\n") }
  end

  test "source lexer terminates aliases whose target is an operator" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("class C\n  alias eql? ==\n  def hash\n    1\n  end\nend\n") }
  end

  test "single quoted heredoc keeps interpolation literal" do
    assert_equal(AST::StringLiteral.new("\#{x}\n"),
      GeneratedRubyFrontend.parse("<<'TEXT'\n\#{x}\nTEXT\n").statements.first)
  end
end

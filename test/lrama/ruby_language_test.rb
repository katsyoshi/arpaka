# frozen_string_literal: true

require "test_helper"
require "lrama/ruby/languages/ruby"
require "open3"
require "rbconfig"

class Lrama::RubyLanguageTest < Test::Unit::TestCase
  AST = Lrama::Ruby::Languages::Ruby::AST

  def parse(*tokens)
    Lrama::Ruby.parse(tokens, language: :ruby)
  end

  def literal(value)
    AST::Literal.new(value)
  end

  test "language is required and unsupported languages fail explicitly" do
    assert_raise(ArgumentError) { Lrama::Ruby.parse([]) }
    [:c, "ruby", nil].each do |language|
      assert_raise(ArgumentError) { Lrama::Ruby.parse([], language: language) }
    end
  end

  test "generic parsers and Ruby ASTs coexist" do
    parser = Lrama::Ruby.compile("%%\nstart: %empty { $$ = 42 };").new
    assert_equal(AST::Program.new([]), parse)
    assert_equal(42, parser.parse([]))
    assert_false(Object.const_defined?(:RubyParser))
  end

  test "generated reductions retain readable rules and named actions" do
    path = File.expand_path("../../lib/lrama/ruby/languages/ruby/parse.y", __dir__)
    source = Lrama::Ruby.generate(File.read(path), allow_error_rules: true)
    assert_include(source, "# arg: arg '+' arg")
    assert_include(source, "@builder.binary(:+, ")
    assert_not_include(source, "@builder.reduce(")
  end

  test "first generation is synchronized and failed generation can be retried" do
    script = <<~'RUBY'
      require "lrama/ruby"
      original = Lrama::Ruby.method(:compile)
      attempts = 0
      Lrama::Ruby.define_singleton_method(:compile) do |*args, **options|
        attempts += 1
        raise "generation failed" if attempts == 1
        sleep 0.05
        original.call(*args, **options)
      end
      begin
        Lrama::Ruby.parse([], language: :ruby)
        abort "failure was swallowed"
      rescue RuntimeError => error
        raise unless error.message == "generation failed"
      end
      threads = 4.times.map do
        Thread.new { Lrama::Ruby.parse([[:tINTEGER, 3]], language: :ruby) }
      end
      trees = threads.map(&:value)
      abort "wrong AST" unless trees.all? { |tree| tree.statements.first.value == 3 }
      Lrama::Ruby.parse([], language: :ruby)
      abort "generated more than once after retry" unless attempts == 2
    RUBY
    _output, error, result = Open3.capture3({ "RUBY_BOX" => "1" }, RbConfig.ruby, "-Ilib", "-e", script)
    assert_predicate(result, :success?, error)
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

  test "array and hash literals build structured AST nodes" do
    array = AST::ArrayLiteral.new([literal(1), literal(2)])
    assert_equal(AST::Program.new([array]), parse([:tLBRACK, nil], [:tINTEGER, 1], [",", nil], [:tINTEGER, 2], ["]", nil]))
    pair = AST::Pair.new(literal(1), literal(2))
    hash = AST::HashLiteral.new([pair])
    assert_equal(AST::Program.new([hash]), parse([:tLBRACE, nil], [:tINTEGER, 1], ["=>", nil], [:tINTEGER, 2], ["}", nil]))
    assert_equal(AST::Program.new([AST::ArrayLiteral.new([])]), parse([:tLBRACK, nil], ["]", nil]))
    assert_equal(AST::Program.new([AST::HashLiteral.new([])]), parse([:tLBRACE, nil], ["}", nil]))
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
    assert_raise(Lrama::Ruby::Languages::Ruby::ParseError) { parse([:tIDENTIFIER, :a], ["=", nil]) }
    assert_equal(expected, parse([:tIDENTIFIER, :a]))
  end

  test "unsupported syntax reports its upstream rule" do
    inputs = [
      [[:tSTRING_BEG, nil], [:tSTRING_CONTENT, "text"], [:tSTRING_END, nil]],
      [[:tIDENTIFIER, :f], ["(", nil], [")", nil]],
      [[:keyword_def, nil], [:tIDENTIFIER, :f], [";", nil], [:keyword_end, nil]]
    ]
    inputs.each do |tokens|
      error = assert_raise(Lrama::Ruby::Languages::Ruby::UnsupportedSyntax) { Lrama::Ruby::Languages::Ruby.parse(tokens) }
      assert_kind_of(String, error.rule)
      assert_kind_of(Integer, error.line)
      assert_include(error.message, "upstream parse.y:")
    end
    assert_equal(AST::Program.new([literal(1)]), parse([:tINTEGER, 1]))
  end

  test "invalid token streams stop without recovery" do
    [[[:UNKNOWN, nil]], [[256, nil]], [[:tINTEGER, 1], ["+", nil]], [[:tINTEGER, 1], [:tINTEGER, 2]]].each do |tokens|
      assert_raise(Lrama::Ruby::Languages::Ruby::ParseError) { Lrama::Ruby::Languages::Ruby.parse(tokens) }
    end
  end
end

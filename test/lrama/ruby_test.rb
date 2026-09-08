# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"
require "tmpdir"

class Lrama::RubyTest < Test::Unit::TestCase
  CALCULATOR = File.read(File.expand_path("../../examples/calculator.y", __dir__))

  test "VERSION" do
    assert(::Lrama::Ruby.const_defined?(:VERSION))
  end

  test "arithmetic precedence, associativity and parentheses" do
    parser = compile(CALCULATOR).new
    assert_equal(14, parser.parse([[:NUMBER, 2], ["+", nil], [:NUMBER, 3], ["*", nil], [:NUMBER, 4]]))
    assert_equal(3, parser.parse([[:NUMBER, 8], ["-", nil], [:NUMBER, 3], ["-", nil], [:NUMBER, 2]]))
    assert_equal(20, parser.parse([["(", nil], [:NUMBER, 2], ["+", nil], [:NUMBER, 3], [")", nil], ["*", nil], [:NUMBER, 4]]))
  end

  test "numeric token IDs, aliases, and explicit EOF" do
    parser = compile('%token NUMBER 300 "number"' + "\n%%\nstart: NUMBER;").new
    assert_equal(false, parser.parse([[300, false], [0, nil]]))
    assert_equal(42, parser.parse([["number", 42]]))
  end

  test "empty productions and default semantic actions" do
    assert_nil(compile("%%\nstart: %empty;").new.parse([]))
    assert_equal([], compile("%%\nstart: %empty { $$ = [] }; ").new.parse([]))
  end

  test "named and midrule references" do
    grammar = <<~'YACC'
      %token NUMBER
      %%
      start: NUMBER[left] { $$ = $left * 2 } NUMBER[right] { $start = $2 + $right };
    YACC
    assert_equal(10, compile(grammar).new.parse([[:NUMBER, 3], [:NUMBER, 4]]))
  end

  test "Ruby strings, comments, regexps, hashes and instance variables" do
    grammar = <<~'YACC'
      %token NUMBER
      %%
      start: NUMBER {
        # Ignore } and $missing here.
        @offset = 2
        text = "日本語 $missing }"
        pattern = /[}]/
        $$ = { value: $1 + @offset, text: text, matched: pattern.match?("}") }
      };
    YACC
    assert_equal({ value: 5, text: "日本語 $missing }", matched: true }, compile(grammar).new.parse([[:NUMBER, 3]]))
  end

  test "Ruby blocks, interpolation, and escaped quotes" do
    grammar = <<~'YACC'
      %token NUMBER
      %%
      start: NUMBER { $$ = [1, 2].map { |n| n * $1 }; @text = "quote: \" }"; $$ = "#{$$} #$1" };
    YACC
    assert_equal("[3, 6] 3", compile(grammar).new.parse([[:NUMBER, 3]]))
  end

  test "standard parameterized rules" do
    grammar = "%token NUMBER\n%%\nstart: delimited('(', NUMBER, ')');"
    assert_equal(7, compile(grammar).new.parse([["(", nil], [:NUMBER, 7], [")", nil]]))
  end

  test "heredoc and multiline literal whitespace is preserved" do
    grammar = <<~'YACC'
      %%
      start: %empty {
        text = <<TEXT
      literal } $missing
      TEXT
        $$ = text + "one
      two"
      };
    YACC
    assert_equal("literal } $missing\none\ntwo", compile(grammar).new.parse([]))
  end

  test "IELR grammar generation" do
    grammar = <<~'YACC'
      %define lr.type ielr
      %%
      start: 'a' first 'd' | 'b' first 'e' | 'a' second 'e' | 'b' second 'd';
      first: 'c';
      second: 'c';
    YACC
    parser = compile(grammar).new
    %w[acd bce ace bcd].each do |input|
      assert_equal(input[0], parser.parse(input.chars.map { |char| [char, char] }))
    end
  end

  test "references around an interpolated heredoc use source order" do
    grammar = <<~'YACC'
      %token NUMBER
      %%
      start: NUMBER {
        $$ = [<<TEXT, $1]
      value: #{$1}
      TEXT
      };
    YACC
    assert_equal(["value: 3\n", 3], compile(grammar).new.parse([[:NUMBER, 3]]))
  end

  test "right associativity and explicit precedence" do
    grammar = <<~'YACC'
      %token NUMBER
      %right '^'
      %precedence NEGATE
      %%
      expr: NUMBER | expr '^' expr { $$ = $1 ** $3 } | '-' expr %prec NEGATE { $$ = -$2 };
    YACC
    parser = compile(grammar).new
    assert_equal(512, parser.parse([[:NUMBER, 2], ["^", nil], [:NUMBER, 3], ["^", nil], [:NUMBER, 2]]))
    assert_equal(4, parser.parse([["-", nil], [:NUMBER, 2], ["^", nil], [:NUMBER, 2]]))
  end

  test "unexpected input and premature EOF raise parse errors" do
    parser_class = compile(CALCULATOR)
    parser = parser_class.new
    [[], [["?", nil]], [[:NUMBER, 1], ["+", nil]], [[:NUMBER, 1], [:NUMBER, 2]], [[-1, nil]]].each do |tokens|
      assert_raise(parser_class::ParseError) { parser.parse(tokens) }
    end
    error = assert_raise(parser_class::ParseError) { parser.parse([[:UNKNOWN, 1]]) }
    assert_equal(:UNKNOWN, error.token)
  end

  test "nonassociative conflicts are syntax errors" do
    grammar = "%token NUMBER\n%nonassoc '<'\n%%\nexpr: NUMBER | expr '<' expr { $$ = $1 < $3 };"
    parser_class = compile(grammar)
    assert_equal(true, parser_class.new.parse([[:NUMBER, 1], ["<", nil], [:NUMBER, 2]]))
    assert_raise(parser_class::ParseError) do
      parser_class.new.parse([[:NUMBER, 1], ["<", nil], [:NUMBER, 2], ["<", nil], [:NUMBER, 3]])
    end
  end

  test "token and action exceptions are propagated" do
    parser = compile("%token NUMBER\n%%\nstart: NUMBER { raise 'action failure' };").new
    assert_equal("action failure", assert_raise(RuntimeError) { parser.parse([[:NUMBER, 1]]) }.message)
    input = Enumerator.new { raise "lexer failure" }
    assert_equal("lexer failure", assert_raise(RuntimeError) { parser.parse(input) }.message)
    assert_raise(ArgumentError) { parser.parse([:NUMBER]) }
  end

  test "unsupported features and invalid actions fail at generation" do
    ["%locations\n%%\nstart: %empty;", "%%\nstart: error;", "%%\nstart: %empty { $$ = };",
     "%union { int value; }\n%%\nstart: %empty;", "%%\nstart: %empty { $$ = $0 };"].each do |grammar|
      assert_raise(Lrama::Ruby::Error) { compile(grammar) }
    end
    assert_raise(Lrama::Ruby::Error) { Lrama::Ruby.generate(CALCULATOR, class_name: "Bad; code") }
  end

  test "unresolved conflicts require an explicit expectation" do
    grammar = "%token NUMBER\n%%\nexpr: NUMBER | expr '+' expr;"
    assert_raise(Lrama::Ruby::Error) { compile(grammar) }
    assert_equal(1, compile("%expect 1\n" + grammar).new.parse([[:NUMBER, 1]]))
  end

  test "generating and compiling do not change the main box" do
    lexer_method = Lrama::Lexer.instance_method(:lex_c_code)
    reference_method = Lrama::Lexer::Token::UserCode.instance_method(:references)
    first = compile("%%\nstart: %empty { $$ = 1 };", class_name: "IsolatedParser")
    second = compile("%%\nstart: %empty { $$ = 2 };", class_name: "IsolatedParser")
    assert_equal(1, first.new.parse([]))
    assert_equal(2, second.new.parse([]))
    assert_false(Object.const_defined?(:IsolatedParser))
    assert_equal(lexer_method, Lrama::Lexer.instance_method(:lex_c_code))
    assert_equal(reference_method, Lrama::Lexer::Token::UserCode.instance_method(:references))
    assert_false(Lrama::Lexer.ancestors.any? { |ancestor| ancestor.name == "Lrama::Ruby::ActionLexer" })
  end

  test "generated file runs without gems or Ruby Box" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "calculator.rb")
      File.write(path, Lrama::Ruby.generate(CALCULATOR, class_name: "Calculator"))
      stdout, stderr, status = Open3.capture3({ "RUBY_BOX" => nil }, RbConfig.ruby,
        "--disable-gems", "-r", path, "-e", 'p Calculator.new.parse([[:NUMBER, 42]])')
      assert_predicate(status, :success?, stderr)
      assert_equal("42\n", stdout)
    end
  end

  test "generation explains when Ruby Box is disabled" do
    _stdout, stderr, status = Open3.capture3({ "RUBY_BOX" => nil }, RbConfig.ruby,
      "-Ilib", "-rlrama/ruby", "-e", 'Lrama::Ruby.generate("%%\nstart: %empty;")')
    assert_false(status.success?)
    assert_include(stderr, "Start Ruby with RUBY_BOX=1")
  end

  test "recognizer accepts C actions and omits C support code" do
    grammar = <<~'YACC'
      %{
      #include "parser.h"
      %}
      %locations
      %union { int value; }
      %token <value> NUMBER
      %type <value> start
      %parse-param {struct parser *p}
      %lex-param {struct parser *p}
      %initial-action { initialize(p); }
      %destructor { release($$); } <value>
      %%
      start: NUMBER { if (p->ctxt.in_def) { warn(p); } /* C action */ $$ = $1; }
           | '(' { enter(p); } NUMBER ')' { $$ = $3; }
           | error { recover(p); }
           ;
      %%
      void helper(void) { abort(); }
    YACC
    code = Lrama::Ruby.generate(grammar, mode: :recognizer)
    assert_not_include(code, "initialize(p)")
    assert_not_include(code, "p->ctxt")
    assert_not_include(code, "void helper")
    parser_class = compile(grammar, mode: :recognizer)
    assert_equal(true, parser_class.new.parse([[:NUMBER, 5]]))
    assert_equal(true, parser_class.new.parse([["(", nil], [:NUMBER, 5], [")", nil]]))
    assert_raise(parser_class::ParseError) { parser_class.new.parse([]) }
    assert_raise(parser_class::ParseError) { parser_class.new.parse([[:UNKNOWN, nil]]) }
    assert_raise(Lrama::Ruby::Error) { compile("%locations\n%%\nstart: %empty;") }
  end

  test "recognizer mode does not leak into later Ruby action generation" do
    generator = Lrama::Ruby::Generator.new
    c_grammar = "%%\nstart: %empty { call_c_function(); };"
    ruby_grammar = '%%' + "\nstart: %empty { $$ = /}/.match?(\"}\") };"
    generator.generate(c_grammar, mode: :recognizer)
    code = generator.generate(ruby_grammar)
    box = Ruby::Box.new
    box.eval(code)
    assert_equal(true, box.const_get(:Parser).new.parse([]))
    generator.generate(c_grammar, mode: :recognizer)
    assert_raise(Lrama::Ruby::Error) { generator.generate(c_grammar, mode: :unknown) }
  end

  test "recognizer still rejects unresolved conflicts" do
    grammar = "%token NUMBER\n%%\nexpr: NUMBER | expr '+' expr;"
    assert_raise(Lrama::Ruby::Error) { compile(grammar, mode: :recognizer) }
  end

  private

  def compile(grammar, **options)
    Lrama::Ruby.compile(grammar, **options)
  end
end

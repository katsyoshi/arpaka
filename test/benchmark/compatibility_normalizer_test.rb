# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"
require_relative "../../benchmark/compatibility/normalizer"

class CompatibilityNormalizerTest < Test::Unit::TestCase
  def setup
    @normalizer = Compatibility::Normalizer.new
  end

  test "basic array and local syntax has one shared representation" do
    source = "values = [1, 2]; values"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)))
  end

  test "basic expression families compare across both AST shapes" do
    ["{name: 1, count: 2}", "x && y", "x and y", "x || y", "x or y", "!flag", "1..3", "ready ? value : fallback",
      "if ready; value; else; fallback; end", "def value; 1; end", "object&.fetch(1)",
      "A::B", "::A", "A::B::C", "::A::B", "def self.value; 1; end",
      "-1", "-0.0", "+1", "block_given?", "value.empty?", "update!"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "unverified VM nodes normalize for unary operators, rational values, and regexp match" do
    ["~value", "1.25r", "/value/ =~ input"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "regexp matches normalize named captures and dynamic match3" do
    ["/(?<name>a)/ =~ text", %q{text =~ /#{pattern}/}].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "nil VM block children preserve explicit trailing nil statements" do
    source = "def eager_load!; cache; nil; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "array case patterns and rest captures compare across both AST shapes" do
    ["case value; in [a, b]; :pair; end", "case value; in [a, *rest]; :rest; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "pinned case patterns and guards compare across both AST shapes" do
    ["expected = 1; case value; in ^expected; :matched; end",
      "case value; in [a, b] if ready; :matched; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "hash case patterns and multiple in clauses compare across both AST shapes" do
    ["case value; in {key: item}; :matched; end",
      "case value; in {key: item}; :matched; in 2; :other; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "nested array and hash case patterns compare across both AST shapes" do
    ["case value; in [a, {key: b}]; :nested; end",
      "case value; in [[a], {key: [b, *rest]}]; :nested; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "alternative case patterns compare across both AST shapes" do
    source = "case value; in 1 | 2; :matched; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "as and find case patterns compare across both AST shapes" do
    ["case input; in 1 => value; :matched; end", "case input; in [*, 1, *]; :matched; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "required keyword parameters in blocks normalize from dynamic assignments" do
    tree = RubyVM::AbstractSyntaxTree.parse("proc { |required:| required }")
    find_node = lambda do |node, type|
      return node if node.is_a?(RubyVM::AbstractSyntaxTree::Node) && node.type == type
      return unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
      node.children.each do |child|
        found = find_node.call(child, type)
        return found if found
      end
      nil
    end
    keyword_parameters = find_node.call(tree, :KW_ARG)
    assert_equal([:keyword_parameters, [[:required_keyword, @normalizer.send(:symbol, :required)]]],
      @normalizer.send(:rubyvm_keyword_arguments, keyword_parameters))
  end

  test "single binary expression wrappers normalize without flattening sequences" do
    ["call((left + right))", "call((left + right), (other * value))"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end

    multiple_statements = normalized_rubyvm("call(begin; left + right; fallback; end)")
    assert_equal(:sequence, multiple_statements.dig(1, 0, 4, 0, 0))
  end

  test "block pass is distinct from symbol arguments and keeps preceding arguments" do
    ["foo(&:to_s)", "foo(:to_s)", "foo(value, &block)",
      "def f(&); foo(&); end", "def f(&block); foo(&block); end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
    assert_kind_of(GeneratedRubyFrontend::AST::Call,
      GeneratedRubyFrontend.parse("foo(*values, name: 1, &block)").statements.first)
  end

  test "method argument forwarding matches RubyVM retained arguments" do
    ["def transmit(...); end", "def stream_for(args, ...); end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "forwarded call arguments normalize as a RubyVM block pass" do
    ["def transmit(...); target(...); end", "def stream_for(args, ...); target(args, ...); end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "splat arguments, array elements, and assignment values compare across both AST shapes" do
    ["foo(*values)", "foo(1, *values, 2)", "[*values, 1]", "items = [*values, 1]"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "multiple assignment preserves its targets and array value" do
    source = "@address, @mailbox_name = address, to"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "keyword arguments keep a distinct tag from hash literals" do
    keyword_arguments = @normalizer.arpaka(GeneratedRubyFrontend.parse("foo(name: 1)"))
    hash_argument = @normalizer.arpaka(GeneratedRubyFrontend.parse("foo({name: 1})"))
    assert_equal(:keyword_arguments, keyword_arguments.dig(1, 0, 4, 0, 0))
    assert_equal(:hash, hash_argument.dig(1, 0, 4, 0, 0))

    rubyvm_keyword_arguments = normalized_rubyvm("foo(name: 1)")
    rubyvm_hash_argument = normalized_rubyvm("foo({name: 1})")
    assert_equal(:hash, rubyvm_keyword_arguments.dig(1, 0, 4, 0, 0))
    assert_equal(:hash, rubyvm_hash_argument.dig(1, 0, 4, 0, 0))

    explicit_hash = "foo(1, {name: 2})"
    assert_equal(normalized_rubyvm(explicit_hash), @normalizer.arpaka(GeneratedRubyFrontend.parse(explicit_hash)))

    keyword_only = "foo(1, name: 2)"
    refute_equal(normalized_rubyvm(keyword_only), @normalizer.arpaka(GeneratedRubyFrontend.parse(keyword_only)))
  end

  test "variable writes indexes and unless compare across both AST shapes" do
    ["@value = 1", "@@value = 1", "$value = 1", "VALUE = 1",
      "values[0]", "values[0] = 1", "unless ready; value; else; fallback; end",
      "case value; when 1, 2; first; else; other; end", "`command`"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "attribute writes compare across both AST shapes" do
    ["self.value = 1", "object.value = 1", "object::value = 1"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "attribute opassign compares across both AST shapes" do
    ["self.identifiers += values", "object.value ||= fallback", "object.value += 1", "object::value += 1"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "local opassign compares through RubyVM's expanded write form" do
    ["timeout -= 0.1", "pos += 1", "owners |= [owner]"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "index opassign compares across both AST shapes" do
    ["values[index] += 1", "options[:root] ||= fallback", "values[0, 1] |= additions"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "bare association entries inside arrays normalize as a hash" do
    ["[:from, attachments: []]", "[1, foo: 2, bar: 3]", "[[1, 2], data: {foo: \"bar\"}]"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "defined expression grouping matches RubyVM around logical operators" do
    ["defined?(A) && defined?(B)", "defined?(A) && B", "defined?(A && B)", "defined? A && B"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "known callable body losses become mismatches" do
    ["-> { 1 }", "while ready; value; end"].each do |source|
      refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "argumentless control statements normalize their absent value as nil" do
    source = "def f; return; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)

    explicit_nil = "def f; return nil; end"
    assert_equal(normalized_rubyvm(explicit_nil), @normalizer.arpaka(GeneratedRubyFrontend.parse(explicit_nil)), explicit_nil)
  end

  test "return values normalize as control values" do
    ["def f(value); return value; end", "def f; return 1; end", "def f; return 1, 2; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "implicit and explicit super arguments compare distinctly" do
    source = "class Parent; def implicit; super; end; def explicit; super(); end; def argument; super(1); end; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "multiple assignment matches while rescue ensure keeps its known mismatch" do
    source = "a, b = values"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)

    rescue_source = "begin; dangerous; rescue Error => error; fallback; ensure; cleanup; end"
    refute_equal(normalized_rubyvm(rescue_source), @normalizer.arpaka(GeneratedRubyFrontend.parse(rescue_source)), rescue_source)
  end

  test "rescue modifiers normalize without changing begin rescue forms" do
    modifier = "value rescue fallback"
    assert_equal(normalized_rubyvm(modifier), @normalizer.arpaka(GeneratedRubyFrontend.parse(modifier)), modifier)
    assert_equal(:rescue_modifier, normalized_rubyvm(modifier).dig(1, 0, 0))

    ["begin; value; rescue; fallback; end",
      "begin; value; rescue Error; fallback; else; other; end"].each do |source|
      assert_equal(:rescue, normalized_rubyvm(source).dig(1, 0, 0), source)
    end

    ensure_source = "begin; value; rescue; fallback; ensure; cleanup; end"
    assert_equal(:ensure, normalized_rubyvm(ensure_source).dig(1, 0, 0), ensure_source)
  end

  test "every supported primitive and empty container has a matching form" do
    ["nil", "true", "false", "1", "1.5", "\"text\"", ":symbol", "Foo", "[]", "{}", ""].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "simple, inherited, nested class and module bodies compare" do
    ["class Thing; 1; end", "class Thing < Parent; 1; end",
      "module Thing; 1; end", "module Outer; class Inner; end; end",
      "module M; value = 1; value; end", "class C; value = 1; value; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "singleton class receivers and bodies compare" do
    ["class << self; end", "class << object; def x; end; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "single required block parameters and their local reads compare" do
    ["items.each { |item| item }", "items.each do |item| item end",
      "outer = 1; items.each { |item| outer + item }; outer",
      "items.each { |first, second| [first, second] }",
      "items.each { |first, second, *rest| [first, second, rest] }",
      "items.each { |first, *rest| [first, rest] }", "items.each { |*rest| rest }",
      "items.each { |first, *| first }", "items.each { |(first, second)| [first, second] }",
      "items.each { |(first, second), tail| [first, second, tail] }"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "aliases, undef and expressionless case preserve their AST distinctions" do
    ["alias old_method new_method", "alias $old $new", "undef old_method, new_method",
      "case; when ready then value; else fallback; end", "case nil; when ready then value; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "qualified and absolute declaration paths compare across both AST shapes" do
    ["class Outer::Inner; end", "class ::Thing; end", "class ::Outer::Inner; end",
      "module Outer::Inner; end", "module ::Thing; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "yield defined back references and variable arity logic normalize soundly" do
    ["def f; yield; end", "def f; yield(value); end", "defined?(value)", "defined?(@value)",
      "self", ":self", "self.name", "[self, :self]", "def self.value; self; end",
      "$1", "$&", "$+", "a && b && c && d", "a || b || c || d"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "argument concatenation preserves splat distinctions" do
    ["f(value, *values)", "f(value, *values, tail)", "def f; yield(value, *values); end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
    ["f(*values)", "[*values]", "[*values, 1]", "[*values, *other]"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "normalization makes RubyVM-only constructs verified mismatches when candidate loses structure" do
    [%q{__FILE__}, %q{:"prefix#{value}"}, %q{`prefix#{value}`}].each do |source|
      refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "class and module local scopes remain distinct from outer locals" do
    source = "outer = 1; module M; outer; end"
    refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)))
  end

  test "known information losses remain visible as mismatches" do
    source = File.read(File.expand_path("../../benchmark/fixtures/splat.rb", __dir__))
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), "splat.rb")
  end

  test "regexp options and encodings compare from parser metadata" do
    regexp_i = File.read(File.expand_path("../../benchmark/fixtures/regexp_i.rb", __dir__))
    regexp_m = File.read(File.expand_path("../../benchmark/fixtures/regexp_m.rb", __dir__))
    default_one = File.read(File.expand_path("../../benchmark/fixtures/optional_default_one.rb", __dir__))
    default_two = File.read(File.expand_path("../../benchmark/fixtures/optional_default_two.rb", __dir__))

    rubyvm_i = normalized_rubyvm(regexp_i)[1][0]
    rubyvm_m = normalized_rubyvm(regexp_m)[1][0]
    arpaka_i = @normalizer.arpaka(GeneratedRubyFrontend.parse(regexp_i))[1][0]

    assert_equal(rubyvm_i[1], rubyvm_m[1])
    assert_not_equal(rubyvm_i[2], rubyvm_m[2])
    assert_equal(rubyvm_i, arpaka_i)
    ["/abc/", "/é/", "/abc/u", "/abc/n", "/abc/e", "/abc/s", "%r{abc}im"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
    refute_equal(normalized_rubyvm(default_one), normalized_rubyvm(default_two))
  end

  test "interpolated regexp parts and explicit options survive parser construction" do
    regexp = GeneratedRubyFrontend.parse('%r{prefix#{value}suffix}im').statements.first
    assert_equal(["prefix", GeneratedRubyFrontend::AST::BareCall.new(:value), "suffix"], regexp.value)
    assert_equal(5, regexp.options)
    assert_nil(regexp.encoding)
    rubyvm = normalized_rubyvm('%r{prefix#{value}suffix}im')[1][0]
    arpaka = @normalizer.arpaka(GeneratedRubyFrontend.parse('%r{prefix#{value}suffix}im'))[1][0]
    assert_equal(rubyvm[1], arpaka[1])
    assert_equal(["unknown", "options"], rubyvm[2])
    assert_equal(["known", 5], arpaka[2])
    refute_equal(normalized_rubyvm('%r{left#{value}}'),
      @normalizer.arpaka(GeneratedRubyFrontend.parse('%r{right#{value}}')))
    unicode = GeneratedRubyFrontend.parse('%r{é#{value}}').statements.first
    assert_equal(Encoding::UTF_8, unicode.value.first.encoding)
  end

  test "absolute constant assignment metadata is left unverified safely" do
    error = assert_raise(Compatibility::Unsupported) { normalized_rubyvm("::Rails = rails_backup") }
    assert_match(/absolute constant assignment metadata/, error.detail)
  end

  test "integer and float values retain distinct exact representations" do
    assert_not_equal(normalized_rubyvm("1"), normalized_rubyvm("1.0"))
    assert_not_equal(normalized_rubyvm("0.0"), normalized_rubyvm("-0.0"))
  end

  test "interpolated percent words compare as dynamic strings and symbols" do
    [%q{%W[pre#{name}post plain]}, %q{%I[pre#{name}post plain]},
      %q{%W[#{name}]}, %q{%I[#{name}]}].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
    assert_equal(normalized_rubyvm(%q{"#{name}"}),
      @normalizer.arpaka(GeneratedRubyFrontend.parse(%q{"#{name}"})))
  end

  test "parameter forms retain post, rest, keyword rest and block fields" do
    rest_only = normalized_rubyvm("def f(*args); end")
    rest_keyword_block = normalized_rubyvm("def f(*args, **kwargs, &block); end")
    required = normalized_rubyvm("def f(first, last); end")
    post = normalized_rubyvm("def f(first, *, last); end")

    assert_not_equal(rest_only, rest_keyword_block)
    assert_not_equal(required, post)
    assert_not_equal(normalized_rubyvm("def f(*rest, first, second); end"),
      normalized_rubyvm("def f(*rest, first, changed); end"))
  end

  test "optional and rest method parameters compare with RubyVM shapes" do
    ["def f(*); end", "def f(*args); end", "def f(first = 1); end",
      "def f(first, second = 1, third = 2); end", "def f(first, *rest, last); end",
      "def f(&); end", "def f(&block); end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "keyword method parameters compare with RubyVM ARGS shapes" do
    ["def f(required:); end", "def f(optional: 1); end", "def f(**kwargs); end",
      "def f(**); end", "def f(required:, optional: 1, **kwargs, &block); end", "def f(**nil); end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "trailing empty begin keeps its nil value" do
    assert_not_equal(normalized_rubyvm("1"), normalized_rubyvm("1; begin; end"))
  end

  test "self and symbol self remain distinct and unknown nested nodes are unverified" do
    self_node = GeneratedRubyFrontend.parse("self").statements.first
    symbol_node = GeneratedRubyFrontend.parse(":self").statements.first
    assert_kind_of(GeneratedRubyFrontend::AST::Self, self_node)
    assert_equal(GeneratedRubyFrontend::AST::Literal.new(:self), symbol_node)
    assert_not_equal(@normalizer.arpaka(self_node), @normalizer.arpaka(symbol_node))
    unknown = Class.new(Data.define(:value)).new(1)
    tree = GeneratedRubyFrontend::AST::Program.new([GeneratedRubyFrontend::AST::ArrayLiteral.new([unknown])])
    error = assert_raise(Compatibility::Unsupported) { @normalizer.arpaka(tree) }
    assert_match(/node/, error.detail)
  end

  private

  def normalized_rubyvm(source)
    body = RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2)
    return [:sequence, []] if body.nil?
    value = @normalizer.rubyvm(body)
    value.is_a?(Array) && value.first == :sequence ? value : [:sequence, [value]]
  end
end

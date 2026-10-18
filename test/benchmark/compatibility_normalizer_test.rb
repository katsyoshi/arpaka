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
      "-1", "-0.0", "+1"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "keyword argument AST nodes compare as RubyVM hash arguments" do
    ["foo(name: 1)", "foo({name: 1})", "foo(0, first: 1, second: 2)",
      "object.foo(name: 1)", "foo name: 1"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "variable writes indexes and unless compare across both AST shapes" do
    ["@value = 1", "@@value = 1", "$value = 1", "VALUE = 1",
      "values[0]", "values[0] = 1", "unless ready; value; else; fallback; end",
      "case value; when 1, 2; first; else; other; end", "`command`"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "known assignment and callable body losses become mismatches" do
    ["object.value = 1", "-> { 1 }",
      "while ready; value; end", "return 1"].each do |source|
      refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "implicit and explicit super arguments compare distinctly" do
    source = "class Parent; def implicit; super; end; def explicit; super(); end; def argument; super(1); end; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "block pass keyword parameters ensure rescue and multiple assignment retain reference structure" do
    ["foo(&block)", "def f(required:, optional: 1); end", "a, b = values",
      "begin; dangerous; rescue Error => error; fallback; ensure; cleanup; end"].each do |source|
      rubyvm = normalized_rubyvm(source)
      arpaka = @normalizer.arpaka(GeneratedRubyFrontend.parse(source))
      refute_equal(rubyvm, arpaka, source)
    end
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
    source = "f(*values)"
    refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "normalization makes RubyVM-only constructs verified mismatches when candidate loses structure" do
    [%q{values[index] += 1}, %q{object.value += 1}, %q{__FILE__}, %q{:"prefix#{value}"}, %q{`prefix#{value}`}].each do |source|
      refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "class and module local scopes remain distinct from outer locals" do
    source = "outer = 1; module M; outer; end"
    refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)))
  end

  test "known information losses remain visible as mismatches" do
    %w[splat.rb optional_default_one.rb method_local_scope.rb required_argument_scope.rb].each do |fixture|
      source = File.read(File.expand_path("../../benchmark/fixtures/#{fixture}", __dir__))
      refute_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), fixture)
    end
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

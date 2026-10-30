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
      "if ready; value; else; fallback; end", "def value; 1; end", "def value(x) = x", "def self.value = 1", "object&.fetch(1)",
      "A::B", "::A", "A::B::C", "::A::B", "def self.value; 1; end",
      "-1", "-0.0", "+1", "block_given?", "value.empty?", "update!"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "defined predicates remain the condition of following ternaries" do
    ["defined?(Rails.root) ? Rails.root : \"/tmp/mails\"",
      "defined?(Nokogiri::HTML5) ? Nokogiri::HTML5::Document : Nokogiri::HTML4::Document"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
    source = "defined?(A ? B : C)"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "single constant paths are accepted as case patterns" do
    source = "case value; when A::B; value; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "rescue variables and backreference assignments normalize from variables" do
    ["begin; work; rescue => error; error; end", "begin; work; rescue => @error; @error; end"].each do |rescue_source|
      assert_equal(normalized_rubyvm(rescue_source), @normalizer.arpaka(GeneratedRubyFrontend.parse(rescue_source)), rescue_source)
    end

    backref_source = "$0 = value"
    assert_equal(normalized_rubyvm(backref_source), @normalizer.arpaka(GeneratedRubyFrontend.parse(backref_source)), backref_source)
  end

  test "break and next command arguments are control nodes" do
    ["items.each { |item| next item }", "items.each { |item| break item }"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "range endpoints preserve implicit nil literals" do
    ["1..", "..1", "1...", "...1", "nil..", "..nil"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "unverified VM nodes normalize for unary operators, rational values, and regexp match" do
    ["~value", "1.25r", "/value/ =~ input"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "regexp delimiter escapes normalize to the RubyVM pattern" do
    ["/\\.\\/consumer/", "/\\//"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "regexp matches normalize named captures and dynamic match3" do
    ["/(?<name>a)/ =~ text", "text =~ /pattern/", "text =~ other", %q{text =~ /#{pattern}/}].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "escaped interpolation in heredocs remains a string" do
    source = <<~'RUBY'
      value = <<-CODE
      \#{value}
      CODE
    RUBY
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "operator method names preserve binary and unary forms" do
    ["def +(other); other; end", "def -(other); other; end",
      "def +@(other); other; end", "def -@(other); other; end",
      "alias + -", "alias +@ -@"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "operator symbols preserve binary names" do
    ["alias_method :+, :plus_with_duration", "alias_method :-, :minus_with_duration"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "complex, imaginary, and symbol array literals compare across both AST shapes" do
    ["1i", "1 + 2i", "1.5 + 2i", "[:a, :b]", "%i[a b]"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "nil VM block children preserve explicit trailing nil statements" do
    source = "def eager_load!; cache; nil; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "a method body containing only nil normalizes as empty" do
    ["def value; nil; end", "def self.value; nil; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "terminal nil branches in method bodies normalize as empty" do
    ["def value; ready ? result : nil; end", "def value; ready ? nil : result; end",
      "def self.value; ready ? result : nil; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
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

  test "qualified hash patterns compare across both AST shapes" do
    ["case input; in Integer[key: value]; :matched; end",
      "case input; in Integer(key: value); :matched; end"].each do |source|
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

  test "single expression wrappers normalize without flattening sequences" do
    ["call((left + right))", "call((ready ? value : fallback))", "call((1..3))", "call((!ready))"].each do |source|
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

  test "implicit numbered block parameters become local reads" do
    ["events.find { _1.payload[:sql] == \"SELECT * FROM posts\" }",
      "items.map { _2.to_s }"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
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

  test "anonymous keyword rest parameters are local reads when forwarded" do
    source = "def render(**); target(**); end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "named regexp captures are local reads in their scope" do
    source = "/(?<size>tiny)/ =~ value; size"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
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

  test "multiple assignment preserves field and index setter targets" do
    [
      "object.value, options[:key] = values",
      "options[:key], object.value = values"
    ].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "constant and nested multiple assignment targets compare across both AST shapes" do
    ["A, B = values", "a, (b, c) = values"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "bare symbol assignment targets normalize as local targets" do
    assert_equal([:local_target, [:symbol, [:bytes, "666f6f", "US-ASCII"]]], @normalizer.send(:rubyvm_target, :foo))
  end

  test "postarg multiple assignment preserves rest and post targets" do
    source = "before, *middle, after = values"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "keyword arguments use the same hash representation as RubyVM" do
    keyword_arguments = @normalizer.arpaka(GeneratedRubyFrontend.parse("foo(name: 1)"))
    hash_argument = @normalizer.arpaka(GeneratedRubyFrontend.parse("foo({name: 1})"))
    assert_equal(:hash, keyword_arguments.dig(1, 0, 4, 0, 0))
    assert_equal(:hash, hash_argument.dig(1, 0, 4, 0, 0))

    rubyvm_keyword_arguments = normalized_rubyvm("foo(name: 1)")
    rubyvm_hash_argument = normalized_rubyvm("foo({name: 1})")
    assert_equal(:hash, rubyvm_keyword_arguments.dig(1, 0, 4, 0, 0))
    assert_equal(:hash, rubyvm_hash_argument.dig(1, 0, 4, 0, 0))

    explicit_hash = "foo(1, {name: 2})"
    assert_equal(normalized_rubyvm(explicit_hash), @normalizer.arpaka(GeneratedRubyFrontend.parse(explicit_hash)))

    keyword_only = "foo(1, name: 2)"
    assert_equal(normalized_rubyvm(keyword_only), @normalizer.arpaka(GeneratedRubyFrontend.parse(keyword_only)))
  end

  test "keyword splats and implicit keyword values use hash pairs" do
    ["foo(**kw)", "foo(**{name: 1})", "foo(name: 1, **kw)",
      "foo({name: 1}, **kw)", "{**kw}", "foo(name:)", "foo(**nil)"].each do |source|
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

  test "multiple ordinary case clauses compare across both AST shapes" do
    source = "case value; when 1; first; when 2; second; else; other; end"

    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)))
  end

  test "receiver fields, safe navigation, and nested indexes compare across both AST shapes" do
    ["object.value", "object&.value", "object[0]", "object&.[](0)",
      "object.value[0]", "object[0].value", "object[0][1]",
      "object.value = value", "object[0] = value", "object.value += value",
      "object[0] += value", "object.value[0] = value", "object[0].value = value",
      "object[0][1] = value"].each do |source|
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
    ["timeout -= 0.1", "pos += 1", "owners |= [owner]",
      "owners ||= []", "owners &&= fallback"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "assignment targets and scoped local reads keep their distinct shapes" do
    [
      "value = 1",
      "first, second = values",
      "first, *middle, last = values",
      "def read(value); value = 1; value; end",
      "items.each { |item| item = value; item }"
    ].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "variable opassign targets compare as reads" do
    ["@value ||= 1", "@@value &&= fallback", "$value += 1"].each do |source|
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

  test "loop execution mode is normalized without changing the loop AST" do
    ["while ready; value; end", "value while ready", "until ready; value; end", "value until ready",
      "begin; value; end while ready", "begin; value; end until ready"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "callable bodies compare with RubyVM" do
    source = "-> { 1 }"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
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

  test "super binary operators preserve Ruby's whitespace-sensitive parsing" do
    ["+", "-", "*", "/"].each do |operator|
      source = "def value; super #{operator} 2; end"
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end

    ["def value; super +2; end", "def value; super *2; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "multiple assignment and rescue ensure compare equally" do
    source = "a, b = values"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)

    rescue_source = "begin; dangerous; rescue Error => error; fallback; ensure; cleanup; end"
    assert_equal(normalized_rubyvm(rescue_source), @normalizer.arpaka(GeneratedRubyFrontend.parse(rescue_source)), rescue_source)
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
    assert_equal(normalized_rubyvm(ensure_source), @normalizer.arpaka(GeneratedRubyFrontend.parse(ensure_source)), ensure_source)

    ensure_only_source = "begin; value; ensure; cleanup; end"
    assert_equal(normalized_rubyvm(ensure_only_source),
      @normalizer.arpaka(GeneratedRubyFrontend.parse(ensure_only_source)), ensure_only_source)
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
      "items.each { |(first, second), (third, fourth)| [first, second, third, fourth] }",
      "items.each { |first, second, *rest| [first, second, rest] }",
      "items.each { |first, *rest| [first, rest] }", "items.each { |*rest| rest }",
      "items.each { |first, *| first }", "items.each { |(first, second)| [first, second] }",
      "items.each { |(first, second), tail| [first, second, tail] }"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "nested destructured block parameters preserve their target shape" do
    source = "items.each { |(first, (second, third))| [first, second, third] }"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "block local variables compare separately from block parameters" do
    tree = GeneratedRubyFrontend.parse("items.each { |item; local| local }")
    parameters = tree.statements.first.parameters
    assert_equal(:required, parameters.kind)
    locals = parameters.value.last
    assert_equal(:locals, locals.kind)
    assert_equal([:local], locals.value)
  end

  test "block-only parameters compare as block parameters" do
    source = "items.each { |&block| block.call }"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "block optional, rest, and block parameters retain their argument shape" do
    [
      "items.each { |item = nil| item }",
      "items.each { |item, *rest| [item, rest] }",
      "items.each { |item = nil, &block| block || item }"
    ].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "command blocks stay attached after compound command arguments" do
    ["foo bar, baz do |value| value end",
      "foo bar, baz do |value| value; value end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "command blocks stay attached after nested parenthesized arguments" do
    ["travel_to Time.new(2004, 11, 24, 1, 4, 44) do; work; end",
      "foo bar() do; work; end"].each do |source|
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

  test "__FILE__ preserves the RubyVM file literal representation" do
    source = "__FILE__"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
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
    assert_equal(["unknown", "options"], arpaka[2])
    refute_equal(normalized_rubyvm('%r{left#{value}}'),
      @normalizer.arpaka(GeneratedRubyFrontend.parse('%r{right#{value}}')))
    unicode = GeneratedRubyFrontend.parse('%r{é#{value}}').statements.first
    assert_equal(Encoding::UTF_8, unicode.value.first.encoding)
  end

  test "regexp once modifier and for loop scopes normalize like RubyVM" do
    [%q{/#{value}/o}, %q{/#{value}/}].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
    assert_equal(true, GeneratedRubyFrontend.parse(%q{/#{value}/o}).statements.first.once)
    assert_equal(false, GeneratedRubyFrontend.parse(%q{/#{value}/}).statements.first.once)

    explicit = GeneratedRubyFrontend.parse('%r{prefix#{value}suffix}imo').statements.first
    assert_equal(5, explicit.options)
    assert_equal(true, explicit.once)

    source = "for item in items; :done; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "END blocks normalize like RubyVM POSTEXE nodes" do
    source = "END { puts :done }"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "absolute constant assignments normalize through their COLON3 wrapper" do
    source = "::Rails = rails_backup"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
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
      "def f(first, second = 1, third = 2); end", "def f(first, second = 1, third); end",
      "def f(first, *rest, last); end",
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

  test "encoding literals compare with RubyVM ENCODING nodes" do
    source = "__ENCODING__"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)))
  end

  test "line and encoding literals compare with magic comments" do
    ["# encoding: ISO-8859-1\n__LINE__\n__ENCODING__",
      "#!/usr/bin/env ruby\n# coding: US-ASCII\n__LINE__\n__ENCODING__",
      "# -*- coding: UTF-8 -*-\n__LINE__\n__ENCODING__"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "line literals in heredoc suffixes keep the source line" do
    source = "class_eval <<-RUBY, __FILE__, __LINE__ + 1\n  def generated; end\nRUBY\n"

    assert_equal(normalized_rubyvm(source),
      @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "static dynamic symbols compare with symbol literals" do
    assert_equal(normalized_rubyvm("%I[static].first"),
      @normalizer.arpaka(GeneratedRubyFrontend.parse("%I[static].first")))
  end

  test "static dynamic xstrings compare with xstrings" do
    source = "%x[printf static]"
    assert_equal(normalized_rubyvm(source),
      @normalizer.arpaka(GeneratedRubyFrontend.parse(source)))
  end

  test "interpolated symbols and xstrings compare with dynamic RubyVM nodes" do
    [
      %q{:"pre#{name}post"},
      %q{`printf #{name}`},
      %q{%x[printf #{name}]}
    ].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "command blocks bind outside receiver and binary arguments" do
    ["travel_to Time.now + 3.seconds do; 1; end", "f foo.bar do; 1; end",
      "f foo + bar do; 1; end", "(1..n).each do; 1; end"].each do |source|
      assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
    end
  end

  test "command blocks bind outside comma-separated arguments" do
    source = "ActiveSupport::Notifications.instrument \"event\", payload do; work; end"
    assert_equal(normalized_rubyvm(source), @normalizer.arpaka(GeneratedRubyFrontend.parse(source)), source)
  end

  test "string literal nodes compare with strings" do
    node = GeneratedRubyFrontend::AST::Literal.new("static")
    assert_equal([:string, [:bytes, "737461746963", "UTF-8"]], @normalizer.arpaka(node))
  end

  private

  def normalized_rubyvm(source)
    body = RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2)
    return [:sequence, []] if body.nil?
    value = @normalizer.rubyvm(body)
    value.is_a?(Array) && value.first == :sequence ? value : [:sequence, [value]]
  end
end

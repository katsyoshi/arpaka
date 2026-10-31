# frozen_string_literal: true

require "json"
require "tmpdir"

require_relative "test_helper"
require_relative "generated_frontend_helper"
require_relative "../benchmark/compatibility"

class BenchmarkCompatibilityTest < Test::Unit::TestCase
  def test_normalizes_legacy_block_call_shape
    block_call = lambda do |members, values|
      klass = Class.new do
        define_singleton_method(:name) { "AST::BlockCall" }
        define_method(:members) { members }
        values.each { |name, value| define_method(name) { value } }
      end
      klass.new
    end
    parameters = Class.new do
      define_singleton_method(:name) { "AST::BlockParameters" }
      define_method(:members) { [:kind, :value] }
      define_method(:kind) { :none }
      define_method(:value) { nil }
    end.new

    normalizer = Compatibility::Normalizer.new
    legacy = block_call.call([:call, :body], call: nil, body: [])
    current = block_call.call([:call, :parameters, :body], call: nil, parameters: parameters, body: [])

    assert_equal normalizer.arpaka(current), normalizer.arpaka(legacy)
  end

  def test_normalizes_control_without_optional_value_field
    node = Class.new do
      define_singleton_method(:name) { "AST::Control" }
      define_method(:members) { [:kind] }
      define_method(:kind) { :break }
    end.new

    assert_equal [:control, [:symbol, [:bytes, "627265616b", "US-ASCII"]], nil],
      Compatibility::Normalizer.new.arpaka(node)
  end

  def test_normalizes_control_with_value_field
    node = Class.new do
      define_singleton_method(:name) { "AST::Control" }
      define_method(:members) { [:kind, :value] }
      define_method(:kind) { :return }
      define_method(:value) { nil }
    end.new

    assert_equal [:control, [:symbol, [:bytes, "72657475726e", "US-ASCII"]], nil],
      Compatibility::Normalizer.new.arpaka(node)
  end

  def test_preserves_block_and_method_argument_shapes
    normalizer = Compatibility::Normalizer.new
    [
      "def f(*args, **keywords, &block); end",
      "def f(required:, optional: 1); end",
      "items.each { |first, *rest, last| [first, rest, last] }",
      "items.each { |first:, **keywords, &block| [first, keywords, block] }"
    ].each do |source|
      rubyvm = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false).children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal rubyvm, arpaka, source
    end
  end

  def test_preserves_super_call_forms
    normalizer = Compatibility::Normalizer.new
    [
      "def f; super; end",
      "def f; super(); end",
      "def f; super(1, *args, **keywords, &block); end",
      "def f; super { |value| value }; end"
    ].each do |source|
      rubyvm = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false).children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1)
      assert_equal [rubyvm], arpaka, source
    end
  end

  def test_does_not_normalize_a_call_to_a_symbol_literal
    runner = compatibility_runner
    call = [:call, nil, false, [:symbol, [:bytes, "6d6574686f64", "US-ASCII"]], []]
    symbol = [:symbol, [:bytes, "6d6574686f64", "US-ASCII"]]

    assert_equal [:mismatch, nil], runner.__send__(:compare_trees, call, symbol)
    assert_equal [:mismatch, nil], runner.__send__(:compare_trees, symbol, call)
  end

  def test_normalizes_legacy_regexp_literal_shape
    node = Class.new do
      define_singleton_method(:name) { "AST::RegexpLiteral" }
      define_method(:members) { [:value] }
      define_method(:value) { "foo" }
    end.new

    assert_equal [:regexp, "666f6f", 0, "UTF-8"],
      Compatibility::Normalizer.new.arpaka(node)
  end

  def test_normalizes_qualified_declaration_names_like_arpaka
    tree = RubyVM::AbstractSyntaxTree.parse("class ActionCable::Loader; end", keep_script_lines: false)
    normalized = Compatibility::Normalizer.new.rubyvm(tree.children.fetch(2))

    assert_equal :constant, normalized.fetch(1).fetch(0)
    assert_equal [:symbol, [:bytes, "4c6f61646572", "US-ASCII"]], normalized.fetch(1).fetch(1)
  end

  def test_normalizes_qualified_expression_names_like_arpaka
    tree = RubyVM::AbstractSyntaxTree.parse("ActionCable::Server::Base", keep_script_lines: false)
    normalized = Compatibility::Normalizer.new.rubyvm(tree.children.fetch(2))

    assert_equal [:constant, [:symbol, [:bytes, "42617365", "US-ASCII"]]], normalized
  end

  def test_compares_final_constant_of_qualified_path_with_constant
    runner = compatibility_runner
    constant = [:constant, [:symbol, [:bytes, "42617365", "US-ASCII"]]]
    qualified = [:constant_path,
      [:constant, [:symbol, [:bytes, "416374696f6e4361626c65", "US-ASCII"]]],
      constant.fetch(1)]

    assert_equal [:match, nil], runner.__send__(:compare_trees, constant, qualified)
    assert_equal [:match, nil], runner.__send__(:compare_trees, qualified, constant)
  end

  def test_compares_constant_path_after_json_boundary
    runner = compatibility_runner
    rubyvm = [:constant, [:symbol, [:bytes, "4c6f61646572", "US-ASCII"]]]
    arpaka = ["constant_path", ["constant", ["symbol", ["bytes", "416374696f6e4361626c65", "US-ASCII"]]],
      ["symbol", ["bytes", "4c6f61646572", "US-ASCII"]]]

    assert_equal [:match, nil], runner.__send__(:compare_trees, rubyvm, arpaka)
    assert_equal [:match, nil], runner.__send__(:compare_trees, arpaka, rubyvm)
  end

  def test_compares_nested_qualified_paths_by_their_receivers
    runner = compatibility_runner
    base = [:constant, [:symbol, [:bytes, "416374696f6e4361626c65", "US-ASCII"]]]
    server = [:constant_path, base, [:symbol, [:bytes, "536572766572", "US-ASCII"]]]
    nested = [:constant_path, server, [:symbol, [:bytes, "42617365", "US-ASCII"]]]
    other = [:constant_path, base, [:symbol, [:bytes, "4f74686572", "US-ASCII"]]]

    assert_equal [:mismatch, nil], runner.__send__(:compare_trees, nested, other)
  end

  def test_preserves_qualified_constant_write_receivers
    normalizer = Compatibility::Normalizer.new
    ["A::B = 1", "A::B::C = 1", "::A::B = 1"].each do |source|
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      rubyvm = normalizer.rubyvm(tree.children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)

      assert_equal arpaka, rubyvm, source
    end
  end

  def test_preserves_operator_assignment_variable_kinds
    normalizer = Compatibility::Normalizer.new
    ["@value += 1", "@@value += 1", "$value += 1", "Value += 1",
      "@value ||= 1", "@@value ||= 1", "$value ||= 1", "Value ||= 1"].each do |source|
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      rubyvm = normalizer.rubyvm(tree.children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)

      assert_equal rubyvm, arpaka, source
    end
  end

  def test_does_not_flatten_nested_qualified_path_to_constant
    runner = compatibility_runner
    base = [:constant, [:symbol, [:bytes, "416374696f6e4361626c65", "US-ASCII"]]]
    nested = [:constant_path,
      [:constant_path, base, [:symbol, [:bytes, "536572766572", "US-ASCII"]]],
      [:symbol, [:bytes, "42617365", "US-ASCII"]]]
    constant = [:constant, [:symbol, [:bytes, "42617365", "US-ASCII"]]]

    assert_equal [:mismatch, nil], runner.__send__(:compare_trees, nested, constant)
    assert_equal [:mismatch, nil], runner.__send__(:compare_trees, constant, nested)
  end

  def test_accepts_rubyvm_single_pair_hash_for_a_bare_keyword_argument
    runner = compatibility_runner
    pair = [:pair, [:symbol, [:bytes, "6e616d65", "US-ASCII"]], [:integer, 1]]
    hash = [:hash, [pair]]

    assert_equal [:accepted_mismatch, "$"],
      runner.__send__(:compare_trees,
        [:call, nil, false, [:symbol, [:bytes, "666f6f", "US-ASCII"]], [hash]],
        [:call, nil, false, [:symbol, [:bytes, "666f6f", "US-ASCII"]], [pair]])
  end

  def test_does_not_treat_an_explicit_hash_literal_as_a_pair_argument
    runner = compatibility_runner
    pair = [:pair, [:symbol, [:bytes, "6e616d65", "US-ASCII"]], [:integer, 1]]
    hash = [:hash, [pair]]

    assert_equal [:mismatch, nil], runner.__send__(:compare_trees, hash, pair)
  end

  def compatibility_runner
    Compatibility::Runner.new(ruby_source: nil, corpora: [["test", __FILE__]], frontend: __FILE__)
  end

  def test_ractor_checks_fixture_with_pre_generated_frontend
    ruby_source = File.expand_path("../vendor/ruby", __dir__)
    Dir.mktmpdir("compatibility-test-") do |directory|
      frontend = File.join(directory, "frontend.rb")
      reference = File.join(directory, "reference.jsonl")
      source_file = File.expand_path("../benchmark/fixtures/basic_match.rb", __dir__)

      File.write(frontend, Arpaka.generate(ruby_source: ruby_source, class_name: "CompatibilityFrontend"))
      source = File.binread(source_file).force_encoding(Encoding::UTF_8)
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      normalized = Compatibility::Normalizer.new.rubyvm(tree.children.fetch(2))
      normalized = [:sequence, normalized.nil? ? [] : [normalized]] unless normalized.is_a?(Array) && normalized.first == :sequence
      File.write(reference, JSON.generate(
        "type" => "reference", "corpus" => "fixture", "path" => "basic_match.rb",
        "sha256" => Digest::SHA256.hexdigest(source), "status" => "ok",
        "elapsed_seconds" => 0.0, "tree" => normalized
      ) + "\n")

      results, = Compatibility::Runner.new(
        ruby_source: ruby_source,
        corpora: [["fixture", source_file]],
        frontend: frontend,
        reference_cache: reference,
        parallel: :ractor,
        threads: 1
      ).run

      assert_equal 1, results.length
      assert_not_include %w[parse_failure timeout error], results.first.fetch("status")
      assert_equal "ok", results.first.fetch("outcomes").fetch("arpaka").fetch("status")
    end
  end
end

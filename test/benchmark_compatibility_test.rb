# frozen_string_literal: true

require "json"
require "fileutils"
require "tmpdir"

require_relative "test_helper"
require_relative "generated_frontend_helper"
require_relative "../benchmark/compatibility"

class BenchmarkCompatibilityTest < Test::Unit::TestCase
  def test_source_encoding_comment_applies_to_string_literals
    source = "# encoding: US-ASCII\n[\"abstract_unit\", \"\\xFC\"]"
    normalizer = Compatibility::Normalizer.new
    expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
    actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)

    assert_equal(expected, actual)
  end

  def test_multiple_assignment_preserves_anonymous_rest
    normalizer = Compatibility::Normalizer.new
    ["first, * = values", "first, *, last = values", "* = values", "*, last = values"].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_legacy_octal_integer_literals
    normalizer = Compatibility::Normalizer.new
    ["0132", "0_132", "-077", "[0, 00, 0123, 123, 0.125, 0e2]"].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
    assert_raise(GeneratedRubyFrontend::LexerError) { GeneratedRubyFrontend.parse("019") }
  end

  def test_anonymous_rest_forwarding_preserves_positional_arguments
    normalizer = Compatibility::Normalizer.new
    ["def f(*); g(*); end", "def f(*, **); g(*, **); end", "def f(*); g(1, *); end"].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_multiple_assignment_preserves_named_rest_and_post_targets
    normalizer = Compatibility::Normalizer.new
    ["first, *rest = values", "first, *rest, last = values", "*rest = values", "*rest, last = values"].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_regexp_character_classes_preserve_interpolation
    normalizer = Compatibility::Normalizer.new
    ['/a[#{value}]b/', '/[#{separator}] */n', '/[#{head}]#{tail}/', '/[\#{literal}]/'].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_interpolated_regexp_decodes_slash_delimiter_escapes
    normalizer = Compatibility::Normalizer.new
    [' /a\/#{value}/', '/#{value}\/tail/', '/[\/]#{value}/', '/\\\\\/#{value}/'].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
    regexp = GeneratedRubyFrontend.parse('/a\/#{value}/').statements.first
    assert_equal "a/", regexp.value.first
  end

  def test_repeated_defined_queries_preserve_logical_associativity
    normalizer = Compatibility::Normalizer.new
    [
      "defined?(@a) && @a && defined?(@b) && @b && check",
      "defined?(@a) || @a || defined?(@b) || @b || check",
      "defined?(@a) && (@a && defined?(@b))",
      "defined?(@a && @b) && check"
    ].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_line_numbers_inside_interpolation
    normalizer = Compatibility::Normalizer.new
    ['"#{__LINE__}"', '/#{__LINE__}/', '%W[#{__LINE__}]', '"#{"#{__LINE__}"}"', "\"text\n\#{\n__LINE__}\""].each do |expression|
      source = "\n\n" + expression
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_static_string_interpolations_match_rubyvm
    normalizer = Compatibility::Normalizer.new
    [
      '"foo#{"bar"}"',
      '"#{"foo"}"',
      '"prefix#{"middle"}suffix"'
    ].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_dynamic_string_interpolations_remain_interpolated
    normalizer = Compatibility::Normalizer.new
    [
      '"foo#{value}"',
      '"#{value}bar"'
    ].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_program_name_is_a_global_variable_not_a_regexp_capture
    normalizer = Compatibility::Normalizer.new
    ["$0", "$0 = 'program'", "[$0, $1, $10]"].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

  def test_do_block_binds_to_command_outside_parenthesized_argument
    normalizer = Compatibility::Normalizer.new
    [
      "instrument :retry, options.slice(:error, :wait) do; work; end",
      "Rails.stub :root, Pathname.getwd() do; work; end",
      "test 'example' do; Rails.stub :root, Pathname.getwd do; work; end; end",
      "test 'example' do; Rails.stub :root, Pathname.getwd() do; work; end; end",
      "test 'example' do; outer inner() { work }; end",
      "items.each do; rows.sort_by { |i, _| i }.each do |row|; work; end; end",
      "outer(inner() do; work; end)",
      "outer inner() { work }"
    ].each do |source|
      expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
      actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal expected, actual, source
    end
  end

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

  def test_splat_tail_keeps_positional_and_keyword_arguments_together
    normalizer = Compatibility::Normalizer.new
    source = "tag_string(name, *args, options, escape: escape)"
    expected = normalizer.rubyvm(RubyVM::AbstractSyntaxTree.parse(source).children.fetch(2))
    actual = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)

    assert_equal expected, actual
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

  def test_normalizes_static_regexp_escapes_like_rubyvm
    normalizer = Compatibility::Normalizer.new
    ["%r{\\/}", "%r(foo\\/bar)"].each do |source|
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      assert_equal normalizer.rubyvm(tree.children.fetch(2)),
        normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0), source
    end
  end

  def test_preserves_binary_precedence_after_defined_expression
    normalizer = Compatibility::Normalizer.new
    source = "!defined?(value) || fallback"
    tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)

    assert_equal normalizer.rubyvm(tree.children.fetch(2)),
      normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
  end

  def test_preserves_singleton_method_required_arguments
    normalizer = Compatibility::Normalizer.new
    ["def self.===(other); other; end", "def self.f(a, b); [a, b]; end"].each do |source|
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      rubyvm = normalizer.rubyvm(tree.children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)

      assert_equal rubyvm, arpaka, source
    end
  end

  def test_preserves_repeated_regexp_escape_backslashes
    normalizer = Compatibility::Normalizer.new
    source = "%r{\\\\/}"
    tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)

    assert_equal normalizer.rubyvm(tree.children.fetch(2)),
      normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
  end

  def test_normalizes_static_dregx_as_a_static_regexp
    normalizer = Compatibility::Normalizer.new
    node = RubyVM::AbstractSyntaxTree.parse("/#{'x'}\\//", keep_script_lines: false).children.fetch(2)

    assert_equal [:regexp, "782f", 0, "US-ASCII"], normalizer.rubyvm(node)
  end

  def test_normalizes_static_interpolated_strings_as_strings
    normalizer = Compatibility::Normalizer.new
    source = '"hello"'
    tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
    node = Class.new do
      define_singleton_method(:name) { "AST::InterpolatedString" }
      define_method(:members) { [:parts] }
      define_method(:parts) { ["hello"] }
    end.new

    assert_equal normalizer.rubyvm(tree.children.fetch(2)),
      normalizer.arpaka(node)
    assert_equal [:string, [:bytes, "68656c6c6f", "UTF-8"]],
      normalizer.rubyvm(tree.children.fetch(2))
  end

  def test_normalizes_legacy_splat_array_value_as_an_array
    node = Class.new do
      define_singleton_method(:name) { "AST::Splat" }
      define_method(:members) { [:value] }
      define_method(:value) { [Class.new do
        define_singleton_method(:name) { "AST::Literal" }
        define_method(:members) { [:value] }
        define_method(:value) { 1 }
      end.new] }
    end.new

    assert_equal [:splat, [:array, [[:integer, 1]]]],
      Compatibility::Normalizer.new.arpaka(node)
  end

  def test_normalizes_case_and_rescue_shapes_as_a_single_ast_family
    normalizer = Compatibility::Normalizer.new
    [
      "case value; when Hash; 1; else 2; end",
      "raise FirstError rescue raise SecondError",
      "begin; raise FirstError; rescue SecondError; 1; end"
    ].each do |source|
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      rubyvm = normalizer.rubyvm(tree.children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)
      assert_equal rubyvm, arpaka, source
    end
  end

  def test_does_not_normalize_bare_rescue_as_a_rescue_modifier
    normalizer = Compatibility::Normalizer.new
    [
      "def f; raise FirstError rescue raise SecondError; end",
      "def f\n  raise FirstError\nrescue\n  raise SecondError\nend"
    ].each do |source|
      tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
      rubyvm = normalizer.rubyvm(tree.children.fetch(2))
      arpaka = normalizer.arpaka(GeneratedRubyFrontend.parse(source)).fetch(1).fetch(0)

      assert_equal rubyvm, arpaka, source
    end
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
      source_files = %w[basic_match.rb splat.rb].map do |name|
        File.expand_path("../benchmark/fixtures/#{name}", __dir__)
      end
      corpus = File.join(directory, "corpus")
      FileUtils.mkdir_p(corpus)
      source_files.each { |path| FileUtils.cp(path, corpus) }

      File.write(frontend, Arpaka.generate(ruby_source: ruby_source, class_name: "CompatibilityFrontend"))
      records = source_files.map do |source_file|
        source = File.binread(source_file).force_encoding(Encoding::UTF_8)
        tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
        normalized = Compatibility::Normalizer.new.rubyvm(tree.children.fetch(2))
        normalized = [:sequence, normalized.nil? ? [] : [normalized]] unless normalized.is_a?(Array) && normalized.first == :sequence
        {
          "type" => "reference", "corpus" => "fixture", "path" => File.basename(source_file),
          "sha256" => Digest::SHA256.hexdigest(source), "status" => "ok",
          "elapsed_seconds" => 0.0, "tree" => normalized
        }
      end
      File.write(reference, records.map { |record| JSON.generate(record) }.join("\n") + "\n")

      results, = Compatibility::Runner.new(
        ruby_source: ruby_source,
        corpora: [["fixture", corpus]],
        frontend: frontend,
        reference_cache: reference,
        parallel: :ractor,
        threads: 2
      ).run

      assert_equal source_files.length, results.length
      results.each do |result|
        assert_not_include %w[parse_failure timeout error], result.fetch("status")
        assert_equal "ok", result.fetch("outcomes").fetch("arpaka").fetch("status")
      end
    end
  end

  def test_ractor_frontend_class_rewrite_matches_thread_frontend
    ruby_source = File.expand_path("../vendor/ruby", __dir__)
    source = <<~RUBY
      class ActionCable::Loader
        def initialize(path = "")
          @path = path + "日本語"
        end

        def load
          ActionCable::Server::Base.new(@path)
        end
      end
    RUBY
    Dir.mktmpdir("compatibility-test-") do |directory|
      frontend = File.join(directory, "frontend.rb")
      file = File.join(directory, "loader.rb")
      reference = File.join(directory, "reference.jsonl")
      corpus = File.join(directory, "corpus")
      FileUtils.mkdir_p(corpus)
      generated = File.read(File.expand_path("../lrama_ruby_parser.rb", __dir__))
      File.write(frontend, generated.sub("class LramaRubyParser\n", "class CompatibilityFrontend\n"))
      File.write(file, source)
      FileUtils.cp(file, File.join(corpus, "loader.rb"))
      normalized = Compatibility::Normalizer.new.rubyvm(
        RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false).children.fetch(2))
      normalized = [:sequence, normalized.nil? ? [] : [normalized]] unless normalized.is_a?(Array) && normalized.first == :sequence
      File.write(reference, JSON.generate(
        "type" => "reference", "corpus" => "fixture", "path" => "loader.rb",
        "sha256" => Digest::SHA256.hexdigest(source), "status" => "ok", "tree" => normalized) + "\n")

      results = %i[thread ractor].map do |parallel|
        Compatibility::Runner.new(
          ruby_source: ruby_source, corpora: [["fixture", corpus]], frontend: frontend,
          reference_cache: reference, parallel: parallel, threads: 1).run.first
      end

      assert_equal results.fetch(0).map { |result| result.fetch("status") },
        results.fetch(1).map { |result| result.fetch("status") }
      assert_equal results.fetch(0).first.fetch("outcomes").fetch("arpaka").fetch("status"),
        results.fetch(1).first.fetch("outcomes").fetch("arpaka").fetch("status")
      assert_equal results.fetch(0).first.fetch("difference"), results.fetch(1).first.fetch("difference")
    end
  end
end

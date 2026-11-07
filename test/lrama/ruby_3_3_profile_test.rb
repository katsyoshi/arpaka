# frozen_string_literal: true

require "test_helper"
require "erb"

class Ruby33ProfileTest < Test::Unit::TestCase
  PROFILE = Arpaka::Ruby::Profile.send(:load, "profiles/ruby_3_3.rb", "ruby-3.3")
  UNSUPPORTED_RULES = {
    29 => ["stmt: \"`alias'\" \"global variable\" \"numbered reference\"", 2385],
    53 => ["command_asgn: backref \"operator-assignment\" lex_ctxt command_rhs", 2592],
    229 => ["arg: backref \"operator-assignment\" lex_ctxt arg_rhs", 3323]
  }.freeze

  test "records the stable Ruby 3.3 source profile" do
    assert_equal("v3_3_10", PROFILE.fetch("source_tag"))
    assert_equal("343ea050023cfc0374fdea6fdf625b2f57b716a4", PROFILE.fetch("source_revision"))
    assert_equal("0347b145280f89b0052aaaa506aa2022c9abdfa2c37677203d53a1a2b3e35861",
      PROFILE.fetch("source_sha256"))
  end

  test "classifies every Ruby 3.3 production" do
    actions = PROFILE.fetch("actions")

    assert_false(actions.empty?)
    assert_equal((1..782).to_a, actions.keys.sort)
    assert_false(actions.values.any? { |classification, _| classification == "pass_through" })
    assert_equal([29, 53, 229], actions.filter_map do |id, (classification, _)|
      id if classification == "unsupported"
    end)
    assert_include(actions.values.map(&:last), "@builder.body_nodes($1)")
    assert_include(actions.values.map(&:last), "@builder.ternary($1, $3, $6)")
    assert_equal("@builder.call(:defined, [$4])", actions.fetch(261).last)
    assert_equal("@builder.case_node($2 || @builder.literal(nil), @builder.case_parts($5).first, @builder.case_parts($5).last)",
      actions.fetch(353).last)
    assert_equal("@builder.lambda_node($6, $8)", actions.fetch(456).last)
    assert_equal("@builder.body_nodes($2)", actions.fetch(594).last)
    assert_equal("@builder.append_arguments($1, $2)", actions.fetch(609).last)
  end

  test "generated Ruby 3.3 builder uses metadata for unsupported actions" do
    metadata = UNSUPPORTED_RULES.map do |id, (rule, line)|
      { "id" => id, "rule" => rule, "line" => line, "status" => "unsupported" }
    end
    template = File.read(File.expand_path("../../lib/arpaka/ruby/runtime/detailed/builder.rb.erb", __dir__))
    builder_source = ERB.new(template, trim_mode: "-").result_with_hash(rules: metadata, runtime: {})
    namespace = Module.new
    namespace.const_set(:UnsupportedSyntax, Class.new(StandardError) do
      attr_reader :rule, :line

      def initialize(rule, line)
        @rule, @line = rule, line
      end
    end)
    namespace.module_eval(builder_source)
    builder = namespace.const_get(:Builder, false).new

    UNSUPPORTED_RULES.each do |id, (rule, line)|
      classification, expression = PROFILE.fetch("actions").fetch(id)
      assert_equal("unsupported", classification)
      assert_equal("@builder.unsupported(#{id})", expression)
      error = assert_raise(namespace::UnsupportedSyntax) { builder.unsupported(id) }
      assert_equal(rule, error.rule)
      assert_equal(line, error.line)
    end
  end

  test "generated Ruby 3.3 frontend reports unsupported syntax with rule metadata" do
    parse_y = ENV["RUBY_3_3_PARSE_Y"]
    omit("Set RUBY_3_3_PARSE_Y to Ruby 3.3.10 parse.y") unless parse_y

    frontend = Arpaka.compile(parse_y: parse_y, class_name: "Ruby33RegressionFrontend")
    { "alias $x $1" => 29, "$1 += foo 2" => 53, "$1 += 2" => 229 }.each do |source, id|
      rule, line = UNSUPPORTED_RULES.fetch(id)
      error = assert_raise(frontend::UnsupportedSyntax) { frontend.parse(source) }
      assert_equal(rule, error.rule)
      assert_equal(line, error.line)
    end
  end
end

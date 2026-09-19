# frozen_string_literal: true

require "test_helper"

class Ruby33ProfileTest < Test::Unit::TestCase
  PROFILE = Arpaka::Ruby::Profile.send(:load, "profiles/ruby_3_3.rb", "ruby-3.3")

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
end

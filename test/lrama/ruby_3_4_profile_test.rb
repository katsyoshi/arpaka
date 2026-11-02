# frozen_string_literal: true

require "test_helper"
require_relative "../../benchmark/compatibility"

class Ruby34ProfileTest < Test::Unit::TestCase
  PROFILE = Arpaka::Ruby::Profile.send(:load, "profiles/ruby_3_4.rb", "ruby-3.4")

  test "uses a distinct AST node for self" do
    assert_include(PROFILE.fetch("runtime").fetch("ast_nodes"), "self")
    assert_include(PROFILE.fetch("runtime").fetch("builder_methods"), "self")
    assert_equal("@builder.self_node", PROFILE.fetch("actions").fetch(672).last)
  end

  test "preserves singleton definition wrappers" do
    assert_equal(["pass_through", "$1"], PROFILE.fetch("actions").fetch(391))
  end

  test "does not collapse self receivers into the self symbol" do
    assert_equal([:self], Compatibility::Normalizer.new.rubyvm(
      RubyVM::AbstractSyntaxTree.parse("self", keep_script_lines: false).children.fetch(2)))

    source = "self::Outer::Inner"
    tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
    normalized = Compatibility::Normalizer.new.rubyvm(tree.children.fetch(2))
    assert_equal([:constant_path,
      [:constant_path, [:self], [:symbol, [:bytes, "4f75746572", "US-ASCII"]]],
      [:symbol, [:bytes, "496e6e6572", "US-ASCII"]]], normalized)
  end
end

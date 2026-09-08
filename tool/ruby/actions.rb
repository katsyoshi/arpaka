# frozen_string_literal: true

# Rule IDs refer to upstream_rules.json, validated against the pinned source.
# Each entry is [classification, Ruby expression used as the reduction value].
module RubyGrammarActions
  ACTIONS = {
    1 => ["empty", "nil"], 2 => ["empty", "nil"], 3 => ["empty", "nil"],
    4 => ["pass_through", "$1"], 5 => ["ported", "@builder.program($2)"],
    6 => ["ported", "[].freeze"], 7 => ["ported", "[$1].freeze"],
    8 => ["ported", "($1 + [$3]).freeze"], 9 => ["pass_through", "$1"],
    13 => ["pass_through", "$1"], 19 => ["ported", "[].freeze"],
    20 => ["ported", "[$1].freeze"], 21 => ["ported", "($1 + [$3]).freeze"],
    22 => ["pass_through", "$1"], 45 => ["pass_through", "$1"],
    78 => ["pass_through", "$1"], 140 => ["ported", "@builder.declare_local($1)"],
    235 => ["ported", "@builder.assign($1, $4)"], 236 => ["pass_through", "$1"],
    253 => ["ported", "@builder.binary(:+, $1, $3)"],
    254 => ["ported", "@builder.binary(:-, $1, $3)"],
    255 => ["ported", "@builder.binary(:*, $1, $3)"],
    256 => ["ported", "@builder.binary(:/, $1, $3)"],
    260 => ["ported", "@builder.unary(:+, $2)"],
    261 => ["ported", "@builder.unary(:-, $2)"],
    283 => ["pass_through", "$1"], 294 => ["empty", "nil"],
    297 => ["pass_through", "$1"], 303 => ["pass_through", "$1"],
    339 => ["pass_through", "$1"], 347 => ["pass_through", "$1"],
    354 => ["ported", "@builder.parentheses($2, 354)"],
    637 => ["pass_through", "$1"], 690 => ["pass_through", "$1"],
    691 => ["ported", "@builder.unary(:-, $2)"],
    692 => ["ported", "@builder.integer($1)"], 693 => ["ported", "@builder.float($1)"],
    699 => ["ported", "@builder.identifier($1)"],
    702 => ["ported", "@builder.literal(nil)"],
    704 => ["ported", "@builder.literal(true)"], 705 => ["ported", "@builder.literal(false)"],
    709 => ["ported", "@builder.read_local($1)"], 710 => ["pass_through", "$1"],
    849 => ["empty", "nil"], 850 => ["empty", "nil"], 851 => ["empty", "nil"],
    852 => ["empty", "nil"], 853 => ["empty", "nil"]
  }.freeze
end

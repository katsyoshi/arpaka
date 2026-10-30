# frozen_string_literal: true

require "json"

module Arpaka
  module Ruby
    module Profile
      CURRENT = {
        "name" => "ruby-4.0",
        "actions" => ::Arpaka::Ruby::Actions::ACTIONS,
        # Rule numbers are stable only within one parse.y revision.  Keep
        # this Ruby 4.0-specific reduction keyed by its grammar signature so
        # the shared action table cannot accidentally apply the old action to
        # a shifted rule number.
        "compatibility_actions" => {
          ["top_stmt", ["keyword_BEGIN", "begin_block"]] =>
            ["ported", "@builder.begin_block($2)"],
          ["stmt_or_begin", ["keyword_BEGIN", "$@5", "begin_block"]] =>
            ["ported", "@builder.begin_block($3)"],
          ["begin_block", ["block_open", "compstmt_top_stmts", "'}'"]] =>
            ["pass_through", "$2"],
          ["stmt", ["k_END", "block_open", "compstmt_stmts", "'}'"]] =>
            ["ported", "@builder.end_block($3)"],
          ["mlhs_basic", ["mlhs_head", "tSTAR", "mlhs_node", "','", "mlhs_items_mlhs_item"]] =>
            ["ported", "@builder.multiple_assign_post($1, $3, $5)"],
          ["mlhs_basic", ["mlhs_head", "tSTAR", "','", "mlhs_items_mlhs_item"]] =>
            ["ported", "@builder.multiple_assign_post($1, nil, $4)"],
          ["mlhs_basic", ["tSTAR", "mlhs_node", "','", "mlhs_items_mlhs_item"]] =>
            ["ported", "@builder.multiple_assign_post([], $2, $4)"],
          ["mlhs_basic", ["tSTAR", "','", "mlhs_items_mlhs_item"]] =>
            ["ported", "@builder.multiple_assign_post([], nil, $3)"],
          ["f_opt_primary_value", ["f_arg_asgn", "f_eq", "primary_value"]] =>
            ["ported", "@builder.parameter(:optional, $1, $3)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_arg", "','", "f_opt_arg_primary_value", "','", "f_rest_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest(@builder.parameter_list($1, $3), $5), $6)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_arg", "','", "f_opt_arg_primary_value", "','", "f_rest_arg", "','", "f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest(@builder.parameter_list($1, $3), $5, $7), $8)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_arg", "','", "f_opt_arg_primary_value", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list($1, $3, $4)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_arg", "','", "f_opt_arg_primary_value", "','", "f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list($1, $3, $5, $6)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_arg", "','", "f_rest_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest($1, $3), $4)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_arg", "','", "f_rest_arg", "','", "f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest($1, $3, $5), $6)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_opt_arg_primary_value", "','", "f_rest_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest([], $1), $3)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_opt_arg_primary_value", "','", "f_rest_arg", "','", "f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest([], $1, $5), $6)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_opt_arg_primary_value", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list($1, $2)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_opt_arg_primary_value", "','", "f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list($1, $3, $4)"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_rest_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "(@builder.append_block_rest([], $1) + Array($2)).freeze"],
          ["args-list_primary_value_opt_args_tail_block_args_tail_none",
            ["f_rest_arg", "','", "f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list(@builder.append_block_rest([], $1, $3), $4)"],
          ["block_param", ["f_arg", "excessed_comma"]] =>
            ["ported", "@builder.parameter_list($1)"],
          ["block_param", ["f_arg", "opt_args_tail_block_args_tail_none"]] =>
            ["ported", "@builder.parameter_list($1, $2)"],
          ["block_param", ["tail-only-args_block_args_tail"]] =>
            ["ported", "@builder.parameter_list($1)"],
        }.freeze,
        "additional_expected_conflicts" => 0,
        "runtime" => {
          "ast_nodes" => %w[self assignment singleton_method singleton_class pattern keyword_arguments].freeze,
          "builder_methods" => %w[self assignment singleton_method singleton_class pattern keyword_arguments rescue].freeze,
          "lexer" => { "source_text_tokens" => %w[tOP_ASGN tUMINUS tUPLUS].freeze }.freeze
        }.freeze
      }.freeze

      def self.select(grammar)
        if grammar.rules.any? { |rule| rule.lhs.id.s_value == "value_expr_command" }
          CURRENT
        elsif grammar.rules.any? { |rule| rule.lhs.id.s_value == "top_compstmt" &&
          rule.rhs.any? { |symbol| symbol.id.s_value == "option_terms" } }
          legacy
        elsif grammar.rules.any? { |rule| rule.lhs.id.s_value == "top_compstmt" &&
          rule.rhs.any? { |symbol| symbol.id.s_value == "opt_terms" } }
          legacy_3_3
        else
          raise ::Arpaka::Error, "Unsupported Ruby parse.y profile"
        end
      end

      def self.legacy
        @legacy ||= load("profiles/ruby_3_4.rb", "ruby-3.4")
      end

      def self.legacy_3_3
        @legacy_3_3 ||= load("profiles/ruby_3_3.rb", "ruby-3.3")
      end

      def self.load(filename, name)
        box = ::Ruby::Box.new
        profile = box.eval(File.read(File.join(__dir__, filename)))
        unless profile.is_a?(Hash) && profile["name"] == name
          raise ::Arpaka::Error, "Invalid #{name} profile"
        end
        profile.freeze
      rescue SyntaxError, TypeError => error
        raise ::Arpaka::Error, "Ruby profile loading failed: #{error.message}"
      end
    end
  end
end

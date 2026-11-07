# frozen_string_literal: true

require "json"
require_relative "actions"
require_relative "profile"

module Arpaka::Ruby
  class GrammarEmitter
    EXTENDED_RULES = {
      ["value_expr_command", ["command"]] => "tLBRACE_ARG"
    }.freeze

    def initialize(grammar:, inventory:, names:)
      @grammar = grammar
      @inventory = inventory
      @names = names
    end

    def emit
      name = ->(symbol) { symbol.term ? symbol.id.s_value : @names.fetch(symbol.id.s_value) }
      profile = ::Arpaka::Ruby::Profile.select(@grammar)
      expected_conflicts = (@grammar.expect || 0) + profile.fetch("additional_expected_conflicts", 0)
      lines = ["/* Generated from ruby/ruby #{Arpaka::Ruby::Grammar::REVISION}. See Arpaka Action mappings. */",
        "%no-stdlib", "%expect #{expected_conflicts}"]
      lines << "%define lr.type ielr" if @grammar.ielr_defined?
      @grammar.terms.each do |symbol|
        next if symbol.error_symbol? || symbol.undef_symbol?
        declaration = "%token #{name.call(symbol)} #{symbol.token_id}"
        declaration += " #{symbol.alias_name}" if symbol.alias_name
        lines << declaration
      end
      @grammar.precedences.group_by(&:precedence).sort.each do |_level, group|
        lines << "%#{group.first.type} #{group.map(&:s_value).join(' ')}"
      end
      lines << "%left keyword_do_block"
      lines << "%start #{name.call(@grammar.rules.first.rhs.first)}"
      lines << "%%"
      metadata = @inventory.to_h { |rule| [rule.fetch("id"), rule] }
      rules = @grammar.rules.reject(&:initial_rule?)
      rules.each do |rule|
        rhs = rule.rhs.empty? ? "%empty" : rule.rhs.map(&name).join(" ")
        extended_precedence = EXTENDED_RULES[[rule.lhs.id.s_value, rule.rhs.map { |symbol| symbol.id.s_value }]]
        precedence = if rule.precedence_sym
          " %prec #{name.call(rule.precedence_sym)}"
        elsif extended_precedence
          " %prec #{extended_precedence}"
        else
          ""
        end
        key = [rule.lhs.id.s_value, rule.rhs.map { |symbol| symbol.id.s_value }]
        action = profile.fetch("compatibility_actions", {})[key] || profile.fetch("actions")[rule.id]
        expression = action&.last || "@builder.unsupported(#{rule.id})"
        lines << "/* upstream parse.y:#{metadata.fetch(rule.id).fetch('line')}: #{rule.as_comment} */"
        lines << "#{name.call(rule.lhs)}: #{rhs}#{precedence} { $$ = #{expression} };"
      end
      lines << "/* arpaka extension: block call as a parenthesized argument */"
      lines << "call_args: block_call { $$ = [$1].freeze };"
      lines << "call_args: args ',' block_call %prec tLOWEST { $$ = ($1 + [$3]).freeze };"
      source = lines.join("\n") + "\n"
      compact = rules.map do |rule|
        { id: rule.id, rule: rule.as_comment,
          line: metadata.fetch(rule.id).fetch("line"),
          status: (profile.fetch("compatibility_actions", {})[[rule.lhs.id.s_value,
              rule.rhs.map { |symbol| symbol.id.s_value }]] || profile.fetch("actions")[rule.id])&.first || "unsupported" }
      end
      { "parse.y" => source, "rules.json" => JSON.pretty_generate(compact) + "\n",
        "runtime" => profile.fetch("runtime", {}),
        "source_profile" => profile.fetch("source_tag", Arpaka::Ruby::Grammar::REVISION) }
    end
  end
end

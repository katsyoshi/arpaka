# frozen_string_literal: true

require "lrama"
require "json"
require "digest"
require "open3"
require "rbconfig"
require_relative "actions"

module Arpaka::RubyGrammar
  REVISION = "37d60dd3241d5fdb10ca43f36077f5d556ae1b8d"
  EXTENDED_RULES = {
    ["value_expr_command", ["command"]] => "tLBRACE_ARG"
  }.freeze

  def self.parse(source, filename)
    grammar = Lrama::Parser.new(source, filename).parse
    unless grammar.no_stdlib
      stdlib = Lrama::Command::STDLIB_FILE_PATH
      grammar.prepend_parameterized_rules(Lrama::Parser.new(File.read(stdlib), stdlib).parse.parameterized_rules)
    end
    grammar.prepare
    grammar.validate!
    grammar
  end

  def self.load_upstream(ruby_source)
    vendor = File.expand_path(ruby_source)
    manifest = JSON.parse(File.read(File.join(__dir__, "source.json")))
    raise ::Arpaka::Error, "Unexpected upstream revision" unless manifest.fetch("revision") == REVISION
    manifest.fetch("files").each do |path, digest|
      actual = Digest::SHA256.file(File.join(vendor, path)).hexdigest
      next if actual == digest

      warn "Arpaka: Ruby source differs from the recorded profile: #{path}; " \
        "expected SHA256 #{digest}, got #{actual}."
    end
    source, error, result = Open3.capture3(RbConfig.ruby,
      File.join(vendor, "tool/id2token.rb"), File.join(vendor, "parse.y"))
    raise ::Arpaka::Error, "Ruby preprocessing failed: #{error}" unless result.success?
    grammar = parse(source, File.join(vendor, "parse.y"))
    inventory = grammar.rules.reject(&:initial_rule?).map do |rule|
      { "id" => rule.id, "lhs" => rule.lhs.id.s_value,
        "rhs" => rule.rhs.map { |symbol| symbol.id.s_value },
        "line" => rule.token_code&.location&.first_line || rule.lineno,
        "code" => rule.token_code&.s_value,
        "midrule_position" => rule.position_in_original_rule_rhs,
        "precedence" => rule.precedence_sym&.id&.s_value }
    end
    unknown = ::Arpaka::RubyGrammarActions::ACTIONS.keys - inventory.map { |rule| rule.fetch("id") }
    warn "Arpaka: Unknown action IDs: #{unknown.inspect}" unless unknown.empty?
    [grammar, inventory]
  end

  def self.symbol_names(grammar)
    used = grammar.terms.map { |symbol| symbol.id.s_value }
    grammar.nterms.to_h do |symbol|
      original = symbol.id.s_value
      candidate = if original.match?(/\A\$?@\d+\z/)
        "midrule_#{original.delete('$@')}"
      else
        original.gsub("'\\n'", "newline").gsub(/[^a-zA-Z0-9_]/, "_")
      end
      candidate = "rule_#{candidate}" unless candidate.match?(/\A[a-zA-Z_]/)
      candidate += "_#{symbol.number}" if used.include?(candidate)
      raise ::Arpaka::Error, "Symbol name collision: #{candidate}" if used.include?(candidate)
      used << candidate
      [original, candidate]
    end
  end

  def self.artifacts(ruby_source:)
    grammar, inventory = load_upstream(ruby_source)
    names = symbol_names(grammar)
    name = ->(symbol) { symbol.term ? symbol.id.s_value : names.fetch(symbol.id.s_value) }
    lines = ["/* Generated from ruby/ruby #{REVISION}. See Arpaka Action mappings. */",
      "%no-stdlib", "%expect #{grammar.expect || 0}"]
    lines << "%define lr.type ielr" if grammar.ielr_defined?
    grammar.terms.each do |symbol|
      next if symbol.error_symbol? || symbol.undef_symbol?
      declaration = "%token #{name.call(symbol)} #{symbol.token_id}"
      declaration += " #{symbol.alias_name}" if symbol.alias_name
      lines << declaration
    end
    grammar.precedences.group_by(&:precedence).sort.each do |_level, group|
      lines << "%#{group.first.type} #{group.map(&:s_value).join(' ')}"
    end
    lines << "%left keyword_do_block"
    lines << "%start #{name.call(grammar.rules.first.rhs.first)}"
    lines << "%%"
    metadata = inventory.to_h { |rule| [rule.fetch("id"), rule] }
    rules = grammar.rules.reject(&:initial_rule?)
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
      expression = ::Arpaka::RubyGrammarActions::ACTIONS[rule.id]&.last || "@builder.unsupported(#{rule.id})"
      lines << "/* upstream parse.y:#{metadata.fetch(rule.id).fetch('line')}: #{rule.as_comment} */"
      lines << "#{name.call(rule.lhs)}: #{rhs}#{precedence} { $$ = #{expression} };"
    end
    lines << "/* arpaka extension: block call as a parenthesized argument */"
    lines << "call_args: block_call { $$ = [$1].freeze };"
    lines << "call_args: args ',' block_call %prec tLOWEST { $$ = ($1 + [$3]).freeze };"
    source = lines.join("\n") + "\n"
    verify_structure(grammar, source, names)
    compact = rules.map do |rule|
      { id: rule.id, rule: rule.as_comment,
        line: metadata.fetch(rule.id).fetch("line"),
        status: ::Arpaka::RubyGrammarActions::ACTIONS[rule.id]&.first || "unsupported" }
    end
    { "parse.y" => source, "rules.json" => JSON.pretty_generate(compact) + "\n" }
  end

  def self.verify_structure(original, source, names)
    # C-lexer inspection only: @builder is a Ruby ivar, not a yacc location.
    port = parse(source.gsub("@builder.", "builder_"), "generated Ruby grammar")
    signature = lambda do |grammar, rename|
      grammar.rules.reject(&:initial_rule?).map do |rule|
        name = ->(symbol) { rename.fetch(symbol.id.s_value, symbol.id.s_value) }
        [name.call(rule.lhs), rule.rhs.map(&name), rule.precedence_sym && name.call(rule.precedence_sym)]
      end.sort_by(&:inspect)
    end
    expected_rules = signature.call(original, names).map do |rule|
      if rule[0] == names.fetch("value_expr_command") && rule[1] == [names.fetch("command")]
        rule[0, 2] + ["tLBRACE_ARG"]
      else
        rule
      end
    end
    expected_rules << ["call_args", ["block_call"], nil]
    expected_rules << ["call_args", ["args", "','", "block_call"], "tLOWEST"]
    actual_rules = signature.call(port, {})
    unless expected_rules.sort_by(&:inspect) == actual_rules.sort_by(&:inspect)
      raise ::Arpaka::Error, "Production structure changed"
    end
    terms = lambda do |grammar|
      grammar.terms.map { |symbol| [symbol.id.s_value, symbol.token_id, symbol.precedence&.type, symbol.precedence&.precedence] }.sort_by(&:inspect)
    end
    expected_terms = terms.call(original).map do |term|
      if term[0] == "keyword_do_block"
        [term[0], term[1], :left, original.precedences.map(&:precedence).max + 1]
      else
        term
      end
    end
    actual_terms = terms.call(port)
    unless expected_terms.sort_by(&:inspect) == actual_terms
      raise ::Arpaka::Error, "Tokens or precedence changed: expected=#{expected_terms.sort_by(&:inspect).inspect} actual=#{actual_terms.inspect}"
    end
  end

end

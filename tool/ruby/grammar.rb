# frozen_string_literal: true

require "lrama"
require "json"
require "digest"
require "open3"
require "rbconfig"
require_relative "actions"

module RubyGrammar
  ROOT = File.expand_path("../..", __dir__)
  DESTINATION = File.join(ROOT, "lib/lrama/ruby/languages/ruby")
  REVISION = "37d60dd3241d5fdb10ca43f36077f5d556ae1b8d"

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

  def self.load_upstream
    vendor = File.join(ROOT, "vendor/ruby")
    manifest = JSON.parse(File.read(File.join(vendor, "source.json")))
    raise "Unexpected upstream revision" unless manifest.fetch("revision") == REVISION
    manifest.fetch("files").each do |path, digest|
      raise "Upstream checksum mismatch: #{path}" unless Digest::SHA256.file(File.join(vendor, path)).hexdigest == digest
    end
    source, error, result = Open3.capture3(RbConfig.ruby,
      File.join(vendor, "tool/id2token.rb"), File.join(vendor, "parse.y"))
    raise error unless result.success?
    grammar = parse(source, "vendor/ruby/parse.y")
    inventory = grammar.rules.reject(&:initial_rule?).map do |rule|
      { "id" => rule.id, "lhs" => rule.lhs.id.s_value,
        "rhs" => rule.rhs.map { |symbol| symbol.id.s_value },
        "line" => rule.token_code&.location&.first_line || rule.lineno,
        "code" => rule.token_code&.s_value,
        "midrule_position" => rule.position_in_original_rule_rhs,
        "precedence" => rule.precedence_sym&.id&.s_value }
    end
    expected = JSON.parse(File.read(File.join(__dir__, "upstream_rules.json")))
    raise "Upstream rules changed; review action mappings" unless inventory == expected
    unknown = RubyGrammarActions::ACTIONS.keys - inventory.map { |rule| rule.fetch("id") }
    raise "Unknown action IDs: #{unknown.inspect}" unless unknown.empty?
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
      raise "Symbol name collision: #{candidate}" if used.include?(candidate)
      used << candidate
      [original, candidate]
    end
  end

  def self.artifacts
    grammar, inventory = load_upstream
    names = symbol_names(grammar)
    name = ->(symbol) { symbol.term ? symbol.id.s_value : names.fetch(symbol.id.s_value) }
    lines = ["/* Generated from ruby/ruby #{REVISION}. See tool/ruby/actions.rb. */",
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
    lines << "%start #{name.call(grammar.rules.first.rhs.first)}"
    lines << "%%"
    metadata = inventory.to_h { |rule| [rule.fetch("id"), rule] }
    rules = grammar.rules.reject(&:initial_rule?)
    rules.each do |rule|
      rhs = rule.rhs.empty? ? "%empty" : rule.rhs.map(&name).join(" ")
      precedence = rule.precedence_sym ? " %prec #{name.call(rule.precedence_sym)}" : ""
      expression = RubyGrammarActions::ACTIONS[rule.id]&.last || "@builder.unsupported(#{rule.id})"
      lines << "/* upstream parse.y:#{metadata.fetch(rule.id).fetch('line')}: #{rule.as_comment} */"
      lines << "#{name.call(rule.lhs)}: #{rhs}#{precedence} { $$ = #{expression} };"
    end
    source = lines.join("\n") + "\n"
    verify_structure(grammar, source, names)
    compact = rules.map do |rule|
      { id: rule.id, rule: rule.as_comment,
        line: metadata.fetch(rule.id).fetch("line"),
        status: RubyGrammarActions::ACTIONS[rule.id]&.first || "unsupported" }
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
    raise "Production structure changed" unless signature.call(original, names) == signature.call(port, {})
    terms = lambda do |grammar|
      grammar.terms.map { |symbol| [symbol.id.s_value, symbol.token_id, symbol.precedence&.type, symbol.precedence&.precedence] }.sort_by(&:inspect)
    end
    raise "Tokens or precedence changed" unless terms.call(original) == terms.call(port)
  end

  def self.run(check:)
    artifacts.each do |file, contents|
      path = File.join(DESTINATION, file)
      if check
        raise "Stale #{file}; run rake ruby:generate" unless File.file?(path) && File.read(path) == contents
      else
        File.write(path, contents)
      end
    end
    puts(check ? "Ruby grammar verified (853 productions)" : "Ruby grammar regenerated")
  end
end

RubyGrammar.run(check: ARGV.include?("--check")) if $PROGRAM_NAME == __FILE__

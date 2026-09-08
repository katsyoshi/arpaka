# frozen_string_literal: true

require "lrama"
require "prism"
require "erb"
require_relative "action_code"

module Lrama
  module Ruby
    class Backend
      class Error < StandardError; end

      def generate(source, filename:, class_name:)
        grammar = Lrama::Parser.new(source, filename).parse
        unless grammar.no_stdlib
          path = Lrama::Command::STDLIB_FILE_PATH
          stdlib = Lrama::Parser.new(File.read(path), path).parse
          grammar.prepend_parameterized_rules(stdlib.parameterized_rules)
        end
        grammar.prepare
        grammar.validate!
        validate_features!(grammar)

        states = Lrama::States.new(grammar, Lrama::Tracer.new($stderr))
        states.compute
        states.compute_ielr if grammar.ielr_defined?
        if states.rr_conflicts_count.positive? || states.sr_conflicts_count != (grammar.expect || 0)
          raise Error, "Unresolved conflicts: #{states.sr_conflicts_count} shift/reduce, #{states.rr_conflicts_count} reduce/reduce"
        end
        context = Lrama::Context.new(states)
        tokens = token_names(grammar)
        actions = grammar.rules.filter_map do |rule|
          next unless rule.token_code
          # Preserve whitespace inside multiline strings and heredocs.
          "    when #{rule.id + 1}\n#{translate_action(rule)}\n"
        end.join
        template = File.read(File.expand_path("parser.rb.erb", __dir__))
        result = ::ERB.new(template, trim_mode: "-").result_with_hash(
          class_name: class_name, context: context, tokens: tokens, actions: actions
        )
        errors = Prism.parse(result).errors
        unless errors.empty?
          raise Error, "Invalid generated Ruby for #{filename}: #{errors.map(&:message).join('; ')}"
        end
        result
      end

      private

      def translate_action(rule)
        code = rule.token_code.s_value.dup
        position = rule.position_in_original_rule_rhs || rule.rhs.length
        rule.token_code.references.reverse_each do |reference|
          replacement = if reference.name == "$"
            "yyval"
          else
            "values[#{reference.index - position - 1}]"
          end
          if code.byteslice(reference.first_column - 1, 1) == "#"
            replacement = "{#{replacement}}"
          end
          # Lrama and Prism locations are byte offsets, including for UTF-8.
          code = code.byteslice(0, reference.first_column) + replacement +
            code.byteslice(reference.last_column..)
        end
        code
      end

      def token_names(grammar)
        grammar.terms.each_with_object({}) do |term, names|
          next if term.error_symbol? || term.undef_symbol?
          names[term.id.s_value] = term.token_id
          if term.id.is_a?(Lrama::Lexer::Token::Char)
            names[term.token_id.chr(Encoding::UTF_8)] = term.token_id
          end
          if term.alias_name&.start_with?('"')
            names[term.alias_name[1...-1]] = term.token_id
          end
        end
      end

      def validate_features!(grammar)
        unsupported = []
        unsupported << "%locations" if grammar.locations
        unsupported << "%union" if grammar.union
        unsupported << "%code" unless grammar.percent_codes.empty?
        unsupported << "prologue" unless grammar.aux.prologue.to_s.strip.empty?
        unsupported << "epilogue" unless grammar.aux.epilogue.to_s.strip.empty?
        {
          "%parse-param" => grammar.parse_param, "%lex-param" => grammar.lex_param,
          "%initial-action" => grammar.initial_action, "%after-shift" => grammar.after_shift,
          "%before-reduce" => grammar.before_reduce, "%after-reduce" => grammar.after_reduce,
          "%after-shift-error-token" => grammar.after_shift_error_token,
          "%after-pop-stack" => grammar.after_pop_stack
        }.each { |name, value| unsupported << name if value }
        unsupported << "%printer" unless grammar.printers.empty?
        unsupported << "%error-token" unless grammar.error_tokens.empty?
        unsupported << "%destructor" if grammar.symbols.any?(&:destructor)
        unsupported << "typed symbols" if grammar.symbols.any?(&:tag)
        if grammar.rules.any? { |rule| rule.rhs.include?(grammar.error_symbol) }
          unsupported << "error recovery rules"
        end
        raise Error, "Not supported by the Ruby backend yet: #{unsupported.join(', ')}" unless unsupported.empty?
      end
    end
  end
end

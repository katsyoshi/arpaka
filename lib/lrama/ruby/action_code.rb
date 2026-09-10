# frozen_string_literal: true

require_relative "action_scanner"

module Lrama
  module Ruby
    # Loaded only in the generator's box. Ruby strings, comments, regular
    # expressions and instance variables must not become grammar references.
    module ActionReferences
      def ruby_short_reference?(offset)
        references
        @ruby_short_references.include?(offset)
      end

      private

      def _references
        result = ActionScanner.new(s_value, filename: location.grammar_file.path,
          line: location.first_line, column: location.first_column).scan
        @ruby_short_references = result.references.select(&:short_interpolation).map(&:first_column)
        result.references.map do |reference|
          attributes = if reference.number
            { number: reference.number, index: reference.number }
          else
            { name: reference.name }
          end
          Grammar::Reference.new(type: :dollar, **attributes,
            first_column: reference.first_column, last_column: reference.last_column)
        end
      rescue ActionScanner::Error => error
        raise Backend::Error, error.message
      end
    end

    module ActionLexer
      def lex_c_code
        return super unless @end_symbol == "}"

        reset_first_position
        result = ActionScanner.new(@scanner.rest, filename: @grammar_file.path,
          line: line, column: column).scan(action: true)
        code = @scanner.string.byteslice(@scanner.pos, result.end_offset)
        @scanner.pos += code.bytesize
        @line += code.count("\n")
        @head = @scanner.pos - code.bytesize + code.b.rindex("\n") + 1 if code.include?("\n")
        [:C_DECLARATION, Lexer::Token::UserCode.new(s_value: code, location: location)]
      rescue ActionScanner::Error => error
        raise Backend::Error, error.message
      end
    end
  end
end

Lrama::Lexer::Token::UserCode.prepend(Lrama::Ruby::ActionReferences)
Lrama::Lexer.prepend(Lrama::Ruby::ActionLexer)

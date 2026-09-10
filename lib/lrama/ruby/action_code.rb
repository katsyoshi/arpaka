# frozen_string_literal: true

require "prism"

module Lrama
  module Ruby
    # Loaded only in the generator's box. Ruby strings, comments, regular
    # expressions and instance variables must not become grammar references.
    module ActionReferences
      private

      def _references
        Prism.lex(s_value).value.filter_map do |token, _state|
          next unless [:GLOBAL_VARIABLE, :NUMBERED_REFERENCE].include?(token.type)

          value = token.value
          unless /\A\$(?:\$|[1-9][0-9]*|[a-zA-Z_][a-zA-Z0-9_]*)\z/.match?(value)
            raise Backend::Error, "Unsupported semantic reference: #{value}"
          end

          attributes = if /\A\$[0-9]+\z/.match?(value)
            { number: value.delete_prefix("$").to_i, index: value.delete_prefix("$").to_i }
          else
            { name: value.delete_prefix("$") }
          end
          Grammar::Reference.new(type: :dollar, **attributes,
            first_column: token.location.start_offset, last_column: token.location.end_offset)
        end.sort_by(&:first_column)
      end
    end

    module ActionLexer
      def lex_c_code
        return super unless @end_symbol == "}"

        reset_first_position
        depth = 0
        # Prism recovers from the yacc references (which are not yet valid
        # Ruby assignments) and still provides byte-accurate token locations.
        Prism.lex(@scanner.rest).value.each do |token, _state|
          case token.type
          when :BRACE_LEFT, :LAMBDA_BEGIN, :EMBEXPR_BEGIN
            depth += 1
          when :BRACE_RIGHT, :EMBEXPR_END
            if depth.zero?
              code = @scanner.rest.byteslice(0, token.location.start_offset)
              @scanner.pos += code.bytesize
              @line += code.count("\n")
              @head = @scanner.pos - code.bytesize + code.b.rindex("\n") + 1 if code.include?("\n")
              return [:C_DECLARATION, Lexer::Token::UserCode.new(s_value: code, location: location)]
            end
            depth -= 1
          end
        end
        raise Backend::Error, "Unterminated Ruby action at line #{line}"
      end
    end
  end
end

Lrama::Lexer::Token::UserCode.prepend(Lrama::Ruby::ActionReferences)
Lrama::Lexer.prepend(Lrama::Ruby::ActionLexer)

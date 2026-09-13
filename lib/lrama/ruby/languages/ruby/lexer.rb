# frozen_string_literal: true

module Lrama
  module Ruby
    module Languages
      module Ruby
        # Lexer for Ruby source input.  This deliberately does not use Prism:
        # the parser needs the same small amount of lexical context that CRuby
        # keeps in its parser (EXPR_BEG/EXPR_END and delimiter nesting).
        class LexicalContext
          attr_accessor :begin_expression, :condition_do, :condition_line,
            :ternary_depth, :lambda_pending, :alias_context, :argument_label,
            :lex_state, :command_start, :label_pending
          attr_reader :delimiter_stack, :cmdarg_stack, :condition_stack,
            :token_history, :state_history, :block_stack, :scope_stack, :parser_events,
            :parser_delimiter_stack, :parser_cmdarg_stack, :parser_block_stack,
            :parser_condition_stack

          def initialize
            @begin_expression = true
            @condition_do = false
            @condition_line = false
            @ternary_depth = 0
            @lambda_pending = false
            @alias_context = false
            @argument_label = nil
            @label_pending = false
            @lex_state = :expr_beg
            @command_start = true
            @delimiter_stack = []
            @cmdarg_stack = []
            @condition_stack = []
            @token_history = []
            @state_history = []
            @block_stack = []
            @scope_stack = []
            @parser_events = []
            @parser_delimiter_stack = []
            @parser_cmdarg_stack = []
            @parser_block_stack = []
            @parser_condition_stack = []
          end

          def delimiter_depth
            @delimiter_stack.length
          end

          def push_delimiter(value)
            @delimiter_stack << value
          end

          def pop_delimiter(value)
            @delimiter_stack.pop if @delimiter_stack.last == value
          end

          def push_cmdarg(value)
            @cmdarg_stack << value
          end

          def pop_cmdarg
            @cmdarg_stack.pop
          end

          def cmdarg?
            @cmdarg_stack.last == true
          end

          def push_condition(value = true)
            @condition_stack << value
          end

          def pop_condition
            @condition_stack.pop
          end

          def condition?
            @condition_stack.any?
          end

          def push_block(value)
            @block_stack << value
          end

          def pop_block
            @block_stack.pop
          end

          def block_depth
            @block_stack.length
          end

          def push_scope(value)
            @scope_stack << value
          end

          def pop_scope
            @scope_stack.pop
          end

          def scope_depth
            @scope_stack.length
          end

          def remember_token(token)
            @token_history << token
            @token_history.shift while @token_history.length > 4
          end

          def remember_state(token)
            @state_history << {
              token: token,
              lex_state: @lex_state,
              begin_expression: @begin_expression,
              command_start: @command_start,
              delimiter_depth: delimiter_depth,
              cmdarg_depth: @cmdarg_stack.length,
              condition_depth: @condition_stack.length,
              block_depth: @block_stack.length,
              scope_depth: @scope_stack.length
            }.freeze
          end

          def parser_shift(token, value, state, action)
            @parser_events << [:shift, token, state, action].freeze
            if ["(", "[", :tLPAREN_ARG].include?(token)
              @parser_delimiter_stack << token
              @parser_cmdarg_stack << (token == :tLPAREN_ARG)
            elsif [")", "]", "}"].include?(token)
              opener = {")" => "(", "]" => "[", "}" => "{"
              }.fetch(token)
              @parser_delimiter_stack.pop if @parser_delimiter_stack.last == opener
              @parser_cmdarg_stack.pop
            end
            if [:keyword_do, :keyword_do_block, :keyword_do_LAMBDA, :tLAMBEG].include?(token) ||
                token == "{" || token == :tLBRACE_ARG
              @parser_block_stack << token
            elsif token == "}" && @parser_block_stack.last
              @parser_block_stack.pop
            elsif token == :keyword_end && @parser_block_stack.last
              @parser_block_stack.pop
            end
            if [:keyword_while, :keyword_until, :keyword_for].include?(token)
              @parser_condition_stack << token
            elsif token == :keyword_do_cond && @parser_condition_stack.last
              @parser_condition_stack.pop
            elsif token == :keyword_end && @parser_condition_stack.last
              @parser_condition_stack.pop
            end
          end

          def parser_reduce(rule, state)
            @parser_events << [:reduce, rule, state].freeze
          end
        end

        class Lexer
          Error = LexerError

          attr_reader :context

          KEYWORDS = {
            "class" => :keyword_class, "module" => :keyword_module,
            "def" => :keyword_def, "begin" => :keyword_begin,
            "rescue" => :keyword_rescue, "ensure" => :keyword_ensure,
            "end" => :keyword_end, "if" => :keyword_if,
            "unless" => :keyword_unless, "then" => :keyword_then,
            "elsif" => :keyword_elsif, "else" => :keyword_else,
            "case" => :keyword_case, "when" => :keyword_when,
            "while" => :keyword_while, "until" => :keyword_until,
            "for" => :keyword_for, "break" => :keyword_break,
            "next" => :keyword_next, "redo" => :keyword_redo,
            "retry" => :keyword_retry, "return" => :keyword_return,
            "yield" => :keyword_yield, "super" => :keyword_super,
            "self" => :keyword_self, "nil" => :keyword_nil,
            "true" => :keyword_true, "false" => :keyword_false,
            "and" => :keyword_and, "or" => :keyword_or,
            "not" => :keyword_not, "alias" => :keyword_alias,
            "defined?" => :keyword_defined, "in" => :keyword_in,
            "BEGIN" => :keyword_BEGIN, "END" => :keyword_END,
            "__LINE__" => :keyword__LINE__, "__FILE__" => :keyword__FILE__,
            "__ENCODING__" => :keyword__ENCODING__
          }.freeze

          OPERATORS = %w[[]= [] ... .. <=> === == != =~ !~ >= <= && || << >> ** => :: &. -> += -= *= /= %= **= <<= >>= &&= ||= |= &= ^=].freeze
          OP_TOKENS = {
            "**" => :tPOW, "<=>" => :tCMP, "==" => :tEQ, "===" => :tEQQ,
            "!=" => :tNEQ, ">=" => :tGEQ, "<=" => :tLEQ, "&&" => :tANDOP,
            "||" => :tOROP, "=~" => :tMATCH, "!~" => :tNMATCH,
            ".." => :tDOT2, "..." => :tDOT3, "<<" => :tLSHFT,
            ">>" => :tRSHFT, "&." => :tANDDOT, "::" => :tCOLON2,
            "=>" => :tASSOC, "->" => :tLAMBDA, "[]" => :tAREF, "[]=" => :tASET
          }.freeze

          def initialize(source, filename: "(ruby)")
            unless source.is_a?(String)
              raise ArgumentError, "source must be a String"
            end
            unless [Encoding::UTF_8, Encoding::US_ASCII].include?(source.encoding) && source.valid_encoding?
              raise Error, "#{filename}:1:0: invalid UTF-8 source"
            end
            @source = source.b
            @filename = filename
            @index = 0
            @line = 1
            @column = 0
            @previous_previous = nil
            @previous = nil
            @previous_value = nil
            @context = LexicalContext.new
            @pending = []
            @class_superclass = false
          end

          def each
            return enum_for(__method__) unless block_given?
            until eof? && @pending.empty?
              token = next_token
              yield token if token
            end
            yield [0, nil]
          end

          private

          def eof?
            @index >= @source.bytesize
          end

          def byte(offset = 0)
            @source.getbyte(@index + offset)
          end

          def advance(count = 1)
            count.times do
              value = byte
              @index += 1
              if value == 10
                @line += 1
                @column = 0
              else
                @column += 1
              end
            end
          end

          def fail!(message, index = @index, line = @line, column = @column)
            raise Error, "#{@filename}:#{line}:#{column}: #{message}"
          end

          def next_token
            unless @pending.empty?
              value = @pending.shift
              return next_token if value[0] == "\n" && newline_ignored?
              @previous_previous = @previous
              @previous = value[0]
              @previous_value = value[1]
              update_pending_delimiter(value[0])
              update_argument_label(value[0], value[1])
              @context.remember_token(value[0])
              @context.begin_expression = expression_begin_after(value[0])
              @context.lex_state = lexical_state_after(value[0])
              @context.command_start = command_start_after(value[0])
              update_block_context(value[0])
              @context.remember_state(value[0])
              return value
            end
            skip_space_and_comments
            return nil if eof?

            start = @index
            value = case byte
            when 10
              advance
              if @context.alias_context && @previous == :tEQ
                @context.alias_context = false
                return ["\n", nil]
              end
              if @class_superclass && next_word_is_terminator?
                @class_superclass = false
                return [";", nil]
              end
              @class_superclass = false
              return next_token if newline_ignored?
              @context.pop_condition if @context.condition? && @context.condition_do
              @context.condition_do = false
              ["\n", nil]
            when 39, 34, 96
              string_token(byte, start)
            when 47
              regexp_or_operator(start)
            when 37
              percent_token(start)
            when 60
              heredoc_or_operator(start)
            when 48..57
              number_token(start)
            when 36, 64
              variable_token(start)
            when 63
              character_or_question(start)
            when 58
              symbol_or_colon(start)
            when 65..90, 95, 97..122, 128..255
              identifier_token(start)
            else
              operator_or_punctuation(start)
            end
            @previous_previous = @previous
            @previous = value && value[0]
            @previous_value = value && value[1]
            update_argument_label(value && value[0], value && value[1])
            @context.remember_token(value && value[0])
            @context.begin_expression = expression_begin_after(value && value[0])
            @context.lex_state = lexical_state_after(value && value[0])
            @context.command_start = command_start_after(value && value[0])
            update_block_context(value && value[0])
            @context.remember_state(value && value[0])
            value
          end

          def skip_space_and_comments
            loop do
              while [9, 11, 12, 13, 32].include?(byte)
                advance
              end
              if byte == 92 && byte(1) == 10
                advance(2)
                next
              end
              break unless byte == 35
              advance
              advance while !eof? && byte != 10
            end
          end

          def newline_ignored?
            ignored = @context.delimiter_depth.positive? || @previous == "\n" ||
              ["+", "-", "*", "/", "%", "=", "?", ":", ",", ".", "&", "|", "^", "<<", ">>", "&&", "||", "=>", :keyword_and, :keyword_or, :keyword_not, :tAMPER, :tPIPE, :tSTAR, :tDSTAR, :tDOT2, :tDOT3, :tPOW, :tCMP, :tEQ, :tEQQ, :tNEQ, :tGEQ, :tLEQ, :tANDOP, :tOROP, :tMATCH, :tNMATCH, :tLSHFT, :tRSHFT, :tASSOC, :tLAMBDA, :tCOLON2, :tANDDOT].include?(@previous) ||
              @previous == :tLABEL ||
              [:modifier_if, :modifier_unless, :modifier_while, :modifier_until].include?(@previous) ||
              [:tANDOP, :tOROP, :tMATCH, :tNMATCH, :tASSOC, :tOP_ASGN].include?(@previous) ||
              next_non_space_byte == 46
            @context.condition_line = false if ignored && @context.condition_line
            ignored
          end

          def next_word_is_terminator?
            position = @index
            position += 1 while [9, 11, 12, 13, 32].include?(@source.getbyte(position))
            %w[else elsif end when].any? do |word|
              @source.byteslice(position, word.bytesize) == word &&
                !identifier_byte?(@source.getbyte(position + word.bytesize))
            end
          end

          def next_non_space_byte
            position = @index
            position += 1 while [9, 11, 12, 13, 32].include?(@source.getbyte(position))
            @source.getbyte(position)
          end

          def update_pending_delimiter(token)
            if ["(", "[", :tLPAREN_ARG].include?(token)
              @context.push_delimiter(token)
              @context.push_cmdarg(token == :tLPAREN_ARG)
            elsif [")", "]", "}"].include?(token)
              opener = {")" => "(", "]" => "[", "}" => "{"
              }.fetch(token)
              @context.pop_delimiter(opener)
              @context.pop_cmdarg
            end
          end

          def update_argument_label(token, value)
            if token == :tLABEL
              @context.argument_label = value
              @context.label_pending = true
            elsif ["\n", ";"].include?(token)
              @context.argument_label = nil
            end
          end

          def expression_begin_after(token)
            return true if token.nil? || token == "\n"
            return false if token == ")" || token == "]" || token == "}"
            return false if token == :tINTEGER || token == :tFLOAT || token == :tRATIONAL || token == :tIMAGINARY
            return false if token == :tIDENTIFIER || token == :tCONSTANT || token == :tFID || token == :tSTRING_END || token == :tREGEXP_END
            return false if token == :keyword_true || token == :keyword_false || token == :keyword_nil || token == :keyword_self
            return false if [:keyword__LINE__, :keyword__FILE__, :keyword__ENCODING__].include?(token)
            return false if token == :tIVAR || token == :tGVAR || token == :tCVAR || token == :tNTH_REF
            true
          end

          def lexical_state_after(token)
            return :expr_beg if token.nil? || token == "\n"
            return :expr_fname if @previous_previous == :keyword_def || @context.alias_context
            return :expr_end if token == 0
            if @context.label_pending && token != :tLABEL
              @context.label_pending = false
              return :expr_labeled
            end
            return :expr_end if [")", "]", "}", :tSTRING_END, :tREGEXP_END,
              :tINTEGER, :tFLOAT, :tRATIONAL, :tIMAGINARY, :tIDENTIFIER,
              :tCONSTANT, :tFID, :tIVAR, :tGVAR, :tCVAR, :tNTH_REF,
              :keyword_true, :keyword_false, :keyword_nil, :keyword_self,
              :keyword__LINE__, :keyword__FILE__, :keyword__ENCODING__].include?(token)
            return :expr_label if token == :tLABEL
            :expr_beg
          end

          def command_start_after(token)
            [nil, 0, "\n", ";"].include?(token)
          end

          def update_block_context(token)
            case token
            when :keyword_def
              @context.push_scope(:method)
            when :keyword_do, :keyword_do_block
              @context.push_block(:do_block)
            when :keyword_do_LAMBDA
              @context.push_block(:lambda)
            when :tLAMBDA
              @context.push_scope(:lambda)
            when :tLAMBEG
              @context.push_block(:lambda)
            when "{", :tLBRACE_ARG
              @context.push_block(:brace_block)
            when "}"
              @context.pop_block if @context.block_stack.last == :brace_block
              @context.pop_scope if @context.scope_stack.last == :lambda
            when :keyword_end
              @context.pop_block if [:do_block, :lambda].include?(@context.block_stack.last)
              @context.pop_scope if [:method, :lambda].include?(@context.scope_stack.last)
            end
          end

          def identifier_token(start)
            while identifier_byte?(byte)
              advance
            end
            word = @source.byteslice(start, @index - start).force_encoding(Encoding::UTF_8)
            if byte == 63 && word == "defined"
              advance
              word = "defined?"
            end
            if [33, 63].include?(byte) && !identifier_byte?(byte(1)) && byte(1) != 61
              suffix = byte.chr
              advance
              return [:tFID, (word + suffix).to_sym]
            end
            if byte == 61 && byte(1) == 40 && [:keyword_def, ".", :tCOLON2].include?(@previous)
              advance
              return [:tFID, (word + "=").to_sym]
            end
            if byte == 61 && @previous == :tSYMBEG
              advance
              return [:tIDENTIFIER, (word + "=").to_sym]
            end
            if byte == 58 && byte(1) != 58
              advance
              return [:tLABEL, word.to_sym]
            end
            if word == "do" && !@context.condition_do && no_argument_block?
              return [:keyword_do, word.to_sym]
            end
            token = KEYWORDS[word]
            if token && [".", :tCOLON2, :tANDDOT].include?(@previous)
              token = :tFID
            elsif (!@context.begin_expression || [:keyword_return, :keyword_break, :keyword_next, :keyword_end, :keyword_yield, :keyword_super].include?(@previous)) && { "if" => :modifier_if, "unless" => :modifier_unless,
              "while" => :modifier_while, "until" => :modifier_until,
              "rescue" => :modifier_rescue }.key?(word)
              token = { "if" => :modifier_if, "unless" => :modifier_unless,
                "while" => :modifier_while, "until" => :modifier_until,
                "rescue" => :modifier_rescue }.fetch(word, token)
            end
            token ||= word == "do" ? do_token : (word.getbyte(0).between?(65, 90) ? :tCONSTANT : :tIDENTIFIER)
            if [:keyword_while, :keyword_until, :keyword_for].include?(token)
              @context.condition_do = true
              @context.push_condition
            end
            @context.alias_context = true if token == :keyword_alias
            [token, word.to_sym]
          rescue EncodingError
            fail!("invalid UTF-8 identifier", start)
          end

          def identifier_byte?(value)
            value && (value == 95 || value.between?(65, 90) || value.between?(97, 122) || value >= 128 || value.between?(48, 57))
          end

          def do_token
            if @context.condition_do && @context.condition?
              @context.pop_condition
              @context.condition_do = false
              :keyword_do_cond
            elsif @context.lambda_pending
              @context.lambda_pending = false
              :keyword_do_LAMBDA
            elsif @previous == ")"
              :keyword_do
            elsif @previous == :tLAMBDA
              :keyword_do_LAMBDA
            else
              :keyword_do_block
            end
          end

          def no_argument_block?
            return false unless [:tIDENTIFIER, :tCONSTANT, :tFID].include?(@previous)
            return false if @context.argument_label == :at && [".", :tCOLON2, :tANDDOT].include?(@previous_previous)
            return false if @context.token_history == ["+", :tINTEGER, ".", :tIDENTIFIER]
            return false if [:tIDENTIFIER, :tCONSTANT, :tFID].include?(@previous_previous)
            return false if [:tSYMBEG, :tLABEL, :tCOLON2].include?(@previous_previous)
            return false if [:tLSHFT, :tLAMBDA].include?(@previous_previous)
            true
          end

          def no_argument_brace_block?
            return false if [".", :tCOLON2].include?(@previous_previous)
            return false if [:tLABEL, :tLSHFT, :tOROP, :tANDOP, :tASSOC, "=", ","].include?(@previous_previous)
            no_argument_block?
          end

          def number_token(start)
            base = 10
            if byte == 48 && [120, 88, 98, 66, 111, 79].include?(byte(1))
              base = { 120 => 16, 88 => 16, 98 => 2, 66 => 2, 111 => 8, 79 => 8 }.fetch(byte(1))
              advance(2)
              digit_start = @index
              advance while digit_byte?(byte, base) || byte == 95
              fail!("invalid numeric literal", start) if @index == digit_start
              text = @source.byteslice(digit_start, @index - digit_start).delete("_")
              return [:tINTEGER, text.to_i(base)]
            end
            advance while digit_byte?(byte, 10) || byte == 95
            float = false
            if byte == 46 && digit_byte?(byte(1), 10)
              float = true
              advance
              advance while digit_byte?(byte, 10) || byte == 95
            end
            if byte == 101 || byte == 69
              float = true
              advance
              advance if byte == 43 || byte == 45
              fail!("invalid numeric literal", start) unless digit_byte?(byte, 10)
              advance while digit_byte?(byte, 10) || byte == 95
            end
            suffix = byte
            advance if [105, 114].include?(suffix)
            text = @source.byteslice(start, @index - start).delete("_")
            return [:tRATIONAL, Rational(text.delete_suffix("r"))] if suffix == 114
            return [:tIMAGINARY, Complex(0, text.delete_suffix("i").to_f)] if suffix == 105
            [float ? :tFLOAT : :tINTEGER, float ? text.to_f : text.to_i]
          rescue ArgumentError, ZeroDivisionError
            fail!("invalid numeric literal", start)
          end

          def digit_byte?(value, base)
            return false unless value
            value.between?(48, 57) && value - 48 < base || base == 16 && value.between?(65, 70) || base == 16 && value.between?(97, 102)
          end

          def variable_token(start)
            marker = byte
            advance
            advance if marker == 64 && byte == 64
            if marker == 36 && [33, 38, 39, 43, 60, 62, 61, 63, 96, 126].include?(byte)
              advance
              text = @source.byteslice(start, @index - start)
              return [:tGVAR, text.to_sym]
            end
            if marker == 36 && byte == 36
              advance
              return [:tGVAR, :"$$"]
            end
            if marker == 36 && byte && byte.between?(48, 57)
              advance while byte && byte.between?(48, 57)
              return [:tNTH_REF, @source.byteslice(start + 1, @index - start - 1).to_i]
            end
            advance while identifier_byte?(byte)
            text = @source.byteslice(start, @index - start)
            token = marker == 36 ? :tGVAR : (text.start_with?("@@") ? :tCVAR : :tIVAR)
            [token, text.to_sym]
          end

          def character_or_question(start)
            return operator_or_punctuation(start) unless @context.begin_expression && byte(1) && byte(1) != 32 && byte(1) != 10
            advance
            value = if byte == 92
              escape_sequence(start)
            else
              length = utf8_character_length(byte)
              character = @source.byteslice(@index, length).force_encoding(Encoding::UTF_8)
              advance(length)
              character
            end
            [:tCHAR, value]
          end

          def utf8_character_length(first_byte)
            return 1 if first_byte < 0x80
            return 2 if first_byte.between?(0xC2, 0xDF)
            return 3 if first_byte.between?(0xE0, 0xEF)
            return 4 if first_byte.between?(0xF0, 0xF4)
            fail!("invalid UTF-8 character")
          end

          def symbol_or_colon(start)
            symbol_position = @context.begin_expression || ([:tIDENTIFIER, :tFID].include?(@previous) && @context.ternary_depth.zero?)
            return operator_or_punctuation(start) unless symbol_position && byte(1) &&
              ![9, 10, 11, 12, 13, 32].include?(byte(1)) && byte(1) != 58
            advance
            if byte == 39 || byte == 34
              quote = byte
              advance
              @pending = read_interpolated_quoted(quote, start)
              @pending << [:tSTRING_END, nil]
            end
            [:tSYMBEG, nil]
          end

          def string_token(quote, start)
            advance
            content_tokens = read_interpolated_quoted(quote, start)
            label = byte == 58
            advance if label
            terminator = label ? :tLABEL_END : :tSTRING_END
            @pending = content_tokens
            @pending << [terminator, nil]
            [quote == 96 ? :tXSTRING_BEG : :tSTRING_BEG, nil]
          end

          def read_interpolated_quoted(quote, start)
            return [[:tSTRING_CONTENT, read_quoted(quote, interpolate: false, start: start)]] if quote == 39
            content = +""
            tokens = []
            until eof?
              value = byte
              if value == quote
                advance
                tokens << [:tSTRING_CONTENT, content] unless content.empty?
                return tokens
              elsif value == 92
                content << escape_sequence(start)
              elsif value == 35 && byte(1) == 123
                tokens << [:tSTRING_CONTENT, content] unless content.empty?
                content = +""
                advance(2)
                expression = read_interpolation_source(start)
                inner = self.class.new(expression, filename: @filename).each.to_a
                inner.pop if inner.last == [0, nil]
                tokens << [:tSTRING_DBEG, nil]
                tokens.concat(inner)
                tokens << [:tSTRING_DEND, nil]
              else
                content << value.chr
                advance
              end
            end
            fail!("unterminated literal", start)
          end

          def read_interpolation_source(start)
            begin_index = @index
            depth = 1
            quote = nil
            escaped = false
            while !eof?
              value = byte
              if quote
                if escaped
                  escaped = false
                elsif value == 92
                  escaped = true
                elsif value == quote
                  quote = nil
                end
              elsif [39, 34, 96].include?(value) && @source.getbyte(@index - 1) != 36
                quote = value
              elsif value == 123
                depth += 1
              elsif value == 125
                depth -= 1
                if depth.zero?
                  expression = @source.byteslice(begin_index, @index - begin_index)
                  advance
                  return expression.force_encoding(Encoding::UTF_8)
                end
              end
              advance
            end
            fail!("unterminated string interpolation", start)
          end

          def read_quoted(quote, interpolate:, start:)
            result = +""
            until eof?
              value = byte
              if value == quote
                advance
                return result
              elsif value == 92
                result << escape_sequence(start)
              elsif value == 35 && interpolate && byte(1) == 123
                fail!("string interpolation cannot be represented by the AST", start)
              else
                result << value
                advance
              end
            end
            fail!("unterminated literal", start)
          end

          def escape_sequence(start)
            advance
            fail!("unterminated escape", start) if eof?
            value = byte
            advance
            return "\n" if value == 110
            return "\t" if value == 116
            return "\r" if value == 114
            return "\f" if value == 102
            return "\a" if value == 97
            return "\e" if value == 101
            return value.chr if value == 92 || value == 34 || value == 39
            value.chr
          end

          def regexp_or_operator(start)
            return operator_or_punctuation(start) if @previous == :keyword_def
            return operator_or_punctuation(start) if @previous == :tSYMBEG
            if @context.begin_expression
              advance
              value = read_regexp(start)
              @pending = [[:tSTRING_CONTENT, value], [:tREGEXP_END, nil]]
              return [:tREGEXP_BEG, nil]
            end
            operator_or_punctuation(start)
          end

          def read_regexp(start)
            result = +""
            in_class = false
            until eof?
              value = byte
              if value == 92
                result << value.chr
                advance
                fail!("unterminated regexp", start) if eof?
                result << byte.chr
                advance
              elsif value == 91
                in_class = true
                result << value.chr
                advance
              elsif value == 93
                in_class = false
                result << value.chr
                advance
              elsif value == 47 && !in_class
                advance
                advance while byte && byte.between?(97, 122)
                return result
              else
                result << value.chr
                advance
              end
            end
            fail!("unterminated regexp", start)
          end

          def percent_token(start)
            literal_kind = [113, 81, 119, 87, 105, 73, 114, 115, 120, 88].include?(byte(1))
            command_argument = start.positive? && [9, 32].include?(@source.getbyte(start - 1)) &&
              [:tIDENTIFIER, :tCONSTANT, :tFID].include?(@previous) &&
              ![:tIDENTIFIER, :tCONSTANT, :tFID].include?(@previous_previous)
            shorthand_delimiter = byte(1) && !identifier_byte?(byte(1)) &&
              ![9, 10, 11, 12, 13, 32, 61].include?(byte(1))
            return operator_or_punctuation(start) unless @context.begin_expression ||
              ((literal_kind || shorthand_delimiter) && command_argument)
            advance
            kind = byte
            if [113, 81, 119, 87, 105, 73, 114, 115, 120, 88].include?(kind)
              advance
            else
              kind = 81
            end
            delimiter = byte
            fail!("invalid percent literal", start) unless delimiter
            advance
            closing = { 40 => 41, 91 => 93, 123 => 125, 60 => 62 }.fetch(delimiter, delimiter)
            interpolate = [81, 87, 73, 114, 120, 88].include?(kind)
            content = interpolate ?
              read_interpolated_delimited(closing, start) :
              read_delimited(closing, start, interpolate: interpolate)
            advance while kind == 114 && byte && byte.between?(97, 122)
            token = { 113 => :tSTRING_BEG, 81 => :tSTRING_BEG, 119 => :tWORDS_BEG, 87 => :tQWORDS_BEG,
                      105 => :tSYMBOLS_BEG, 73 => :tQSYMBOLS_BEG, 114 => :tREGEXP_BEG,
                      115 => :tSYMBEG, 120 => :tXSTRING_BEG, 88 => :tXSTRING_BEG }.fetch(kind)
            terminator = kind == 114 ? :tREGEXP_END : :tSTRING_END
            @pending = if [119, 87, 105, 73].include?(kind)
              content = content.map { |token, value| value.to_s }.join if content.is_a?(Array)
              word_tokens(content, symbols: [105, 73].include?(kind)) + [[terminator, nil]]
            elsif content.is_a?(Array)
              content + [[terminator, nil]]
            else
              [[:tSTRING_CONTENT, content], [terminator, nil]]
            end
            [token, nil]
          end

          def word_tokens(content, symbols:)
            words = content.split(/[\t\n\f\r ]+/).reject(&:empty?)
            tokens = [[" ", nil]]
            words.each do |word|
              tokens << [:tSTRING_CONTENT, symbols ? word.to_sym : word]
              tokens << [" ", nil]
            end
            tokens
          end

          def read_delimited(closing, start, interpolate: false)
            result = +""
            depth = 0
            until eof?
              value = byte
              if value == 92
                result << escape_sequence(start)
              elsif value == 35 && interpolate && byte(1) == 123
                fail!("string interpolation cannot be represented by the AST", start)
              elsif value == closing && depth.zero?
                advance
                return result
              else
                depth += 1 if value == ({ 41 => 40, 93 => 91, 125 => 123, 62 => 60 }.fetch(closing, -1))
                depth -= 1 if value == closing && depth.positive?
                result << value.chr
                advance
              end
            end
            fail!("unterminated percent literal", start)
          end

          def read_interpolated_delimited(closing, start)
            result = +""
            tokens = []
            depth = 0
            opening = { 41 => 40, 93 => 91, 125 => 123, 62 => 60 }.fetch(closing, -1)
            until eof?
              value = byte
              if value == 92
                result << escape_sequence(start)
              elsif value == 35 && byte(1) == 123
                tokens << [:tSTRING_CONTENT, result] unless result.empty?
                result = +""
                advance(2)
                expression = read_interpolation_source(start)
                inner = self.class.new(expression, filename: @filename).each.to_a
                inner.pop if inner.last == [0, nil]
                tokens << [:tSTRING_DBEG, nil]
                tokens.concat(inner)
                tokens << [:tSTRING_DEND, nil]
              elsif value == closing && depth.zero?
                advance
                tokens << [:tSTRING_CONTENT, result] unless result.empty?
                return tokens
              else
                depth += 1 if value == opening
                depth -= 1 if value == closing && depth.positive?
                result << value.chr
                advance
              end
            end
            fail!("unterminated percent literal", start)
          end

          def interpolated_content_tokens(source, start)
            return [[:tSTRING_CONTENT, source]] unless source.include?("#" + "{")
            tokens = []
            literal = +""
            index = 0
            while index < source.bytesize
              if source.getbyte(index) == 35 && source.getbyte(index + 1) == 123
                tokens << [:tSTRING_CONTENT, literal] unless literal.empty?
                depth = 1
                expr_start = index + 2
                index = expr_start
                while index < source.bytesize && depth.positive?
                  depth += 1 if source.getbyte(index) == 123
                  depth -= 1 if source.getbyte(index) == 125
                  index += 1
                end
                fail!("unterminated string interpolation", start) unless depth.zero?
                expression = source.byteslice(expr_start, index - expr_start - 1)
                inner = self.class.new(expression, filename: @filename).each.to_a
                inner.pop if inner.last == [0, nil]
                tokens << [:tSTRING_DBEG, nil]
                tokens.concat(inner)
                tokens << [:tSTRING_DEND, nil]
                literal = +""
              else
                literal << source.getbyte(index).chr
                index += 1
              end
            end
            tokens << [:tSTRING_CONTENT, literal] unless literal.empty?
            tokens
          end

          def heredoc_or_operator(start)
            if byte(1) == 60 && heredoc_prefix?
              return heredoc_token(start) if @context.begin_expression || @previous == :tIDENTIFIER
            end
            operator_or_punctuation(start)
          end

          def heredoc_prefix?
            value = byte(2)
            value && ([39, 34, 96, 45, 126].include?(value) || identifier_byte?(value))
          end

          def heredoc_token(start)
            advance(2)
            indent = byte == 45 || byte == 126
            squiggly = byte == 126
            advance if indent
            quote = byte
            if quote == 39 || quote == 34 || quote == 96
              advance
              delimiter_start = @index
              advance while byte && byte != quote
              fail!("unterminated heredoc identifier", start) if eof?
              delimiter = @source.byteslice(delimiter_start, @index - delimiter_start)
              advance
            else
              delimiter_start = @index
              advance while identifier_byte?(byte)
              delimiter = @source.byteslice(delimiter_start, @index - delimiter_start)
            end
            fail!("invalid heredoc identifier", start) if delimiter.empty?
            suffix_start = @index
            advance while byte && byte != 10
            suffix = @source.byteslice(suffix_start, @index - suffix_start).force_encoding(Encoding::UTF_8)
            advance if byte == 10
            body = +""
            interpolate = quote != 39
            loop do
              line_start = @index
              advance while !eof? && byte != 10
              line = @source.byteslice(line_start, @index - line_start)
              line_without_cr = line.delete_suffix("\r")
              terminator = indent ? line_without_cr.sub(/\A[ \t]*/, "") : line_without_cr
              if terminator == delimiter
                advance if byte == 10
                break
              end
              body << line << "\n"
              advance if byte == 10
              fail!("unterminated heredoc", start) if eof?
            end
            body = dedent_heredoc(body) if squiggly
            content_tokens = interpolate ? interpolated_content_tokens(body, start) : [[:tSTRING_CONTENT, body]]
            @pending = content_tokens + [[:tSTRING_END, nil]]
            unless suffix.empty?
              suffix_tokens = self.class.new(suffix, filename: @filename).each.to_a
              suffix_tokens.pop if suffix_tokens.last == [0, nil]
              @pending.concat(suffix_tokens)
            end
            @pending << ["\n", nil]
            [quote == 96 ? :tXSTRING_BEG : :tSTRING_BEG, nil]
          end

          def dedent_heredoc(body)
            indents = body.lines.filter_map do |line|
              next if line.strip.empty?
              line[/\A[ \t]*/].bytesize
            end
            return body if indents.empty?

            width = indents.min
            body.lines.map { |line| line.sub(/\A[ \t]{0,#{width}}/, "") }.join
          end

          def operator_or_punctuation(start)
            if @previous == :tSYMBEG && ["-@", "+@"].include?(@source.byteslice(@index, 2))
              value = @source.byteslice(@index, 2)
              advance(2)
              return [value == "-@" ? :tUMINUS : :tUPLUS, nil]
            end
            text = OPERATORS.sort_by { |operator| -operator.bytesize }.find do |operator|
              next false if operator == "[]" && start.positive? &&
                [9, 10, 11, 12, 13, 32].include?(@source.getbyte(start - 1)) &&
                @previous != :keyword_def
              @source.byteslice(@index, operator.bytesize) == operator
            end
            operator_method = [:keyword_def, ".", :tCOLON2, :tANDDOT, :tSYMBEG].include?(@previous)
            if text && !(begin_expression? && !operator_method && ["[]", "[]="].include?(text))
              advance(text.bytesize)
              token = if text == "**" && @context.begin_expression
                :tDSTAR
              elsif text == ".." && @context.begin_expression
                :tBDOT2
              elsif text == "..." && (@context.begin_expression || [:tLPAREN, "(", ","].include?(@previous))
                :tBDOT3
              elsif text == "::" && (@context.begin_expression || (start.positive? && [9, 32].include?(@source.getbyte(start - 1))))
                :tCOLON3
              else
                OP_TOKENS.fetch(text, :tOP_ASGN)
              end
              @context.lambda_pending = true if token == :tLAMBDA
              return [token, nil]
            end
            value = byte.chr
            if value == "{" && no_argument_brace_block?
              advance
              @pending.unshift([:tLBRACE_ARG, nil])
              return [:tAMPER, nil]
            end
            advance
            if value == "(" || value == "[" || value == "{"
              brace_block = value == "{" && ([:tIDENTIFIER, :tCONSTANT, :tFID].include?(@previous) ||
                @previous == ")" ||
                [".", :tCOLON2].include?(@previous_previous) || [:proc, :lambda].include?(@previous_value))
              lambda_block = value == "{" && @context.lambda_pending
              command_arg = value == "(" && !@context.begin_expression && start.positive? && [9, 32].include?(@source.getbyte(start - 1)) &&
                [:tIDENTIFIER, :tCONSTANT, :tFID].include?(@previous)
              unless brace_block || lambda_block
                @context.push_delimiter(value)
                @context.push_cmdarg(command_arg)
              end
              if value == "("
                if command_arg
                  return [:tLPAREN_ARG, nil]
                end
                return [@context.begin_expression && ![".", :tCOLON2, :tANDDOT, :keyword_super, :keyword_yield, :tLAMBDA, :tAREF].include?(@previous) ? :tLPAREN : "(", nil]
              end
              if value == "{" && @context.lambda_pending
                @context.lambda_pending = false
                return [:tLAMBEG, nil]
              end
              array_argument = value == "[" && start.positive? &&
                [9, 10, 11, 12, 13, 32].include?(@source.getbyte(start - 1)) &&
                [:tIDENTIFIER, :tFID, :tCONSTANT].include?(@previous)
              return [value == "[" && (@context.begin_expression || array_argument) ? :tLBRACK : (value == "[" ? "[" : (brace_block ? "{" : :tLBRACE)), nil]
            elsif value == ")" || value == "]" || value == "}"
              opener = { ")" => "(", "]" => "[", "}" => "{" }.fetch(value)
              @context.pop_delimiter(opener)
              @context.pop_cmdarg
            elsif value == "-" && @context.begin_expression
              return [:tUMINUS, nil]
            elsif value == "+" && @context.begin_expression
              return [:tUPLUS, nil]
            elsif value == "*" && @context.begin_expression
              return [:tSTAR, nil]
            elsif value == "&" && @previous == :tSYMBEG
              return [value, nil]
            elsif value == "&" && @context.begin_expression
              return [:tAMPER, nil]
            elsif value == "?" && !@context.begin_expression
              @context.ternary_depth += 1
            elsif value == ":" && @context.ternary_depth.positive?
              @context.ternary_depth -= 1
            elsif value == "<" && @previous == :tCONSTANT && @previous_previous == :keyword_class
              @class_superclass = true
            end
            [value, nil]
          rescue EncodingError
            fail!("invalid byte", start)
          end

          def begin_expression?
            @context.begin_expression
          end
        end
        private_constant :Lexer
      end
    end
  end
end

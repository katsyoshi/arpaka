# frozen_string_literal: true

require "strscan"

module Lrama
  module Ruby
    # A Ruby source lexer used for action boundary detection and references.
    # All positions are bytes in the original source; literals are never decoded.
    class ActionScanner
      Reference = Data.define(:name, :number, :first_column, :last_column, :short_interpolation)
      Result = Data.define(:end_offset, :references)
      Heredoc = Data.define(:delimiter, :indent, :interpolate, :offset)
      class Error < StandardError; end

      IDENTIFIER = /[a-zA-Z_\x80-\xff][a-zA-Z_0-9\x80-\xff]*[!?]?/n
      NUMBER = /(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|[0-9][0-9_]*(?:\.[0-9_]+)?(?:[eE][+-]?[0-9_]+)?)[ri]*/
      BEGIN_WORDS = %w[if unless while until when return yield break next rescue else elsif then do begin and or not in case for].freeze
      END_WORDS = %w[nil true false self end __FILE__ __LINE__ __ENCODING__].freeze
      PAIRS = { "(" => ")", "[" => "]", "{" => "}" }.freeze
      LITERAL_PAIRS = PAIRS.merge("<" => ">").freeze
      # Bound recursive interpolation rather than allowing SystemStackError.
      MAX_INTERPOLATION_DEPTH = 128

      def initialize(source, filename: "(grammar)", line: 1, column: 0)
        @source = source.b
        @scanner = StringScanner.new(@source)
        @filename, @line, @column = filename, line, column
        @references = []
        @interpolation_depth = 0
        @strict_references = false
      end

      def scan(action: false)
        @strict_references = action
        code(action ? "}" : nil)
        Result.new(@scanner.pos, @references.sort_by(&:first_column).freeze)
      end

      private

      def fail_at(message, offset = @scanner.pos)
        prefix = @source.byteslice(0, offset)
        lines = prefix.count("\n")
        column = lines.zero? ? @column + offset : offset - prefix.rindex("\n") - 1
        raise Error, "#{@filename}:#{@line + lines}:#{column}: #{message}"
      end

      def code(terminator)
        brackets = []
        heredocs = []
        state = :begin
        spaced = false
        until @scanner.eos?
          offset = @scanner.pos
          char = @scanner.peek(1)
          if @scanner.scan(/[ \t\r\f]+/)
            spaced = true
            next
          elsif @scanner.scan(/\\\r?\n/)
            spaced = true
            next
          elsif @scanner.scan(/\n/)
            heredocs.each { |item| heredoc_body(item) }
            heredocs.clear
            state = :begin unless [:begin, :method].include?(state)
            spaced = true
            next
          elsif char == "#"
            @scanner.scan(/[^\n]*/)
            next
          elsif (offset.zero? || @source.getbyte(offset - 1) == 10) && @scanner.check(/=begin(?=\s|\z)/)
            @scanner.scan(/[^\n]*(?:\n|\z)/)
            found = false
            until @scanner.eos?
              line = @scanner.scan(/[^\n]*(?:\n|\z)/)
              if /\A=end(?:\s|\z)/.match?(line)
                found = true
                break
              end
            end
            fail_at("Unterminated block comment", offset) unless found
            next
          elsif char == terminator && brackets.empty?
            fail_at("Close the action/interpolation after the heredoc body", offset) unless heredocs.empty?
            return
          elsif PAIRS.key?(char)
            brackets << [PAIRS.fetch(char), offset]
            @scanner.getch
            state = :begin
          elsif [")", "]", "}"].include?(char)
            fail_at("Mismatched closing #{char}", offset) unless brackets.last&.first == char
            brackets.pop
            @scanner.getch
            state = :end
          elsif ["'", '"', "`"].include?(char)
            @scanner.getch
            literal(char, interpolate: char != "'", offset: offset)
            state = :end
          elsif char == "$"
            reference
            state = :end
          elsif @scanner.scan(/@@?[a-zA-Z_\x80-\xff][a-zA-Z_0-9\x80-\xff]*/n)
            state = :end
          elsif @scanner.check(NUMBER)
            @scanner.scan(NUMBER)
            state = :end
          elsif @scanner.check(IDENTIFIER)
            word = @scanner.scan(IDENTIFIER)
            fail_at("__END__ is not supported in Ruby actions", offset) if word == "__END__"
            # Method names after dot/:: are not keywords.
            state = if state == :method
              :bare
            elsif BEGIN_WORDS.include?(word)
              :begin
            elsif END_WORDS.include?(word)
              :end
            else
              :bare
            end
          elsif char == "/" || char == "%" || @scanner.check(/<</)
            if state == :method
              @scanner.scan(/(?:<<|\/|%)/)
              state = :bare
            elsif state == :begin
              if char == "/"
                @scanner.getch
                literal("/", interpolate: true, regexp: true, offset: offset)
                @scanner.scan(/[a-z]*/)
              elsif char == "%"
                percent_literal(offset)
              else
                heredocs << heredoc_start(offset)
              end
              state = :end
            else
              @scanner.scan(/(?:<<|\/|%)=?/)
              state = :begin
            end
          elsif char == "?" && state == :begin
            @scanner.getch
            character(offset)
            state = :end
          elsif @scanner.scan(/&\.|::|\.(?!\.)/)
            state = :method
          elsif char == ":" && state == :begin
            @scanner.getch
            if @scanner.check(/['"]/)
              quote = @scanner.getch
              literal(quote, interpolate: quote != "'", offset: offset)
            elsif !@scanner.scan(/[@$]?[a-zA-Z_\x80-\xff][a-zA-Z_0-9\x80-\xff]*[!?]?/n) &&
              !@scanner.scan(/(?:\[\]=?|<=>|===|==|=~|!~|!=|<=|>=|<<|>>|\*\*|[+\-~]@?|[!*\/%&|^<>`])/)
              fail_at("Unsupported symbol literal", offset)
            end
            state = :end
          elsif @scanner.scan(/(?:\.\.\.?|->|\*\*=|&&=?|\|\|=?|<=>|===|==|=>|!=|!~|=~|<=|>=|>>=?|\*\*|[+\-*|&^]=|[=+\-*!,;:<>?~|&^])/)
            state = :begin
          else
            fail_at("Unsupported Ruby action token #{char.inspect}", offset)
          end
          spaced = false
        end
        fail_at("Unterminated heredoc", heredocs.first.offset) unless heredocs.empty?
        fail_at("Unclosed #{brackets.last.first}", brackets.last.last) unless brackets.empty?
        fail_at("Unterminated Ruby action/interpolation") if terminator
      end

      def reference(short: false)
        offset = @scanner.pos
        @global_variable_start = offset
        value = @scanner.scan(/\$(?:\$|[0-9]+|[a-zA-Z_][a-zA-Z0-9_]*)/)
        unless value
          return scan_global_variable unless @strict_references
          fail_at("Unsupported semantic reference", offset)
        end
        if value.match?(/\A\$0/) || @scanner.check(/[a-zA-Z_0-9\x80-\xff]/n)
          return scan_global_variable unless @strict_references
          fail_at("Unsupported semantic reference", offset)
        end
        number = value.match?(/\A\$[0-9]+\z/) ? value.delete_prefix("$").to_i : nil
        @references << Reference.new(number ? nil : value.delete_prefix("$"), number,
          offset, @scanner.pos, short)
      end

      def scan_global_variable
        @scanner.pos = @global_variable_start || @scanner.pos
        @scanner.scan(/\$(?:[<>]?|[!@&`'++~?=\/\\;,.:$-][a-zA-Z]?|[<>][^>\n]*>|[0-9]+|[a-zA-Z_][a-zA-Z0-9_]*)/)
        fail_at("Unsupported global variable", @scanner.pos) if @scanner.pos == (@global_variable_start || @scanner.pos)
      end

      def interpolation
        return false unless @scanner.peek(1) == "#"
        if @scanner.scan(/#\{/)
          @interpolation_depth += 1
          fail_at("Interpolation nesting exceeds #{MAX_INTERPOLATION_DEPTH}") if @interpolation_depth > MAX_INTERPOLATION_DEPTH
          code("}")
          @scanner.getch
          @interpolation_depth -= 1
        elsif @scanner.scan(/#(?=\$)/)
          reference(short: true)
        elsif @scanner.scan(/#@@?[a-zA-Z_\x80-\xff][a-zA-Z_0-9\x80-\xff]*/n)
          # Instance/class variable interpolation is preserved verbatim.
        else
          return false
        end
        true
      end

      def literal(close, interpolate:, offset:, open: nil, regexp: false)
        depth = 0
        until @scanner.eos?
          char = @scanner.peek(1)
          if char == "\\"
            @scanner.getch
            @scanner.getch || fail_at("Unterminated escape", offset)
          elsif interpolate && interpolation
            next
          elsif regexp && char == "["
            regexp_class(offset)
          elsif char == close
            @scanner.getch
            return if depth.zero?
            depth -= 1
          elsif open && char == open
            depth += 1
            @scanner.getch
          else
            @scanner.getch
          end
        end
        fail_at("Unterminated literal (expected #{close})", offset)
      end

      def regexp_class(offset)
        @scanner.getch
        @scanner.scan(/\^/)
        @scanner.scan(/\]/) # A leading ] is literal.
        until @scanner.eos?
          if @scanner.scan(/\\[\s\S]/)
            next
          elsif interpolation
            next
          elsif @scanner.scan(/\[:[^\]\n]*:\]/)
            next # POSIX character class inside a bracket expression.
          elsif @scanner.scan(/\]/)
            return
          else
            @scanner.getch
          end
        end
        fail_at("Unterminated regexp character class", offset)
      end

      def percent_literal(offset)
        @scanner.getch
        kind = @scanner.scan(/[qQwWiIrsx]/) || "Q"
        delimiter = @scanner.getch
        unless delimiter && /\A[!-~]\z/.match?(delimiter) && !/[a-zA-Z0-9\\]/.match?(delimiter)
          fail_at("Unsupported percent literal delimiter", offset)
        end
        literal(LITERAL_PAIRS.fetch(delimiter, delimiter), open: LITERAL_PAIRS.key?(delimiter) ? delimiter : nil,
          interpolate: !%w[q w i s].include?(kind), regexp: kind == "r", offset: offset)
        @scanner.scan(/[a-z]*/) if kind == "r"
      end

      def heredoc_start(offset)
        @scanner.scan(/<</)
        indent = !!@scanner.scan(/[-~]/)
        quote = @scanner.scan(/['"`]/)
        delimiter = if quote
          start = @scanner.pos
          @scanner.getch until @scanner.eos? || [quote, "\r", "\n"].include?(@scanner.peek(1))
          text = @source.byteslice(start, @scanner.pos - start)
          fail_at("Unterminated heredoc delimiter", offset) unless @scanner.getch == quote
          text
        else
          @scanner.scan(/[a-zA-Z_][a-zA-Z_0-9]*/)
        end
        fail_at("Unsupported heredoc delimiter", offset) unless delimiter && !delimiter.empty?
        Heredoc.new(delimiter, indent, quote != "'", offset)
      end

      def heredoc_body(item)
        until @scanner.eos?
          if @scanner.pos.zero? || @source.getbyte(@scanner.pos - 1) == 10
            start = @scanner.pos
            @scanner.scan(/[ \t]*/) if item.indent
            if @scanner.peek(item.delimiter.bytesize) == item.delimiter
              @scanner.pos += item.delimiter.bytesize
              return if @scanner.eos? || @scanner.scan(/\r?\n/)
            end
            @scanner.pos = start
          end
          if item.interpolate && interpolation
            next
          elsif item.interpolate && @scanner.scan(/\\[\s\S]/)
            next
          else
            @scanner.getch
          end
        end
        fail_at("Unterminated heredoc #{item.delimiter}", item.offset)
      end

      def character(offset)
        fail_at("Unterminated character literal", offset) if @scanner.eos? || @scanner.check(/\s/)
        if @scanner.scan(/\\/)
          if @scanner.scan(/u\{/)
            fail_at("Unterminated character escape", offset) unless @scanner.scan(/[0-9a-fA-F \t]+\}/)
          elsif @scanner.scan(/(?:[CM]-|c)/)
            character(offset)
          else
            @scanner.getch || fail_at("Unterminated character escape", offset)
          end
        else
          # Consume exactly one UTF-8 codepoint (or one ASCII byte).
          @scanner.scan(/(?:[\xc2-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3}|[\x00-\x7f])/n) ||
            fail_at("Unsupported character encoding", offset)
        end
      end
    end
  end
end

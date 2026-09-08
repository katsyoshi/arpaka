# frozen_string_literal: true

require_relative "../../ruby"

module Lrama
  module Ruby
    module Languages
      module Ruby
        class ParseError < ::Lrama::Ruby::Error
          attr_reader :token, :state

          def initialize(error)
            @token, @state = error.token, error.state
            super(error.message)
          end
        end

        class UnsupportedSyntax < ::Lrama::Ruby::Error
          attr_reader :rule, :line

          def initialize(rule, line)
            @rule, @line = rule, line
            super("Unsupported syntax: #{rule} (upstream parse.y:#{line})")
          end
        end

        PARSER_MUTEX = Mutex.new
        private_constant :PARSER_MUTEX

        def self.parse(tokens)
          parser_class = generated_parser
          parser = parser_class.new
          parser.instance_variable_set(:@builder, Builder.new)
          begin
            parser.parse(tokens)
          rescue parser_class::ParseError => error
            raise ParseError.new(error)
          end
        end

        def self.generated_parser
          PARSER_MUTEX.synchronize do
            @generated_parser ||= begin
              path = File.expand_path("ruby/parse.y", __dir__)
              ::Lrama::Ruby.compile(File.read(path), filename: path,
                class_name: "RubyParser", allow_error_rules: true)
            end
          end
        end
        private_class_method :generated_parser
      end
    end
  end
end

require_relative "ruby/ast"
require_relative "ruby/builder"

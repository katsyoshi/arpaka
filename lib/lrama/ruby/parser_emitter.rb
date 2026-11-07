# frozen_string_literal: true

require "erb"
require_relative "table_codec"

module Lrama
  module Ruby
    class ParserEmitter
      def emit(class_name:, context:, tokens:, actions:, recognizer:)
        template = File.read(File.expand_path("parser.rb.erb", __dir__))
        names = %i[yytranslate yypact yydefact yypgoto yydefgoto yytable yycheck yyr1 yyr2]
        literal_tables = names.to_h do |name|
          [name, "#{context.public_send(name).inspect}.freeze"]
        end
        candidates = names.to_h do |name|
          values = context.public_send(name)
          compressed = TableCodec.compress(values)
          encoded = "__decode_table(#{compressed.inspect}, #{values.length})"
          [name, encoded.bytesize < literal_tables.fetch(name).bytesize ? encoded : literal_tables.fetch(name)]
        end

        literal_source = render(template, class_name:, context:, tokens:, actions:, recognizer:,
          tables: literal_tables, compressed_tables: false)
        return literal_source unless candidates.values.any? { |expression| expression.start_with?("__decode_table(") }

        compressed_source = render(template, class_name:, context:, tokens:, actions:, recognizer:,
          tables: candidates, compressed_tables: true)
        compressed_source.bytesize < literal_source.bytesize ? compressed_source : literal_source
      end

      private

      def render(template, class_name:, context:, tokens:, actions:, recognizer:, tables:, compressed_tables:)
        ::ERB.new(template, trim_mode: "-").result_with_hash(
          class_name: class_name, context: context, tokens: tokens, actions: actions,
          recognizer: recognizer, tables: tables, compressed_tables: compressed_tables
        )
      end
    end
  end
end

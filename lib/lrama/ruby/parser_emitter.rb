# frozen_string_literal: true

require "erb"

module Lrama
  module Ruby
    class ParserEmitter
      def emit(class_name:, context:, tokens:, actions:, recognizer:)
        template = File.read(File.expand_path("parser.rb.erb", __dir__))
        ::ERB.new(template, trim_mode: "-").result_with_hash(
          class_name: class_name, context: context, tokens: tokens, actions: actions,
          recognizer: recognizer
        )
      end
    end
  end
end

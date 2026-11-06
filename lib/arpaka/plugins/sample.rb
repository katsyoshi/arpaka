# frozen_string_literal: true

require "lrama/ruby"

module Arpaka
  module Plugins
    module Sample
      def self.generate(grammar_path, class_name: "SampleParser")
        grammar = File.read(grammar_path)
        Lrama::Ruby.generate(grammar, filename: grammar_path, class_name: class_name)
      end
    end
  end
end

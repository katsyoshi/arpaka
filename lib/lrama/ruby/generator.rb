# frozen_string_literal: true

require "lrama"
require "prism"

module Lrama
  module Ruby
    class Generator
      def initialize
        unless ::Ruby::Box.enabled?
          raise Error, "Ruby Box is required. Start Ruby with RUBY_BOX=1."
        end

        @box = ::Ruby::Box.new
        # A new box does not inherit Bundler's activated load paths.
        @box.load_path.replace($LOAD_PATH)
        @box.require(File.expand_path("backend.rb", __dir__))
        @backend = @box::Lrama::Ruby::Backend.new
      end

      def generate(source, filename: "(grammar)", class_name: "Parser")
        unless /\A[A-Z][a-zA-Z0-9_]*\z/.match?(class_name)
          raise Error, "class_name must be a single Ruby constant name"
        end

        @backend.generate(source, filename: filename, class_name: class_name)
      rescue @box::Lrama::Ruby::Backend::Error => e
        raise Error, e.message
      end
    end
  end
end

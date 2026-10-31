# frozen_string_literal: true

require "lrama"

module Lrama
  module Ruby
    class Generator
      def initialize
        unless ::Ruby::Box.enabled?
          raise Error, "Ruby Box is required. Start Ruby with RUBY_BOX=1."
        end
      end

      def generate(source, filename: "(grammar)", class_name: "Parser", mode: :parser, allow_error_rules: false)
        unless /\A[A-Z][a-zA-Z0-9_]*\z/.match?(class_name)
          raise Error, "class_name must be a single Ruby constant name"
        end

        unless [:parser, :recognizer].include?(mode)
          raise Error, "mode must be :parser or :recognizer"
        end

        box = ::Ruby::Box.new
        # A new box does not inherit Bundler's activated load paths.
        box.load_path.replace($LOAD_PATH)
        box.require(File.expand_path("backend.rb", __dir__))
        box.require(File.expand_path("action_code.rb", __dir__)) if mode == :parser
        begin
          box::Lrama::Ruby::Backend.new.generate(source,
            filename: filename, class_name: class_name, mode: mode,
            allow_error_rules: allow_error_rules)
        rescue box::Lrama::Ruby::Backend::Error => e
          raise Error, e.message
        end
      end
    end
  end
end

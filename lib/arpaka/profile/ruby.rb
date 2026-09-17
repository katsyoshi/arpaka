# frozen_string_literal: true

require "json"

module Arpaka
  module Profile
    module RUBY
      CURRENT = {
        "name" => "ruby-4.0",
        "actions" => ::Arpaka::RubyGrammarActions::ACTIONS,
        "additional_expected_conflicts" => 0,
        "runtime" => {}.freeze
      }.freeze

      def self.select(grammar)
        if grammar.rules.any? { |rule| rule.lhs.id.s_value == "value_expr_command" }
          CURRENT
        elsif grammar.rules.any? { |rule| rule.lhs.id.s_value == "top_compstmt" }
          legacy
        else
          raise ::Arpaka::Error, "Unsupported Ruby parse.y profile"
        end
      end

      def self.legacy
        @legacy ||= begin
          box = ::Ruby::Box.new
          profile = box.eval(File.read(File.join(__dir__, "ruby_3_4.rb")))
          unless profile.is_a?(Hash) && profile["name"] == "ruby-3.4"
            raise ::Arpaka::Error, "Invalid Ruby 3.4 profile"
          end
          profile.freeze
        rescue SyntaxError, TypeError => error
          raise ::Arpaka::Error, "Ruby legacy profile loading failed: #{error.message}"
        end
      end
    end
  end
end

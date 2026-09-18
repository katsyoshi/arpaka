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
        elsif grammar.rules.any? { |rule| rule.lhs.id.s_value == "top_compstmt" &&
          rule.rhs.any? { |symbol| symbol.id.s_value == "option_terms" } }
          legacy
        elsif grammar.rules.any? { |rule| rule.lhs.id.s_value == "top_compstmt" &&
          rule.rhs.any? { |symbol| symbol.id.s_value == "opt_terms" } }
          legacy_3_3
        else
          raise ::Arpaka::Error, "Unsupported Ruby parse.y profile"
        end
      end

      def self.legacy
        @legacy ||= load("ruby_3_4.rb", "ruby-3.4")
      end

      def self.legacy_3_3
        @legacy_3_3 ||= load("ruby_3_3.rb", "ruby-3.3")
      end

      def self.load(filename, name)
        box = ::Ruby::Box.new
        profile = box.eval(File.read(File.join(__dir__, filename)))
        unless profile.is_a?(Hash) && profile["name"] == name
          raise ::Arpaka::Error, "Invalid #{name} profile"
        end
        profile.freeze
      rescue SyntaxError, TypeError => error
        raise ::Arpaka::Error, "Ruby profile loading failed: #{error.message}"
      end
    end
  end
end

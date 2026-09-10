# frozen_string_literal: true

require_relative "ruby/version"

module Lrama
  module Ruby
    class Error < StandardError; end

    def self.parse(tokens, language:)
      raise ArgumentError, "Unsupported language: #{language.inspect}" unless language == :ruby

      require_relative "ruby/languages/ruby"
      Languages::Ruby.parse(tokens)
    end

    def self.generate(source, filename: "(grammar)", class_name: "Parser", mode: :parser, allow_error_rules: false)
      Generator.new.generate(source, filename: filename, class_name: class_name,
        mode: mode, allow_error_rules: allow_error_rules)
    end

    def self.compile(source, filename: "(grammar)", class_name: "Parser", mode: :parser, allow_error_rules: false)
      code = generate(source, filename: filename, class_name: class_name,
        mode: mode, allow_error_rules: allow_error_rules)
      box = ::Ruby::Box.new
      begin
        box.eval(code)
      rescue SyntaxError => error
        raise Error, "Invalid generated Ruby for #{filename}: #{error.message}"
      end
      box.const_get(class_name, false)
    end
  end
end

require_relative "ruby/generator"

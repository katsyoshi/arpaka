# frozen_string_literal: true

require_relative "ruby/version"
require_relative "ruby/box_lifecycle"

module Lrama
  module Ruby
    class Error < StandardError; end

    def self.generate(source, filename: "(grammar)", class_name: "Parser", mode: :parser, allow_error_rules: false)
      Generator.new.generate(source, filename: filename, class_name: class_name,
        mode: mode, allow_error_rules: allow_error_rules)
    end

    def self.compile(source, filename: "(grammar)", class_name: "Parser", mode: :parser, allow_error_rules: false)
      code = generate(source, filename: filename, class_name: class_name,
        mode: mode, allow_error_rules: allow_error_rules)
      BoxLifecycle.with(:lrama_compile) do |box|
        BoxLifecycle.remove_constant(box, [class_name])
        begin
          box.eval(code)
        rescue SyntaxError => error
          raise Error, "Invalid generated Ruby for #{filename}: #{error.message}"
        end
        box.const_get(class_name, false)
      end
    end
  end
end

require_relative "ruby/generator"

Lrama::Ruby::BoxLifecycle.prepare(:lrama_backend_parser, :lrama_backend_recognizer,
  :lrama_compile) if ::Ruby::Box.enabled?

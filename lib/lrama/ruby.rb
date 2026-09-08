# frozen_string_literal: true

require_relative "ruby/version"

module Lrama
  module Ruby
    class Error < StandardError; end

    def self.generate(source, filename: "(grammar)", class_name: "Parser", mode: :parser)
      Generator.new.generate(source, filename: filename, class_name: class_name, mode: mode)
    end

    def self.compile(source, filename: "(grammar)", class_name: "Parser", mode: :parser)
      code = generate(source, filename: filename, class_name: class_name, mode: mode)
      box = ::Ruby::Box.new
      box.eval(code)
      box.const_get(class_name, false)
    end
  end
end

require_relative "ruby/generator"

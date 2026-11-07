# frozen_string_literal: true

require_relative "ruby/class_name_parser"

module Arpaka
  module Ruby
    def self.generate(ruby_source: nil, parse_y: nil, class_name: "RubyParser", ast_type: :detailed)
      Generator.new.generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name,
        ast_type: ast_type)
    end

    def self.compile(ruby_source: nil, parse_y: nil, class_name: "RubyParser", ast_type: :detailed)
      class_name = ClassNameParser.parse(class_name)
      source = generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name.to_s,
        ast_type: ast_type)
      box = ::Ruby::Box.new
      box.eval(source)
      class_name.resolve(box)
    end
  end
end

require_relative "ruby/generator"

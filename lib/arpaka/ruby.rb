# frozen_string_literal: true

require_relative "ruby/class_name_parser"

module Arpaka
  module Ruby
    def self.generate(ruby_source: nil, parse_y: nil, class_name: "RubyParser")
      Generator.new.generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name)
    end

    def self.compile(ruby_source: nil, parse_y: nil, class_name: "RubyParser")
      class_name = ClassNameParser.parse(class_name)
      source = generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name.to_s)
      box = ::Ruby::Box.new
      box.eval(source)
      class_name.resolve(box)
    end
  end
end

require_relative "ruby/generator"

# frozen_string_literal: true

require_relative "lrama/ruby"

module Arpaka
  class Error < Lrama::Ruby::Error; end

  def self.generate(ruby_source: nil, parse_y: nil, class_name: "RubyParser")
    Generator.new.generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name)
  end

  def self.compile(ruby_source: nil, parse_y: nil, class_name: "RubyParser")
    source = generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name)
    box = ::Ruby::Box.new
    box.eval(source)
    box.const_get(class_name, false)
  end
end

require_relative "arpaka/generator"

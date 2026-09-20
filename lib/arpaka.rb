# frozen_string_literal: true

require_relative "lrama/ruby"

module Arpaka
  class Error < Lrama::Ruby::Error; end

  require_relative "arpaka/ruby"

  def self.generate(ruby_source: nil, parse_y: nil, class_name: "RubyParser")
    Ruby.generate(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name)
  end

  def self.compile(ruby_source: nil, parse_y: nil, class_name: "RubyParser")
    Ruby.compile(ruby_source: ruby_source, parse_y: parse_y, class_name: class_name)
  end
end

# frozen_string_literal: true

require "test_helper"

RUBY_SOURCE = File.expand_path("../vendor/ruby", __dir__)
GeneratedRubyFrontend = Arpaka.compile(ruby_source: RUBY_SOURCE,
  class_name: "TestRubyFrontend")

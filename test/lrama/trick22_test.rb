# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class Trick22Test < Test::Unit::TestCase
  TRICK_ROOT = ENV["TRICK22_ROOT"]

  test "parses every trick22 Ruby file" do
    omit("set TRICK22_ROOT to run the external Trick 2022 corpus") unless TRICK_ROOT && Dir.exist?(TRICK_ROOT)

    files = Dir[File.join(TRICK_ROOT, "**", "*.rb")].sort

    assert_equal(12, files.length)
    files.each do |path|
      assert_nothing_raised("#{path}: generated frontend parses this file") do
        GeneratedRubyFrontend.parse(File.read(path), filename: path)
      end
    end
  end

  test "does not treat an operator method call as a heredoc" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("receiver.<<value\n") }
  end

  test "keeps receiver operators and local variable indexing in nested ternaries" do
    source = <<~'RUBY'
      r=[]
      h=""
      r["/ "] ? s.<<(h) : r ["/g"] ? (h[/:.+l/] = ?: "image/gif") : other
      (1..2).map { _1. /(383r) }
    RUBY

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end
end

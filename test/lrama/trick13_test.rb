# frozen_string_literal: true

require "test_helper"
require_relative "../generated_frontend_helper"

class Trick13Test < Test::Unit::TestCase
  TRICK_ROOT = ENV["TRICK13_ROOT"]

  test "parses every trick13 Ruby file" do
    omit("set TRICK13_ROOT to run the external Trick 2013 corpus") unless TRICK_ROOT && Dir.exist?(TRICK_ROOT)

    files = Dir[File.join(TRICK_ROOT, "**", "*.rb")].sort

    assert_equal(11, files.length)
    files.each do |path|
      assert_nothing_raised("#{path}: generated frontend parses this file") do
        GeneratedRubyFrontend.parse(File.read(path), filename: path)
      end
    end
  end

  test "recognizes a backtick as a symbol method name" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value < 1 and:`#\n") }
  end

  test "recognizes a method named do after a receiver" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("value.to.do(1)\n") }
  end

  test "accepts an attribute assignment without a method-name suffix" do
    assert_nothing_raised { GeneratedRubyFrontend.parse("cell.symbol=0\n") }
  end

  test "accepts a Unicode heredoc delimiter" do
    source = "value = <<−1.hex\nbody\n−1\n"

    assert_nothing_raised { GeneratedRubyFrontend.parse(source) }
  end
end

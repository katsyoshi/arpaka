# frozen_string_literal: true

require "test_helper"
require_relative "../fixtures/plugins/sample_plugin"
require "tmpdir"

class SamplePluginTest < Test::Unit::TestCase
  test "generates one parser from a grammar file" do
    Dir.mktmpdir do |directory|
      grammar_path = File.join(directory, "sample.y")
      File.write(grammar_path, "%token NUMBER\n%%\nstart: NUMBER;")

      source = SamplePlugin.generate(grammar_path, class_name: "SampleParser")
      box = Ruby::Box.new
      box.eval(source)
      parser = box.const_get(:SampleParser, false)

      assert_equal(7, parser.new.parse([[:NUMBER, 7]]))
    end
  end
end

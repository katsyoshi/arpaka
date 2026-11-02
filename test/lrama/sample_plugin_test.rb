# frozen_string_literal: true

require "test_helper"
require "arpaka/cli"
require_relative "../fixtures/plugins/sample_plugin"
require "tmpdir"
require "stringio"

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

  test "the sample command runs the plugin in a box and writes its output" do
    Dir.mktmpdir do |directory|
      grammar_path = File.join(directory, "sample.y")
      output_path = File.join(directory, "parser.rb")
      File.write(grammar_path, "%token NUMBER\n%%\nstart: NUMBER;")

      out = StringIO.new
      err = StringIO.new
      result = Arpaka::CLI.run(
        ["sample", "generate", "-y", grammar_path, "-c", "FooParser", "-o", output_path],
        out: out, err: err)

      assert_equal(0, result)
      assert_empty(err.string)
      assert_include(out.string, "Generated #{output_path}")
      assert_nil(defined?(Arpaka::Plugins::Sample))

      box = Ruby::Box.new
      box.eval(File.read(output_path))
      assert_equal(7, box.eval("FooParser.new.parse([[:NUMBER, 7]])"))
    end
  end
end

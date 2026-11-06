# frozen_string_literal: true

module Arpaka
  module Plugins
    class SampleRunner
      PLUGIN = File.expand_path("sample.rb", __dir__)

      def self.generate(grammar:, class_name:)
        unless ::Ruby::Box.enabled?
          raise ::Arpaka::Error, "Ruby Box is required for plugins. Start Ruby with RUBY_BOX=1."
        end

        box = ::Ruby::Box.new
        # A new box does not inherit Bundler's activated load paths.
        box.load_path.replace($LOAD_PATH)
        box.require(PLUGIN)
        box.eval("Arpaka::Plugins::Sample.generate(#{grammar.dump}, class_name: #{class_name.dump})")
      end
    end
  end
end

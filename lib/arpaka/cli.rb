# frozen_string_literal: true

require_relative "../arpaka"
require_relative "ruby/cli"
require_relative "plugins/cli"

module Arpaka
  class CLI
    def self.run(argv, out: $stdout, err: $stderr)
      return Plugins::CLI.run(argv.drop(1), out: out, err: err) if argv.first == "sample"

      Ruby::CLI.run(argv, out: out, err: err)
    end
  end
end

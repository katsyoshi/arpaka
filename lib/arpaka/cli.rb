# frozen_string_literal: true

require_relative "../arpaka"
require_relative "ruby/cli"

module Arpaka
  class CLI
    def self.run(argv, out: $stdout, err: $stderr)
      Ruby::CLI.run(argv, out: out, err: err)
    end
  end
end

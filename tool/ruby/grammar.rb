# frozen_string_literal: true

require_relative "../../lib/arpaka"
require_relative "../../lib/arpaka/cli"

source = ENV.fetch("RUBY_SOURCE", File.expand_path("../../vendor/ruby", __dir__))
if ARGV == ["--check"]
  Arpaka.generate(ruby_source: source)
  puts "Ruby grammar, Action mappings and standalone frontend verified"
else
  exit Arpaka::CLI.run(["generate", "--ruby-source", source, *ARGV])
end

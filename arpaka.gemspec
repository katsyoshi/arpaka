# frozen_string_literal: true

require_relative "lib/lrama/ruby/version"

Gem::Specification.new do |spec|
  spec.name = "arpaka"
  spec.version = Lrama::Ruby::VERSION
  spec.authors = ["MATSUMOTO, Katsuyoshi"]
  spec.email = ["github@katsyoshi.org"]

  spec.summary = "Ruby language parser frontend and Lrama output backend"
  spec.description = "A Ruby parser frontend and Ruby output backend for Lrama."
  spec.homepage = "https://github.com/katsyoshi/arpaka"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["homepage_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ tool/ vendor/]) ||
        %w[AGENTS.md DESIGN.md plan.md].include?(f)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lrama", ">= 0.8.0"
end

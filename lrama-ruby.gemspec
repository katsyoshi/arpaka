# frozen_string_literal: true

require_relative "lib/lrama/ruby/version"

Gem::Specification.new do |spec|
  spec.name = "lrama-ruby"
  spec.version = Lrama::Ruby::VERSION
  spec.authors = ["MATSUMOTO, Katsuyoshi"]
  spec.email = ["github@katsyoshi.org"]

  spec.summary = "Lrama output target for Ruby"
  spec.description = "https://github.com/katsyoshi/lrama-ruby"
  spec.homepage = "https://github.com/katsyoshi/lrama-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["homepage_uri"] = spec.homepage

  # Uncomment the line below to require MFA for gem pushes.
  # This helps protect your gem from supply chain attacks by ensuring
  # no one can publish a new version without multi-factor authentication.
  # See: https://guides.rubygems.org/mfa-requirement-opt-in/
  # spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
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

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "lrama", ">= 0.8.0"
  spec.add_dependency "prism", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://guides.rubygems.org/make-your-own-gem/
end

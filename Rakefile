# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :ruby do
  desc "Generate a standalone Ruby frontend (requires OUTPUT; optional RUBY_SOURCE)"
  task :generate do
    abort "Set OUTPUT to the destination Ruby file" unless ENV["OUTPUT"]
    ruby "tool/ruby/grammar.rb", "--output", ENV.fetch("OUTPUT")
  end

  desc "Verify the Ruby source profile, Action mappings and generated frontend"
  task :check do
    ruby "tool/ruby/grammar.rb", "--check"
  end
end

namespace :package do
  desc "Verify installed frontend generation and standalone execution"
  task :check do
    ruby "tool/check_package.rb"
  end
end

task default: ["ruby:check", :test, "package:check"]

namespace :benchmark do
  desc "Benchmark Ruby source and token parsing"
  task :parse do
    ruby "benchmark/parse.rb"
  end
end

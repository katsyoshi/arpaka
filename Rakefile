# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :ruby do
  desc "Regenerate the bundled Ruby grammar and action metadata"
  task :generate do
    ruby "tool/ruby/grammar.rb"
  end

  desc "Verify the bundled Ruby grammar against the pinned upstream source"
  task :check do
    ruby "tool/ruby/grammar.rb", "--check"
  end
end

namespace :package do
  desc "Build and install a local gem and verify its bundled language runtime"
  task :check do
    ruby "tool/check_package.rb"
  end
end

task default: ["ruby:check", :test, "package:check"]

# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"

root = File.expand_path("..", __dir__)
isolate = ARGV.include?("--isolate")
run = lambda do |env, *command, **options|
  output, error, result = Open3.capture3(env, *command, **options)
  raise "#{command.first} failed:\n#{output}\n#{error}" unless result.success?
  output
end

# Include untracked implementation files so packaging can be checked before
# staging a commit. The isolated checkout exercises the real git-based gemspec.
files = run.call({}, "git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", chdir: root).split("\0")
Dir.mktmpdir("lrama-ruby-package-") do |directory|
  checkout = File.join(directory, "source")
  install = File.join(directory, "installed")
  FileUtils.mkdir_p([checkout, install])
  files.each do |file|
    source = File.join(root, file)
    next unless File.file?(source)
    target = File.join(checkout, file)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(source, target)
  end
  run.call({}, "git", "init", "-q", chdir: checkout)
  run.call({}, "git", "add", ".", chdir: checkout)
  env = { "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLE_GEMFILE" => nil,
    "BUNDLE_BIN_PATH" => nil, "RUBY_BOX" => "1" }
  run.call(env, RbConfig.ruby, "-S", "gem", "build", "lrama-ruby.gemspec", chdir: checkout)
  gem_file = Dir.glob(File.join(checkout, "*.gem")).fetch(0)
  run.call(env, RbConfig.ruby, "-S", "gem", "install", "--local", "--ignore-dependencies",
    "--no-document", "--install-dir", install, gem_file, chdir: directory)
  env["GEM_HOME"] = install
  env["GEM_PATH"] = ([install] + Gem.path).join(File::PATH_SEPARATOR)
  script = <<~'RUBY'
    require "lrama/ruby"
    spec = Gem.loaded_specs.fetch("lrama-ruby")
    forbidden = spec.files.select { |file| file.start_with?("vendor/", "tool/", "test/") || %w[plan.md DESIGN.md AGENTS.md].include?(file) }
    abort "Development files packaged: #{forbidden.inspect}" unless forbidden.empty?
    %w[parse.y rules.json COPYING BSDL].each do |file|
      abort "Missing #{file}" unless File.file?(File.join(spec.full_gem_path, "lib/lrama/ruby/languages/ruby", file))
    end
    tree = Lrama::Ruby.parse([[:tIDENTIFIER, :a], ["=", nil], [:tINTEGER, 1]], language: :ruby)
    node = tree.statements.fetch(0)
    abort "Wrong packaged AST" unless node.name == :a && node.value.value == 1
    puts "Packaged gem: first AST parse OK"
  RUBY
  command = [RbConfig.ruby, "-e", script]
  if isolate
    # Linux verification: all persistent files read-only, source checkouts hidden,
    # and no network namespace connectivity. No writable /tmp is provided.
    command = ["bwrap", "--unshare-net", "--ro-bind", "/", "/", "--dev", "/dev", "--proc", "/proc",
      "--tmpfs", root, "--tmpfs", checkout, "--chdir", install, *command]
  end
  puts run.call(env, *command, chdir: install)
end

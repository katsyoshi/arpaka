# frozen_string_literal: true

# Local-only health snapshot for the Rails checkout. This intentionally uses
# RubyVM::AbstractSyntaxTree as an oracle; it is not part of Arpaka's runtime.

require "json"
require "lrama/ruby/action_scanner"

rails = ARGV[0] || [
  File.expand_path("~/Program/Github/rails"),
  File.expand_path("~/Program/Ruby/rails")
].find { |path| File.directory?(path) }
abort "Rails checkout not found" unless rails

files = Dir.glob(File.join(rails, "**/*.rb"), File::FNM_EXTGLOB).sort
snapshot = {
  "rails" => rails,
  "files" => files.length,
  "scanner_failures" => [],
  "ast_failures" => [],
  "scanner_successes" => 0,
  "ast_successes" => 0
}

files.each do |path|
  source = File.binread(path)
  relative = path.delete_prefix("#{rails}/")

  begin
    Lrama::Ruby::ActionScanner.new(source, filename: relative).scan
    snapshot["scanner_successes"] += 1
  rescue Lrama::Ruby::ActionScanner::Error => error
    snapshot["scanner_failures"] << {"file" => relative, "error" => error.message}
  end

  begin
    RubyVM::AbstractSyntaxTree.parse(source)
    snapshot["ast_successes"] += 1
  rescue SyntaxError => error
    snapshot["ast_failures"] << {"file" => relative, "error" => error.message.lines.first&.chomp}
  end
end

puts JSON.pretty_generate(snapshot)

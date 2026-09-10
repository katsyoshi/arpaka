# Repository guide

## Project status

`arpaka` is a Ruby language parser frontend and an output backend for Lrama.
Keep implementation decisions aligned with both roles. The frontend is exposed
as `Arpaka`; the generic Ruby parser generator remains under `Lrama::Ruby`.

The initial backend generates standalone Ruby parsers from Lrama's LALR/IELR
tables. `Lrama::Ruby.generate` returns source; `Lrama::Ruby.compile` returns a
parser class loaded in its own Ruby Box. See README for supported grammar features.
Ruby >= 4.0.0 is required. CI runs Ruby 4.0 and head.
Generation uses Ruby Box to isolate Ruby-specific extensions to Lrama; start Ruby
with `RUBY_BOX=1`. Prism handles Ruby action tokens and generated syntax validation.
Whether to provide a fallback for Ruby
3.4 and earlier will be decided during implementation; compatibility with those
versions is not currently promised.

## Layout

- `lib/lrama/ruby.rb`: library entry point.
- `lib/lrama/ruby/`: implementation files and `version.rb`.
- `lib/lrama/ruby/parser.rb.erb`: standalone parser template.
- `lib/lrama/ruby/backend.rb` and `action_code.rb`: internal files loaded in the generator's box.
- `examples/calculator.y`: executable example grammar.
- `lib/lrama/ruby/languages/ruby/`: bundled grammar, AST, builder and runtime metadata.
- `tool/ruby/`: grammar adapter, action definitions and original rule inventory.
- `vendor/ruby/`: pinned upstream grammar, preprocessing tools and license files.
- `sig/lrama/ruby.rbs`: RBS declarations.
- `test/lrama/*_test.rb`: Test::Unit tests; `test/test_helper.rb` loads the library.
- `arpaka.gemspec`: gem metadata and runtime dependencies.
- `Gemfile`: development dependencies.
- `.github/workflows/main.yml`: CI runs `bundle exec rake` with `RUBY_BOX=1`.

## Development commands

- `bin/setup`: install dependencies with Bundler.
- `RUBY_BOX=1 bundle exec rake test`: run the test suite.
- `RUBY_BOX=1 bundle exec rake`: verify the bundled grammar and run the test suite.
- `bundle exec rake ruby:generate`: regenerate bundled grammar and metadata after action changes.
- `bundle exec rake ruby:check`: verify source checksums, rule mappings and generated artifacts without editing them.
- `RUBY_BOX=1 bundle exec ruby -Itest test/lrama/ruby_test.rb`: run one test file.
- `RUBY_BOX=1 bin/console`: open an interactive Ruby session with the library loaded.

## Conventions

Follow the existing Ruby style: two-space indentation, double-quoted strings,
snake_case filenames and methods, and `# frozen_string_literal: true` in Ruby
source files. Keep library code under `Lrama::Ruby`. Add relevant Test::Unit
coverage for behavior changes and maintain RBS declarations when changing the
public API. No formatter or linter is configured.

## Packaging and release

Keep `Gemfile.lock` untracked; it is ignored intentionally.
The gemspec packages Git-tracked files, so review package contents when adding
repository documentation or tooling files.
Runtime language grammars and licenses must be packaged; `vendor/`, `tool/`
and local design/plan documents are excluded. Parsing must work without these
development files and without filesystem writes. The Ruby grammar is generated
and cached in memory on first use, with a fresh builder per parse.

`bundle exec rake release` creates tags, pushes to Git, and publishes a gem.
Run it only when a release is explicitly requested.

# Repository guide

## Project status

`arpaka` is a Ruby language parser frontend and an output backend for Lrama.
Keep implementation decisions aligned with both roles. Arpaka generates a
standalone Ruby frontend from a user-supplied Ruby source
tree; the generic Ruby parser generator remains under `Lrama::Ruby`.

The initial backend generates standalone Ruby parsers from Lrama's LALR/IELR
tables. `Lrama::Ruby.generate` returns source; `Lrama::Ruby.compile` returns a
parser class loaded in its own Ruby Box. See README for supported grammar features.
Ruby >= 4.0.0 is required. CI runs Ruby 4.0 and head.
Generation uses Ruby Box to isolate Ruby-specific extensions to Lrama; start Ruby
with `RUBY_BOX=1`. A Ruby action scanner handles action tokens. Generated frontend
code is validated
in an isolated Ruby Box.
Whether to provide a fallback for Ruby
3.4 and earlier will be decided during implementation; compatibility with those
versions is not currently promised.

## Layout

- `lib/lrama/ruby.rb`: library entry point.
- `lib/lrama/ruby/`: implementation files and `version.rb`.
- `lib/lrama/ruby/parser.rb.erb`: standalone parser template.
- `lib/lrama/ruby/backend.rb` and `action_code.rb`: internal files loaded in the generator's box.
- `examples/calculator.y`: executable example grammar.
- `lib/arpaka/`: public frontend entry points and compatibility CLI.
- `lib/arpaka/ruby/`: Ruby frontend generator, CLI, source profiles, Action mappings and runtime templates.
- `exe/arpaka`: installed generation command.
- `tool/ruby/`: development entry point for frontend generation and checks.
- `vendor/ruby/`: pinned upstream grammar, preprocessing tools and license files.
- `sig/lrama/ruby.rbs`: RBS declarations.
- `test/lrama/*_test.rb`: Test::Unit tests; `test/test_helper.rb` loads the library.
- `arpaka.gemspec`: gem metadata and runtime dependencies.
- `Gemfile`: development dependencies.
- `.github/workflows/main.yml`: CI runs `bundle exec rake` with `RUBY_BOX=1`.

## Development commands

- `bin/setup`: install dependencies with Bundler.
- `RUBY_BOX=1 bundle exec rake test`: run the test suite.
- `RUBY_BOX=1 bundle exec rake`: verify generation, tests and installed packaging.
- `RUBY_BOX=1 OUTPUT=/path/to/frontend.rb bundle exec rake ruby:generate`: generate a standalone frontend.
- `RUBY_BOX=1 bundle exec rake ruby:check`: verify source checksums, rule mappings and frontend generation without editing artifacts.
- `RUBY_BOX=1 bundle exec ruby -Itest test/lrama/ruby_test.rb`: run one test file.
- `RUBY_BOX=1 bin/console`: open an interactive Ruby session with the library loaded.

## Conventions

Follow the existing Ruby style: two-space indentation, double-quoted strings,
snake_case filenames and methods, and `# frozen_string_literal: true` in Ruby
source files. Keep generic backend code under `Lrama::Ruby` and frontend
generation under `Arpaka`. Add relevant Test::Unit
coverage for behavior changes and maintain RBS declarations when changing the
public API. No formatter or linter is configured.

## Packaging and release

Keep `Gemfile.lock` untracked; it is ignored intentionally.
The gemspec packages Git-tracked files, so review package contents when adding
repository documentation or tooling files.
The gem packages frontend generation templates, Action mappings, source profiles
and notices, but no Ruby parse.y or generated Ruby frontend. `vendor/`, `tool/`
and local design/plan documents are excluded. The generated single Ruby file must
parse without Arpaka/Lrama gems, Ruby Box, auxiliary files or filesystem writes.
Embed required metadata and license notices; create fresh state per parse.
The user supplies Ruby sources to `Arpaka.generate` or `Arpaka.compile`; the
returned frontend exposes `.parse(source, filename:)` to obtain its AST.

`bundle exec rake release` creates tags, pushes to Git, and publishes a gem.
Run it only when a release is explicitly requested.

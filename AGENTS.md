# Repository guide

## Project status

`lrama-ruby` is a backend for Lrama that generates Ruby parser code. Its purpose
is to support Ruby as an output language for Lrama. Keep implementation decisions
aligned with this backend role.

The project currently has a Ruby gem scaffold using the `Lrama::Ruby` namespace.
The entry point defines an error class and loads the version; the Ruby code
generation backend is not implemented yet.
Ruby >= 4.0.0 is required. CI currently runs Ruby 4.0.6.
The implementation will use Ruby Box. Whether to provide a fallback for Ruby
3.4 and earlier will be decided during implementation; compatibility with those
versions is not currently promised.

## Layout

- `lib/lrama/ruby.rb`: library entry point.
- `lib/lrama/ruby/`: implementation files and `version.rb`.
- `sig/lrama/ruby.rbs`: RBS declarations.
- `test/lrama/*_test.rb`: Test::Unit tests; `test/test_helper.rb` loads the library.
- `lrama-ruby.gemspec`: gem metadata and runtime dependencies.
- `Gemfile`: development dependencies.
- `.github/workflows/main.yml`: CI runs `bundle exec rake`.

## Development commands

- `bin/setup`: install dependencies with Bundler.
- `bundle exec rake test`: run the test suite.
- `bundle exec rake`: run the default task, also the test suite.
- `bundle exec ruby -Itest test/lrama/ruby_test.rb`: run one test file.
- `bin/console`: open an interactive Ruby session with the library loaded.

## Conventions

Follow the existing Ruby style: two-space indentation, double-quoted strings,
snake_case filenames and methods, and `# frozen_string_literal: true` in Ruby
source files. Keep library code under `Lrama::Ruby`. Add relevant Test::Unit
coverage for behavior changes and maintain RBS declarations when changing the
public API. No formatter or linter is configured.

## Known scaffold limitations

The initial suite has two tests and one failure: `test "something useful"`
compares `"expected"` with `"actual"`. Replace this placeholder when adding
real behavior; do not treat it as a new regression.

README installation and usage text and gemspec metadata still contain TODOs.
Resolve these with verified project details before packaging or publishing.
The gemspec packages Git-tracked files, so review package contents when adding
repository documentation or tooling files.

`bundle exec rake release` creates tags, pushes to Git, and publishes a gem.
Run it only when a release is explicitly requested.

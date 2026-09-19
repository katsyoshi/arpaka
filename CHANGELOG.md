## [Unreleased]

## [1.0.0] - 2026-09-19

- Added frontend generation directly from a Ruby `parse.y` file.
- Added source profiles for the Ruby 3.3 and Ruby 3.4 grammars.
- Loaded Ruby's canonical token definitions from `defs/id.def` when generating
  frontends from a Ruby source tree.
- Made generated runtime extensions depend on the selected source profile.

## [0.1.1] - 2026-09-15

- Changed Ruby source profile mismatches and unknown Action IDs from generation
  errors to warnings.

## [0.1.0] - 2026-09-15

- Initial release of the `Lrama::Ruby` backend for generating standalone Ruby
  parsers from Lrama grammars.
- Added `Arpaka` frontend generation from a pinned Ruby source tree, including
  its standalone lexer, AST, builder and Action mappings.
- Added parser compilation in isolated Ruby Boxes, recognizer generation and
  support for retaining error productions.
- Added a Ruby action scanner and compatibility coverage using Rails and Ruby
  Trick programs.

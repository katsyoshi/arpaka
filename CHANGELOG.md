## [Unreleased]

## [2.0.0]

- Added optional structured AST output for lexical class, module, instance
  method and singleton method definitions, with source-order nesting and
  separate occurrences for reopened classes and modules.
- Supported namespaced generated frontend class names through the API and CLI.
- Improved Ruby AST compatibility for method parameters, local scopes, pattern
  matching, splats, interpolation, control flow and command calls.
- Added a usage guide and an AST comparison benchmark that separates parse
  success from AST agreement and records unsupported comparisons explicitly.
  Added optional Ractor checks and a `--disable-gc` switch for experiments.
- Reduced the pinned grammar's generated standalone frontend from about 450 KB
  to about 190 KB by compressing parser tables and omitting unused rule data.
- Refactored Ruby parser and frontend generation into focused internal
  components without changing the default detailed AST output.
- Preserved Ruby 3.3 unsupported-rule metadata in generated frontends.
- Fixed quote-specific escapes, escaped word boundaries and percent-regexp
  delimiter escapes in generated Ruby frontends. Interpolated `%W` and `%I`
  now fail explicitly instead of silently losing their interpolation.
- Temporarily represent keyword arguments with Hash-shaped AST nodes while
  RubyVM::AbstractSyntaxTree is used as the comparison oracle. This
  representation may later be split into dedicated keyword-argument nodes as
  Arpaka's semantic AST becomes the canonical model.

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

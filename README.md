# Arpaka

<p align="center">
  <img src="assets/arpaka-logo.svg" alt="Arpaka" width="720">
</p>

<p align="center">
  Generate Ruby parsers with Lrama, and use their ASTs from Ruby.
</p>

Arpaka provides a Ruby output backend for
[Lrama](https://github.com/ruby/lrama) and a tool for generating a Ruby language
frontend. Its goal is to make Ruby syntax accessible as an AST from Ruby code.

`Lrama::Ruby` turns Yacc-style grammars with Ruby semantic actions into
standalone Ruby parsers using Lrama's LALR/IELR tables. Arpaka applies its Ruby
Action mappings to a Ruby source tree supplied by the user and emits a single
Ruby file containing the parser, lexer, AST and builder. Users choose the output
location and regenerate when updating the grammar or Actions.

The Ruby frontend is experimental and partial. The gem contains generation
support, not a bundled `parse.y` or a pre-generated Ruby frontend.

## Requirements

Ruby 4.0 or later. Start the generator with `RUBY_BOX=1`: Ruby Box isolates the
Ruby-specific extensions to Lrama. `Lrama::Ruby.compile` also loads each generated
parser in a separate box, so parsers with the same class name can coexist.

Generated `.rb` files have no gem dependencies and can also be required normally
without Ruby Box. Support for Ruby 3.4 and earlier remains undecided.

## Installation

For local development:

```sh
bin/setup
```

To use this unreleased gem from another application's Gemfile:

```ruby
gem "arpaka", git: "https://github.com/katsyoshi/arpaka"
```

## Usage

Write a Yacc-style grammar with Ruby actions, such as
[examples/calculator.y](examples/calculator.y):

```yacc
%token NUMBER
%left '+'
%left '*'
%%
expression: NUMBER
          | expression '+' expression { $$ = $1 + $3 }
          | expression '*' expression { $$ = $1 * $3 }
          ;
```

Run the following Ruby code with `RUBY_BOX=1 bundle exec ruby your_script.rb`:

```ruby
require "arpaka"

path = "examples/calculator.y"
grammar = File.read(path)
parser_class = Lrama::Ruby.compile(grammar, filename: path, class_name: "Calculator")
parser = parser_class.new
p parser.parse([[:NUMBER, 2], ["+", nil], [:NUMBER, 3], ["*", nil], [:NUMBER, 4]])
# => 14

# Generate source without executing its semantic actions.
File.write("calculator.rb",
  Lrama::Ruby.generate(grammar, filename: path, class_name: "Calculator"))
```

`class_name` defaults to `Parser` and must be a single Ruby constant name.
The generated class exposes `parse(tokens)`. Supply an enumerable of
`[token, value]` pairs; tokens may be names (symbols or strings), string aliases,
character literals such as `"+"`, or numeric token IDs. `TOKENS` maps names to IDs.
Exhausting the enumerable signals EOF; `[0, nil]` also signals EOF explicitly.
Provide your own tokenizer to convert source text into these pairs.

`$$` is the result of an action. `$1`, `$2`, etc. refer to values on the rule's
right-hand side; named references such as `$left` and midrule actions are also
supported. An omitted action returns the first value, or `nil` for an empty rule.
Strings, comments, regular expressions and Ruby instance variables are preserved.
Dollar-prefixed names in executable action code are reserved for grammar
references, including inside Ruby interpolation. Typed references, bracketed
references, `$0`, and special Ruby globals are not supported.

Unexpected input raises the generated class's `ParseError`, exposing `token` and
`state`. Exceptions from token enumeration and semantic actions propagate to the
caller. There is no error recovery yet.

`allow_error_rules: true` permits grammars containing the reserved `error`
symbol without enabling error recovery. The default is `false`. With either
setting the parser stops at the first syntax error; supplying the reserved
error token from a lexer is rejected. This option is useful when incrementally
porting a grammar whose recovery rules must remain present.

### Building an AST

[examples/calculator_ast.y](examples/calculator_ast.y) uses Ruby actions to
build an abstract syntax tree instead of evaluating arithmetic. This example
represents a number as `[:number, value]` and a binary operation as
`[:binary, operator, left, right]`. The grammar defines this AST format;
the backend does not impose a node type.

```ruby
path = "examples/calculator_ast.y"
parser = Lrama::Ruby.compile(File.read(path), filename: path,
  class_name: "CalculatorAst").new

tree = parser.parse([[:NUMBER, 2], ["+", nil], [:NUMBER, 3], ["*", nil], [:NUMBER, 4]])
p tree
# => [:binary, :+, [:number, 2], [:binary, :*, [:number, 3], [:number, 4]]]
```

Run this after requiring `arpaka`, with `RUBY_BOX=1`. Supply tokens from
your own lexer, or pass a token array as above. The default parser mode runs
the actions and returns the root node. Precedence and associativity determine
the tree's shape. Parentheses affect grouping but are omitted from the AST by
the action `$$ = $2`. Evaluation or compilation of the resulting tree belongs
to the application; even `1 / 0` produces a tree without performing division.

### Generating a Ruby frontend

Provide a Ruby source tree containing `parse.y`, `tool/id2token.rb`,
`defs/id.def`, `COPYING` and `BSDL`. Arpaka does not download Ruby sources.
The first supported source profile is ruby/ruby revision
`37d60dd3241d5fdb10ca43f36077f5d556ae1b8d`; other revisions are not automatically
supported. Input checksums and expanded rule mappings are checked before
applying Actions. Changed input files are reported and generation stops.
Even comment-only changes currently require updating the source profile.

```sh
RUBY_BOX=1 bundle exec arpaka generate \
  --ruby-source /path/to/ruby \
  --class-name MyRubyParser \
  --output lib/my_library/ruby_parser.rb
```

The output directory must already exist. `--class-name` defaults to
`RubyParser` and must be a single Ruby constant name. Existing output files are
preserved unless `--force` is supplied. A failed generation leaves the previous
file intact. The output includes its source profile, generator version and
copyright/license notices.

When only `parse.y` is available, Arpaka can replace its `RUBY_TOKEN(NAME)`
declarations with token names and generate a frontend without the rest of the
Ruby source tree:

```sh
RUBY_BOX=1 bundle exec arpaka generate \
  --parse-y /path/to/parse.y \
  --class-name MyRubyParser \
  --output lib/my_library/ruby_parser.rb
```

This mode embeds Arpaka's own license notices. The `--ruby-source` mode remains
the compatibility-preserving path when the Ruby source tree is available.

The consumer only needs the generated file and Ruby 4.0 or later:

```ruby
require_relative "lib/my_library/ruby_parser"

tree = MyRubyParser.parse("a = 1\na + 2", filename: "example.rb")
# MyRubyParser::AST::Program containing the assignment and addition
```

`parse` takes Ruby source and returns an AST. The parser, lexer and builder are
internal; callers do not need to supply tokens. Each call has fresh parsing and
local-variable state. No Arpaka/Lrama gem, Ruby Box, grammar files, network access
or filesystem writes are needed at runtime.

For generation from Ruby, `Arpaka.generate` returns that same standalone source.
To try a frontend in memory, use `Arpaka.compile`; both require `RUBY_BOX=1`:

```ruby
require "arpaka"

frontend = Arpaka.compile(ruby_source: "/path/to/ruby", class_name: "MyRubyParser")
tree = frontend.parse("a = 1")

code = Arpaka.generate(ruby_source: "/path/to/ruby", class_name: "MyRubyParser")
File.write("ruby_parser.rb", code)
```

The former `Arpaka.parse`, `Arpaka.parse_source` and `Lrama::Ruby.parse`
APIs have been replaced by explicitly generating or compiling a frontend.
The generic `Lrama::Ruby.generate` and `Lrama::Ruby.compile` APIs are unchanged.

This is not a complete Ruby frontend. Existing support includes literals,
assignments, calls, collections and portions of control flow and definitions.
Some constructs parse without preserving all their semantics in the current
AST, and nodes do not have source locations. Known unported rules raise
`MyRubyParser::UnsupportedSyntax`, exposing `rule` and upstream `line`.
Syntax errors raise `MyRubyParser::ParseError`, exposing `token` and `state`.
Lexer failures raise `MyRubyParser::LexerError` with filename, line and byte
column. These inherit from the generated `MyRubyParser::Error`.

The generated frontend has also been exercised against real-world source. On
Ruby 4.0.6, it parsed all 3,436 Ruby files in a local Rails checkout. This is
the practical compatibility signal for the current frontend. Ruby's Trick
contest programs are kept as a separate language-compatibility challenge: the
frontend currently parses 12 of 23 Ruby files in the `trick18` checkout, while
the remaining files use deliberately adversarial syntax that is not yet
represented by the current Action mappings. These are smoke-test results, not
a claim of complete Ruby language coverage.

## Current scope

Supported: precedence and associativity, `%prec`, `%empty`, `%start`, `%expect`,
LALR/IELR tables, and Lrama's standard parameterized rules. Standard list rules
retain Lrama's default semantic actions; they do not automatically build arrays.
Unresolved conflicts fail generation unless the shift/reduce count matches
`%expect`; reduce/reduce conflicts always fail.

Locations, typed values/`%union`, `%code`, prologues, epilogues, parse/lex parameters,
initial actions, hooks, printers, destructors and error recovery are not implemented.
The generator rejects these features rather than dropping their behavior.
Use plain Ruby values in actions; C actions are not translated into Ruby.
A Ruby action scanner handles semantic action tokens; Bison is not required.

### Inspecting a C grammar

Use `mode: :recognizer` to generate a standalone recognizer from a grammar with
C actions. This mode uses Lrama's C action lexer and deliberately omits all
semantic actions, prologues, epilogues, hooks, printers and destructors. Type and
location declarations do not produce runtime values. Error recovery is not
performed: unexpected input still raises `ParseError`. Conflicts are checked
as in the default `mode: :parser`.

```ruby
code = Lrama::Ruby.generate(File.read("parse.preprocessed.y"),
  class_name: "RubyRecognizer", mode: :recognizer)
File.write("ruby_recognizer.rb", code)
```

`parse(tokens)` returns `true` when the token stream is accepted. This mode is
for inspecting grammar tables; it does not build an AST or preserve checks and
lexer state changes performed by C actions. You must supply the token stream.
It does not by itself parse Ruby source text.

For Ruby's upstream `parse.y`, first run Ruby's `tool/id2token.rb` with
`defs/id.def` from the same revision. This is the preprocessing step used by
Ruby's build to replace `RUBY_TOKEN(...)` with numeric token IDs:

```sh
ruby /path/to/ruby/tool/id2token.rb /path/to/ruby/parse.y > parse.preprocessed.y
```

## Development

```sh
RUBY_BOX=1 bundle exec rake
RUBY_BOX=1 bundle exec rake test
RUBY_BOX=1 bundle exec rake ruby:check
RUBY_BOX=1 OUTPUT=/path/to/frontend.rb bundle exec rake ruby:generate
RUBY_BOX=1 bundle exec rake benchmark:parse
```

Development commands default to the pinned Ruby source fixture in `vendor/ruby`.
In an uninstalled checkout, invoke the CLI with
`RUBY_BOX=1 bundle exec ruby -Ilib exe/arpaka generate ...`.
Set `RUBY_SOURCE` to select another source directory. Normal CLI/API usage always
requires an explicit Ruby source tree. `ruby:check` verifies the source profile,
Action inventory, grammar transformation and generated frontend without editing
artifacts. `ruby:generate` writes the standalone frontend to `OUTPUT`.

`lib/arpaka/actions.rb` holds the Ruby Action mappings;
`lib/arpaka/upstream_rules.json` records the expected expanded upstream rules.
Update these and the source checksums together when adding support for a changed
Ruby grammar. Runtime templates live under `lib/arpaka/runtime/`.

Tests exercise the generated frontend and the generic backend. Package checks
install the gem, generate from external Ruby sources, and execute the resulting
file with gems and Ruby Box disabled. `Gemfile.lock` stays local and untracked.
Developer fixtures and tools are excluded from the gem.

### Benchmark

`benchmark:parse` measures frontend generation separately from loading the
generated file and parsing in a fresh process with Ruby Box disabled.
Set `ITERATIONS` to change the measured parsing iterations (default: 100).
Each warm measurement follows ten warmup calls. File reading/class definition
is measured separately; process startup and `require "prism"` are not timed.

The RubyVM and Prism measurements use the same source but return different AST
representations. They are reference measurements, not equivalent-work guarantees.

Example results on Ruby 4.0.6, x86_64 Linux, YJIT disabled, Prism 1.9.0
(10 measured iterations per input, ten warmup calls):

| Input | Arpaka (warm) | RubyVM AST | Prism |
| ---: | ---: | ---: | ---: |
| 10 bytes | 0.054 ms | 0.003 ms | 0.003 ms |
| 1,697 bytes | 5.901 ms | 0.060 ms | 0.128 ms |
| 18,800 bytes | 61.475 ms | 0.850 ms | 1.859 ms |

Frontend generation took 2.190s and loading the generated file took 20.571ms
in the same run. The first Arpaka parse took 0.130ms, 6.707ms and 73.381ms
for the small, medium and large inputs respectively.

Generation is a one-time build step per regeneration, not a cost of parsing an
input file. The generated frontend is loaded and measured with Ruby Box disabled.
Results vary with input and environment.

## License

[MIT](LICENSE.txt).

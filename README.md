# Arpaka

A Ruby language parser frontend and Ruby output backend for
[Lrama](https://github.com/ruby/lrama). `Arpaka` parses Ruby tokens into an AST,
while `Lrama::Ruby` generates standalone Ruby parsers with Ruby semantic actions.
The Ruby frontend is experimental and partial.

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

### Using the bundled Ruby grammar

```ruby
require "arpaka"

tree = Arpaka.parse(
  [[:tIDENTIFIER, :a], ["=", nil], [:tINTEGER, 1]]
)
# Arpaka::AST::Program containing LocalWrite(:a, Literal(1))
```

Run with `RUBY_BOX=1`. The first call generates and compiles the bundled grammar
in memory; later calls reuse the class. Each call has its own parser and local
variable table. No build command, network access or writable working directory
is needed. `language:` is required; currently only the symbol `:ruby` is supported.

Supply token pairs from your own lexer. `tINTEGER` values are Integers, `tFLOAT`
values are Floats, and `tIDENTIFIER` values are Symbols or Strings. Operators and
keywords may carry `nil`. Parentheses use Ruby's context-dependent token names
(for example `tLPAREN` followed by `")"`), not a source string tokenizer.

The supported slice includes numeric and nil/boolean literals, binary `+ - * /`,
unary `+ -`, single-expression parentheses, simple local assignments, and
statements separated by semicolons or newlines. Every successful parse returns
an `AST::Program`. Its frozen `statements` array contains immutable Data nodes:
`Literal(value)`, `Binary(operator, left, right)`, `Unary(operator, operand)`,
`LocalRead(name)`, `LocalWrite(name, value)`, and `BareCall(name)`.
An unassigned bare identifier is a `BareCall`; assignment registers a local
before reading its right-hand side, including in `a = a`.

This is not yet a complete Ruby frontend. Strings, explicit calls, control flow,
methods, and multi-statement parentheses are unsupported. Nodes have no source
locations. Input must already reflect the lexical decisions Ruby's parser and
lexer normally make together; this API does not parse Ruby source text.

`Arpaka::ParseError` exposes `token` and `state`. `Arpaka::UnsupportedSyntax`
exposes the original `rule` and upstream `line`. Both inherit from
`Lrama::Ruby::Error`. Unported rules raise
instead of returning a partial AST. Lexer exceptions and invalid token values
propagate to the caller.

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
Prism tokenizes Ruby actions and checks generated syntax; Bison is not required.

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
RUBY_BOX=1 bundle exec rake test
RUBY_BOX=1 bin/console
```

Tests cover generated parsers, Ruby actions, parse errors and Box isolation,
including execution of a generated file without gems. CI uses Ruby 4.0.6.
`Gemfile.lock` stays local and is not tracked.

The default task also checks the bundled Ruby grammar against the pinned
upstream source in `vendor/ruby`. `tool/ruby/actions.rb` defines the ported
actions; `tool/ruby/upstream_rules.json` records the original expanded rules.
Run `bundle exec rake ruby:generate` after changing action definitions, and
`bundle exec rake ruby:check` to check for stale artifacts without writing files.
The check compares every production, token ID and precedence, including empty
productions representing midrule actions. Update the pinned revision and rule
inventory together when deliberately upgrading upstream.

Runtime grammar and rule metadata are packaged; upstream source and developer
tools are not. Ruby-derived artifacts retain the upstream license notices in
`lib/lrama/ruby/languages/ruby/COPYING` and `BSDL`.

## License

[MIT](LICENSE.txt).

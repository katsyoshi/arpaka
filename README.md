# Lrama::Ruby

A Ruby output backend for [Lrama](https://github.com/ruby/lrama). It uses Lrama's
LALR/IELR parsing tables to generate a standalone Ruby parser with Ruby semantic
actions.

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
gem "lrama-ruby", git: "https://github.com/katsyoshi/lrama-ruby"
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
require "lrama/ruby"

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

## License

[MIT](LICENSE.txt).

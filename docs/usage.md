# Arpaka usage guide

Arpaka has two related roles:

- `Lrama::Ruby` generates standalone parsers from Yacc-style grammars.
- `Arpaka` generates a standalone Ruby source frontend whose `parse` method
  returns an AST.

This guide focuses on the Ruby frontend. The frontend is experimental and
partial; successful parsing does not imply that every Ruby construct is
represented completely in the AST.

## Requirements and execution model

Arpaka requires Ruby 4.0 or later. Generation and compilation use Ruby Box to
isolate Ruby-specific Lrama extensions, so start the generator with
`RUBY_BOX=1`:

```sh
RUBY_BOX=1 bundle exec ruby your_script.rb
```

When using the checkout before installing the executable, use
`RUBY_BOX=1 bundle exec ruby -Ilib exe/arpaka ...`. An installed gem exposes
the `arpaka` executable directly.

Generation requires either a Ruby source tree or a `parse.y` file. Arpaka
does not download Ruby sources. The source-tree mode expects the files used by
the selected source profile, including `parse.y`, `tool/id2token.rb`,
`defs/id.def`, `COPYING`, and `BSDL`. The current profile is pinned to Ruby
revision `37d60dd3241d5fdb10ca43f36077f5d556ae1b8d`; a different checkout may
produce checksum warnings or fail generation.

The generated frontend is a single Ruby file. At runtime it needs Ruby 4.0 or
later, but it does not need the Arpaka or Lrama gems, Ruby Box, the grammar
files, network access, or filesystem writes. Requiring the generated file
defines the requested parser class and its AST classes.

## Ruby API

Require Arpaka in the process that performs generation or compilation:

```ruby
require "arpaka"
```

### Generate standalone source

`Arpaka.generate` returns the complete frontend source as a string. It requires
exactly one of `ruby_source:` and `parse_y:`:

```ruby
code = Arpaka.generate(
  ruby_source: "/path/to/ruby",
  class_name: "MyRubyParser"
)
File.write("local/tmp/my_ruby_parser.rb", code)
```

For a `parse.y`-only input:

```ruby
code = Arpaka.generate(
  parse_y: "/path/to/parse.y",
  class_name: "MyRubyParser"
)
File.write("local/tmp/my_ruby_parser.rb", code)
```

`class_name` defaults to `RubyParser` and accepts either one Ruby constant name
or a namespace path such as `MyLibrary::RubyParser`. Arpaka parses the name as
one or more constant components separated by exactly `::`; each component must
start with an uppercase ASCII letter and may continue with ASCII letters,
digits, or underscores. Empty components, malformed separators, numeric or
lowercase components raise `Arpaka::Error` with the invalid component described.
Arpaka emits the required nested modules. Generation validates the generated
source in an isolated Ruby Box before returning it.
For example, `class_name: "A::B::Parser"` generates `module A`, nested
`module B`, and the `Parser` class. The returned source can be loaded normally,
and `Arpaka.compile` returns the leaf `A::B::Parser` class from its isolated Box.

### Compile in memory

`Arpaka.compile` generates the same source and evaluates it in a new Ruby Box.
It returns the generated parser class:

```ruby
frontend = Arpaka.compile(
  ruby_source: "/path/to/ruby",
  class_name: "A::B::Parser"
)

tree = frontend.parse("value = 1\nvalue + 2", filename: "example.rb")
```

Each call to `parse` creates fresh parser and local-variable state. The
`filename:` keyword is retained for diagnostics and defaults to the parser's
normal filename value when omitted.

### Parse with a generated frontend

The generated class exposes:

```ruby
require_relative "local/tmp/my_ruby_parser"

tree = MyLibrary::RubyParser.parse("a = 1\na + 2", filename: "example.rb")
```

`parse(source, filename:)` accepts Ruby source text and returns an AST rooted
at `MyRubyParser::AST::Program`; the generated runtime defaults `filename` to
`"(ruby)"` when it is omitted. The parser, lexer, and builder are internal
implementation details; callers do not provide tokens. Parsing state is not
shared between calls.

Generated frontends raise these generated error classes:

- `MyRubyParser::ParseError` for syntax errors; it exposes `token` and `state`.
- `MyRubyParser::UnsupportedSyntax` for an upstream grammar rule that is not
  mapped; it exposes `rule` and `upstream line` information.
- `MyRubyParser::LexerError` for lexer failures; it includes filename, line,
  and byte-column information.
- All of these inherit from `MyRubyParser::Error`.

The former `Arpaka.parse`, `Arpaka.parse_source`, and `Lrama::Ruby.parse`
frontends are not part of this API. Generate or compile a frontend first.

## Command-line generation

The CLI command is `arpaka generate`. It requires exactly one input mode and an
output path:

```sh
RUBY_BOX=1 bundle exec arpaka generate \
  --ruby-source /path/to/ruby \
  --class-name MyLibrary::RubyParser \
  --output lib/my_library/ruby_parser.rb
```

The `parse.y`-only mode uses Arpaka's token-name preprocessing:

```sh
RUBY_BOX=1 bundle exec arpaka generate \
  --parse-y /path/to/parse.y \
  --class-name MyRubyParser \
  --output lib/my_library/ruby_parser.rb
```

The output directory must already exist. Existing output is preserved unless
`--force` is supplied. Output is written through a temporary file and is only
published after generation succeeds, so a failed generation leaves an existing
frontend intact. The generated file includes the source profile, generator
version, and license notices.

The experimental sample plugin is a separate command shape:

```sh
RUBY_BOX=1 bundle exec arpaka sample generate \
  -y /path/to/parser.y \
  -c MyParser \
  -o lib/my_library/parser.rb
```

## Frontend scope and limitations

The frontend currently covers literals, assignments, calls, collections, and
parts of control flow, blocks, methods, classes, modules, and related Ruby
syntax. It is intended to expose a useful AST, not to promise full Ruby
language equivalence. AST nodes currently do not have source locations.

Important limitations include:

- `%W` and `%I` have incomplete Action mappings; interpolated forms currently
  raise a lexer error instead of producing a flattened AST.
- Some constructs parse while losing semantic details, including known losses
  around block parameters and qualified constant paths.
- Unsupported upstream grammar rules raise `UnsupportedSyntax`.
- Ruby grammar revisions other than the pinned source profile are not
  automatically supported.

These limitations are why the compatibility benchmark compares normalized ASTs
and reports unsupported or ambiguous cases separately from successful parses.

This frontend is distinct from the generic `Lrama::Ruby` backend. The generic
backend still accepts a Yacc-style grammar and returns a parser source string
from `Lrama::Ruby.generate`, or a parser class from `Lrama::Ruby.compile`.

## Parsing speed benchmark

The parsing benchmark measures frontend generation separately from loading the
generated file and parsing representative inputs. Run it from the repository
root with:

```sh
RUBY_BOX=1 bundle exec rake benchmark:parse
```

`benchmark/parse.rb` uses three generated inputs:

- `small`: `value = 1\n`;
- `medium`: 100 assignments followed by `value100 + 1`;
- `large`: 1,000 assignments followed by `value1000 + 1`.

Set `RUBY_SOURCE` to benchmark generation from another Ruby source tree. If it
is unset, the benchmark uses the repository's `vendor/ruby` source. Set
`ITERATIONS` to change the number of measured parse calls; it defaults to 100
and must be positive:

```sh
RUBY_BOX=1 RUBY_SOURCE=/path/to/ruby ITERATIONS=250 \
  bundle exec rake benchmark:parse
```

The benchmark has two processes and two measurement phases. The generator
process measures one `Arpaka.generate` call. It then writes the generated
frontend to a temporary file and starts a fresh runtime process with Ruby Box
disabled. That runtime process measures:

- loading the generated file, including reading and defining its classes;
- the first parse for each input;
- ten warmup parses, followed by the configured number of warm parses;
- `RubyVM::AbstractSyntaxTree.parse` for the same inputs, when RubyVM AST is
  available; and
- `Prism.parse` for the same inputs.

Process startup is not included in the timed calls, and loading Prism itself is
outside the Prism measurements. The runtime process uses `--yjit` when YJIT is
already enabled in the invoking Ruby. Each result prints total elapsed time and
average milliseconds per call. Generation and file loading are reported
separately because generation is a one-time cost when a frontend is built, not
a cost paid by every later `parse` call.

RubyVM AST and Prism return different AST representations from Arpaka. Their
numbers are useful reference points for the same input and environment, but
they are not a guarantee of equivalent work, equivalent semantics, or a
benchmark ranking. Arpaka performs frontend-specific lexing, parsing, AST
construction, and normalization, so compare results only with the same Ruby
version, CPU, YJIT setting, input sizes, source profile, and `ITERATIONS`.

The README's reference run used Ruby 4.0.6 on x86_64 Linux with YJIT disabled
and Prism 1.9.0. It reported warm Arpaka parse times of 0.054 ms, 5.901 ms,
and 61.475 ms for 10-byte, 1,697-byte, and 18,800-byte inputs; the same table
reports RubyVM AST and Prism reference values. Generation took 2.190 s,
loading the generated file took 20.571 ms, and first Arpaka parses took
0.130 ms, 6.707 ms, and 73.381 ms. These are historical measurements, not
service-level targets. Self-hosted elapsed time varies with CPU, Ruby version,
YJIT, source profile, and input shape; record the complete output from your
own run when comparing changes.

## AST compatibility benchmark

`benchmark/compatibility.rb` compares the generated frontend with
`RubyVM::AbstractSyntaxTree` for every `.rb` file in explicitly supplied local
corpora. It parses source files; it does not execute them. Rails, Trick, and
other external repositories are read-only inputs and are not downloaded or
packaged by Arpaka.

### Prepare a frontend

Generate the frontend once in a Ruby Box. Reuse it for the comparison so
generation time is not mixed into parser comparison time:

```sh
RUBY_BOX=1 bundle exec ruby tool/ruby/grammar.rb \
  --output local/tmp/compatibility-frontend.rb \
  --class-name CompatibilityFrontend \
  --force
```

Alternatively, omit `--frontend` below and pass `--ruby-source`; the runner
will generate a frontend itself and therefore must run with `RUBY_BOX=1`.

### Build and use a RubyVM reference cache

The comparison runner requires `--reference-cache`. The cache is JSONL keyed by
corpus name, relative path, and source SHA256. Each `type: "reference"` record
contains the normalized RubyVM tree and a status. A changed corpus file does
not silently reuse an old tree: its SHA256 no longer matches and the run
reports a reference-cache miss as an error.

`benchmark/compatibility.rb` reads this cache; it does not create RubyVM
reference records during a normal comparison. Generate the cache as a separate
oracle step using the same Ruby version as the comparison. A minimal local
example is:

```ruby
# Save as local/tmp/build-reference-cache.rb and run with:
# bundle exec ruby -Ilib local/tmp/build-reference-cache.rb
require "digest"
require "json"
require_relative "../../benchmark/compatibility/normalizer"

corpora = {
  "rails" => "/path/to/rails",
  "trick25" => "/path/to/trick2025",
  "trick22" => "/path/to/trick2022",
  "trick18" => "/path/to/trick2018",
  "trick15" => "/path/to/trick2015",
  "trick13" => "/path/to/trick2013"
}
normalizer = Compatibility::Normalizer.new

File.open("local/tmp/arpaka-reference-all.jsonl", "w") do |out|
  corpora.each do |name, root|
    Dir.glob(File.join(root, "**", "*.rb")).sort.each do |path|
      source = File.binread(path).force_encoding(Encoding::UTF_8)
      relative = path.delete_prefix(File.expand_path(root) + File::SEPARATOR)
      record = {
        "type" => "reference", "corpus" => name, "path" => relative,
        "sha256" => Digest::SHA256.hexdigest(source), "status" => "ok",
        "elapsed_seconds" => 0.0
      }
      begin
        tree = RubyVM::AbstractSyntaxTree.parse(source, keep_script_lines: false)
        value = normalizer.rubyvm(tree.children.fetch(2))
        record["tree"] = value.is_a?(Array) && value.first == :sequence ? value :
          [:sequence, value.nil? ? [] : [value]]
      rescue SyntaxError => error
        record["status"] = "parse_failure"
        record["reason"] = "#{error.class}: #{error.message}"
      rescue Compatibility::Unsupported => error
        record["status"] = "unverified"
        record["side"] = error.side.to_s
        record["reason"] = error.detail
      rescue StandardError => error
        record["status"] = "error"
        record["reason"] = "#{error.class}: #{error.message}"
      end
      out.puts(JSON.generate(record, max_nesting: false))
    end
  end
end
```

The oracle step must use the same corpus revisions and Ruby runtime as the
comparison. The cache may also be compressed as `.xz`; the runner invokes
`xz -dc` when the path ends in `.xz`.

### Run the comparison

Pass one `--corpus NAME=PATH` per source tree. The names become part of the
cache key and report. A corpus can also be one Ruby file, but a directory is
recursively scanned for `.rb` files:

```sh
bundle exec ruby -Ilib benchmark/compatibility.rb \
  --frontend local/tmp/compatibility-frontend.rb \
  --corpus rails=/path/to/rails \
  --corpus trick25=/path/to/trick2025 \
  --corpus trick22=/path/to/trick2022 \
  --corpus trick18=/path/to/trick2018 \
  --corpus trick15=/path/to/trick2015 \
  --corpus trick13=/path/to/trick2013 \
  --reference-cache local/tmp/arpaka-reference-all.jsonl \
  --threads 32 \
  --parallel thread \
  --report local/tmp/arpaka-compatibility.jsonl
```

If the frontend was generated with a namespace, pass its complete constant
path with `--frontend-class`:

```sh
RUBY_BOX=1 bundle exec ruby -Ilib benchmark/compatibility.rb \
  --frontend local/tmp/a_b_parser.rb \
  --frontend-class A::B::Parser \
  --corpus fixture=benchmark/fixtures \
  --reference-cache local/tmp/fixture-reference.jsonl \
  --threads 32 --parallel thread
```

The runner and worker resolve each component of this path with `const_get`, so
the frontend can define `A::B::Parser` directly. The default remains
`CompatibilityFrontend`, preserving existing commands and generated frontends.

For self-hosted runs, `--threads 32 --parallel thread` is the recommended
starting point for the large Rails/Trick corpus. The default is one Thread,
which is useful for debugging but considerably slower on a large corpus.
`--parallel ractor` is available for experimental isolation comparisons, and
`--disable-gc` is an opt-in experiment that can substantially increase heap
usage. `--timeout` controls the per-parser/file timeout and defaults to 10
seconds.

This runner option is separate from the repository test suite. The normal
compatibility tests execute the Thread path. Tests that exercise Ruby
Box/Ractor compatibility are currently omitted by default because of the Ruby
4.0 Ruby Box/Ractor constraints; run them explicitly with
`ARPAKA_RUN_RACTOR_TESTS=1`. That test setting does not enable the runner's
`--parallel ractor` mode, and selecting `--parallel ractor` does not change
which test-suite cases are omitted.

The Rake wrapper accepts equivalent selections through environment variables:

```sh
CORPORA="rails=/path/to/rails trick13=/path/to/trick13" \
REPORT=local/tmp/arpaka-compatibility.jsonl \
RUBY_SOURCE=/path/to/ruby \
bundle exec rake benchmark:compatibility
```

The Rake task forwards `CORPORA`, `REPORT`, and `RUBY_SOURCE`; for explicit
thread and parallel settings, invoke `benchmark/compatibility.rb` directly.

### Read the report

The JSONL report contains one file record per comparison followed by a summary
record. The summary includes runtime, Git/source revisions, corpus manifests,
frontend and benchmark hashes, file count, per-corpus counts, and exit-related
totals. It also includes `elapsed_seconds` for the run and GC deltas for heap
pages, live slots, total allocations, minor GC, and major GC.

File statuses mean:

- `match`: the normalized RubyVM and Arpaka ASTs are equal.
- `accepted_mismatch`: a comparison difference explicitly accepted by the
  comparator, currently including keyword-argument representation and certain
  explicit terminal-`nil` body representations.
- `mismatch`: both sides produced comparable trees, but they differ in a way
  not accepted by the comparator.
- `unverified`: a parser or normalizer used a construct outside the comparison
  model, or required metadata is unavailable; this is not a match.
- `parse_failure`: RubyVM or Arpaka could not parse the file.
- `error`: an unexpected worker/input failure or a missing reference-cache
  record occurred.
- `timeout`: a worker exceeded the configured timeout.

The command exits 0 only when every file is `match` or `accepted_mismatch`, 1
when any comparison has another status, and 2 for invalid configuration or a
runner error. A successful parse alone is not AST compatibility.

### Self-hosted duration and baseline

Compatibility time depends on CPU, Ruby version, corpus revisions, file count,
frontend version, worker count, and GC behavior. Treat timings as local
capacity-planning hints, not guarantees. The repository's reference in
[`docs/contributes.md`](contributes.md) measured Ruby 4.0.7 against Rails and
Trick 2013, 2015, 2018, 2022, and 2025: 3,525 Ruby files with 32 workers.
The reported baselines were:

| Mode | Elapsed | Heap pages | Live slots | Minor GC | Major GC |
| --- | ---: | ---: | ---: | ---: | ---: |
| Thread | 6.85 s | 1,483 | 131,390 | 5 | 3 |
| Thread + `--disable-gc` | 6.62 s | 1,484 | 131,433 | 5 | 3 |
| Ractor | 15.66 s | 4,795 | 4,445,551 | 128 | 10 |
| Ractor + `--disable-gc` | 10.42 s | 101,705 | 131,481,029 | 2 | 1 |

Those values are the `docs/contributes.md` reference run, not a promise about
another host. Compare `elapsed_seconds` and GC fields from your own report,
along with its Ruby runtime, corpus commits, and file count.


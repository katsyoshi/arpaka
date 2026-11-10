# Benchmarks

## Parsing speed

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

Set `RUBY_SOURCE` to benchmark generation from another Ruby source tree. Set
`ITERATIONS` to change the number of measured parse calls; it defaults to 100.
The benchmark performs 100 unmeasured warmup calls before each warm measurement:

```sh
RUBY_BOX=1 RUBY_SOURCE=/path/to/ruby ITERATIONS=250 \
  bundle exec rake benchmark:parse
```

The benchmark measures normal AST and Structural Tree generation, loading both
generated frontends, and parsing in a fresh process with Ruby Box disabled. It
also measures `RubyVM::AbstractSyntaxTree.parse` and `Prism.parse` when they
are available. Each parse measurement has 100 warmup calls followed by the
configured number of measured calls. Process startup and loading Prism are not
included in the timed calls. This warmup is part of the benchmark setup rather
than a user-facing option, so YJIT can compile frequently called paths before
the measured phase.

Structural Tree is a lightweight structural projection of the AST. It keeps
definitions and lexical nesting for structural consumers rather than exposing a
second, simplified AST contract. The API option remains `ast_type: :structured`;
the benchmark uses the name Structural Tree to describe the resulting output.

RubyVM AST and Prism return different representations and perform different
work from Arpaka. Their numbers are reference measurements, not equivalent-work
guarantees or a benchmark ranking. Compare runs using the same Ruby version,
CPU, YJIT setting, source profile, input sizes, and `ITERATIONS`.

## Current reference result

On 2026-11-11, Ruby 4.0.9 on x86_64 Linux with YJIT disabled and Prism 2.1.0
produced the following result with 100 measured iterations and 100 warmup calls:

| Input | Arpaka AST (warm) | Arpaka Structural Tree (warm) | RubyVM AST | Prism |
| ---: | ---: | ---: | ---: | ---: |
| 10 bytes | 0.057 ms | 0.066 ms | 0.001 ms | 0.002 ms |
| 1,697 bytes | 6.451 ms | 7.034 ms | 0.067 ms | 0.098 ms |
| 18,800 bytes | 70.461 ms | 77.258 ms | 0.882 ms | 1.139 ms |

Frontend generation took 1.783s for the normal AST and 1.765s for Structural
Tree. Loading the generated files took 11.665ms and 9.560ms, respectively.
The first Arpaka parse took 0.199ms, 6.512ms and 78.562ms for the normal AST,
and 0.178ms, 6.508ms and 72.671ms for Structural Tree.

These measurements are a current reference, not service-level targets. The
frontend performs lexing, parsing, AST construction, and normalization, so
differences from RubyVM AST and Prism are expected.

The same run with YJIT enabled produced these warm parse times:

| Input | Arpaka AST (warm) | Arpaka Structural Tree (warm) | RubyVM AST | Prism |
| ---: | ---: | ---: | ---: | ---: |
| 10 bytes | 0.043 ms | 0.048 ms | 0.004 ms | 0.002 ms |
| 1,697 bytes | 4.024 ms | 5.091 ms | 0.068 ms | 0.080 ms |
| 18,800 bytes | 42.422 ms | 49.921 ms | 0.860 ms | 0.945 ms |

With YJIT enabled, frontend generation took 1.453s for the normal AST and
1.391s for Structural Tree. Loading took 13.710ms and 11.828ms. The first
parse is affected by JIT compilation, so warm results are the more useful
comparison.

## Historical reference

An earlier run used Ruby 4.0.6 on x86_64 Linux with YJIT disabled and Prism
1.9.0. It measured only the normal AST output:

| Input | Arpaka AST (warm) | RubyVM AST | Prism |
| ---: | ---: | ---: | ---: |
| 10 bytes | 0.054 ms | 0.003 ms | 0.003 ms |
| 1,697 bytes | 5.901 ms | 0.060 ms | 0.128 ms |
| 18,800 bytes | 61.475 ms | 0.850 ms | 1.859 ms |

Frontend generation took 2.190s, loading took 20.571ms, and first Arpaka
parses took 0.130ms, 6.707ms, and 73.381ms for the three inputs.

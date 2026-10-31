# Compatibility checks

This repository has two kinds of compatibility checks. They serve different
purposes and should not be treated as interchangeable.

## Pull request CI

Pull request CI is the fast, required check for the repository itself. It
verifies that the generated frontend and the test suite still work on the
supported Ruby versions.

The Ractor compatibility mode is experimental. Generate a frontend first in a
Ruby Box, then run the compatibility check without a Ruby Box:

```sh
RUBY_BOX=1 OUTPUT=/tmp/arpaka-frontend.rb bundle exec rake ruby:generate

bundle exec ruby benchmark/compatibility.rb \
  --ruby-source vendor/ruby \
  --corpus fixtures=benchmark/fixtures \
  --frontend /tmp/arpaka-frontend.rb \
  --reference-cache /path/to/reference.jsonl \
  --threads 2 \
  --parallel ractor
```

The default mode remains Thread-based. Ractor checks should not make ordinary
pull request validation depend on large external repositories.

## Weekly compatibility inspection

The weekly inspection is intended for larger real-world inputs, especially the
Rails repository and the TRICK programs. It is a diagnostic and compatibility
inspection, not a replacement for pull request CI.

The external repositories should be checked out by the CI job at the commit
being inspected. The RubyVM Oracle JSONL should then be generated in the same
job and with the same Ruby runtime used for the comparison. The Oracle is
temporary job data; it should not be committed to this repository.

The inspection should record the external repository commits, Ruby runtime,
Ractor count, GC setting and result summary. The comparison report should be
uploaded as an Artifact. The much larger Oracle should normally remain in the
job workspace and only be uploaded for a failed or explicitly requested run.

### Reference benchmark

The following measurement was made with Ruby 4.0.7 against the Rails
repository and TRICK 2013, 2015, 2018, 2022 and 2025 sources. The corpus
contained 3,525 Ruby files and both modes used `--threads 32`.

| Mode | Elapsed time | Heap allocated pages | Heap live slots | Minor GC | Major GC |
| --- | ---: | ---: | ---: | ---: | ---: |
| Thread | 6.85 s | 1,483 | 131,390 | 5 | 3 |
| Thread + `--disable-gc` | 6.62 s | 1,484 | 131,433 | 5 | 3 |
| Ractor | 15.66 s | 4,795 | 4,445,551 | 128 | 10 |
| Ractor + `--disable-gc` | 10.42 s | 101,705 | 131,481,029 | 2 | 1 |

In this run, Ractor mode was about 2.3 times slower than Thread mode with GC
enabled. Disabling GC reduced the Ractor time by about 33%, but increased heap
usage substantially. These numbers are a reference point rather than a
performance guarantee; Ruby versions, CPU count, corpus revisions and worker
counts can change the result.

## Ractor mode

Ractor workers share the generated frontend class loaded by the parent Ractor.
The frontend is loaded once per run so that each corpus does not redefine its
constants.

Use `--threads` to control the number of concurrent workers. Ractor mode has
additional object-transfer and heap costs, so the best worker count may differ
from the Thread mode.

## Disabling GC

`--disable-gc` is an opt-in performance experiment. It applies to both Thread
and Ractor workers; GC remains enabled by default.

```sh
bundle exec ruby benchmark/compatibility.rb \
  --corpus fixtures=benchmark/fixtures \
  --frontend /tmp/arpaka-frontend.rb \
  --reference-cache /path/to/reference.jsonl \
  --parallel ractor \
  --threads 32 \
  --disable-gc
```

Disabling GC can improve throughput substantially, but it can also grow the
Ruby heap dramatically. Use it only on machines with ample memory and inspect
the `GC.stat` values in the report. It should not be enabled by default in CI.

## Reading results

The report distinguishes parser outcomes from tree comparison results:

- `match`: normalized trees are equal.
- `accepted_mismatch`: a known, explicitly accepted representation difference.
- `mismatch`: normalized trees differ.
- `unverified`: one side uses a construct outside the comparison model.
- `parse_failure`: parsing failed.
- `timeout`: a worker exceeded its time limit.
- `error`: an unexpected worker or input error occurred.

Existing `mismatch` and `unverified` results are not automatically evidence of
a Ractor failure. Compare Thread and Ractor runs using the same corpus,
reference cache and Ruby runtime; Ractor-specific failures are parse failures,
timeouts, worker errors, or result differences that appear only in Ractor mode.

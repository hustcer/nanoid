# Performance measurements

## Method

Measured on 2026-09-08 on an Apple M1 (arm64), macOS 15.7.9, with
MoonBit `moon 0.1.20260827`, `moonc v0.10.11+6ff76a5f9`, and Node.js `v22.23.1`.
Benchmarks are in `src/nanoid_bench_test.mbt` and use `@bench.T.keep` to retain
results. Run them with:

```sh
moon bench --target native --release
moon bench --target js --release
```

Each process reports a mean over 10 adaptively sized sample batches. The summary
tables use the median of three process means. Baseline and changed versions were
run sequentially in alternating order, in separate worktrees, with identical
benchmark source and package imports. Compilation and process startup are outside
the timed regions. Results describe this machine and runtime, not every backend
or workload. Values below retain the precision printed by `moon bench`.

## Reuse the fixed URL alphabet

Baseline: `ab44480`. The changed version prepares the private URL alphabet
character array once and validates only the requested size in `nanoid()`.
Previously, every call rebuilt a persistent hash map to validate the same 64
characters, then allocated and populated another character array.

| Backend | Operation | Before | After | Speedup |
| --- | --- | ---: | ---: | ---: |
| Native | `nanoid(size=21)` | 6.660 µs | 0.41528 µs | 16.04× |
| Native | `nanoid(size=1)` | 6.340 µs | 0.13724 µs | 46.20× |
| JS | `nanoid(size=21)` | 8.010 µs | 1.370 µs | 5.85× |
| JS | `nanoid(size=1)` | 8.330 µs | 1.060 µs | 7.86× |
| Native | Reused URL generator, size 21 (control) | 0.41042 µs | 0.41197 µs | 1.00× |
| JS | Reused URL generator, size 21 (control) | 1.350 µs | 1.380 µs | 0.98× |

The default-generation benchmarks include the existing OS-backed RNG and string
construction. The control constructs its generator outside the timed region;
its small variation is not treated as an improvement.

### Individual process means (microseconds)

| Backend | Operation | Before rounds 1 / 2 / 3 | After rounds 1 / 2 / 3 |
| --- | --- | --- | --- |
| Native | Default size 21 | 6.67 / 6.66 / 6.63 | 0.41750 / 0.41213 / 0.41528 |
| Native | Default size 1 | 6.34 / 6.37 / 6.33 | 0.13711 / 0.13909 / 0.13724 |
| Native | Reused generator | 0.41042 / 0.41145 / 0.40872 | 0.41197 / 0.41098 / 0.41385 |
| JS | Default size 21 | 8.53 / 8.01 / 7.95 | 1.37 / 1.37 / 1.38 |
| JS | Default size 1 | 8.55 / 8.33 / 8.10 | 1.04 / 1.06 / 1.10 |
| JS | Reused generator | 1.35 / 1.35 / 1.36 | 1.38 / 1.35 / 1.39 |

To reproduce the baseline, check out `ab44480` in a separate worktree, copy
`src/nanoid_bench_test.mbt` from this change, and add the test-only
`moonbitlang/core/bench` import to `src/moon.pkg`. Run the commands above on each
version in alternating order. Tests for invalid sizes, maximum sizes, alphabet
membership, and generator reuse pass on all four targets; generated public
interfaces are unchanged.

# Record Swift 6.4 benchmark thresholds

<!-- markdownlint-disable MD013 -->

The new Linux 6.4 benchmark lane compiled and ran the benchmarks, but its threshold check failed because `Benchmarks/Thresholds/6.4/` did not exist. The benchmark plugin reported `benchmarkThresholdRegression` for missing absolute thresholds, then emitted the two measured p90 allocation-count files as a diff. This was a missing baseline for the new compiler lane, not a regression against an existing 6.4 baseline.

Add only the two JSON files emitted by the completed hosted run. Keep benchmark code, the threshold comparison, and all existing toolchain thresholds unchanged.

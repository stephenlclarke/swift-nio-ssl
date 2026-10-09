# Add Swift 6.4 allocation-count thresholds

<!-- markdownlint-disable MD013 -->

The Linux 6.4 benchmark lane now has p90 allocation-count thresholds for `ManyWrites` (201953) and `SimpleHandshake` (641871), matching the files emitted by failed job `113721424357` in run `37900414912`. These values are within the range of the existing 6.1–6.3 and nightly thresholds. No benchmark workload, measurement method, or comparison rule changed.

Validation: the two JSON files parse as the exact observed counts; the existing toolchain threshold inventory remains unchanged. A fresh hosted 6.4 benchmark run remains required to verify the complete check. The original failure log is retained separately.

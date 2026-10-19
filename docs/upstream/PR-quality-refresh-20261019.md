# fix(ci): bind local TLS coverage to source and branch

## Problem and behavior

Refresh the existing quality pull request with current TLS upstream changes and fix both local-scan review findings. Coverage carries source-revision and checksum sidecars. Scans reject stale reports, modified reports and dirty tracked source, and identify the current local branch explicitly. Detached local checkouts fail instead of selecting main implicitly.

## Validation

The actual Make target is exercised with an isolated scanner double for valid local and CI context, missing and stale provenance, modified reports, source edits, detached HEAD and a mismatched version override. Existing coverage-conversion regressions still run. The complete native TLS suite supplies fresh measured coverage; no historical benchmark is rebuilt or rerun.

## Compatibility and risks

Supported GitHub Actions retains automatic pull-request context. The scanner token is supplied only through the environment. Existing measured coverage shortfalls remain visible. Related: [issue](ISSUE-quality-refresh-20261019.md) and [PR 6](https://github.com/stephenlclarke/swift-nio-ssl/pull/6).

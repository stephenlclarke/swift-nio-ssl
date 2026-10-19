# fix(ci): bind local TLS coverage to source and branch

## Problem and behavior

Refresh the existing quality pull request with current TLS upstream changes and fix both local-scan review findings. Coverage carries source-revision and checksum sidecars. Scans reject stale reports, modified reports and dirty tracked source, and identify the current local branch explicitly. Detached local checkouts fail instead of selecting main implicitly.

## Validation

The actual Make target is exercised with an isolated scanner double for valid local and CI context, missing and stale provenance, modified reports, source edits, detached HEAD and a mismatched version override. Existing coverage-conversion regressions still run. The complete native TLS suite supplies fresh measured coverage; no historical benchmark is rebuilt or rerun.

## Compatibility and risks

Supported GitHub Actions retains automatic pull-request context. The scanner token is supplied only through the environment. Existing measured coverage shortfalls remain visible. Related: [issue](ISSUE-quality-refresh-20261019.md) and [PR 6](https://github.com/stephenlclarke/swift-nio-ssl/pull/6).

The refreshed upstream source also reports three unused `bio` callback parameters in Sonar. Preserve their required C callback signatures and argument labels while explicitly marking the parameters unused; this changes no runtime behavior.

Swift 6.4 hosted benchmark checks reported allocation improvements against stale budgets: ManyWrites 201,649 versus 201,953; SimpleHandshake 423,788 versus 641,871. The budgets now use those already recorded CI measurements ([job](https://github.com/stephenlclarke/swift-nio-ssl/actions/runs/39214798930/job/117936495037)); an earlier job measured 201,649/423,781, within the unchanged 50-allocation tolerance. This tightens the existing budgets and changes no production code, tolerance, published baseline artifact, or historical result.

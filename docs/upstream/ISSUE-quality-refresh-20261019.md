# Keep local TLS quality scans on the correct branch and revision

## Problem

Review findings on [PR 6](https://github.com/stephenlclarke/swift-nio-ssl/pull/6) show that a local scan omits branch context and accepts coverage left behind by a different source checkout. That can replace main's measurements or attach historical coverage to a new commit.

## Expected behavior

Record the clean source revision before coverage generation and verify it again afterward. Admit only a matching revision and report checksum at scan time. Explicitly supply the local branch; preserve supported GitHub Actions pull-request detection.

## Compatibility

Old coverage needs one regeneration to create provenance sidecars. No threshold, source exclusion or baseline changes. See [implementation](PR-quality-refresh-20261019.md).

The refreshed upstream source also reports three unused `bio` callback parameters in Sonar. Preserve their required C callback signatures and argument labels while explicitly marking the parameters unused; this changes no runtime behavior.

Swift 6.4 hosted benchmark checks reported allocation improvements against stale budgets: ManyWrites 201,649 versus 201,953; SimpleHandshake 423,788 versus 641,871. The budgets now use those already recorded CI measurements ([job](https://github.com/stephenlclarke/swift-nio-ssl/actions/runs/39214798930/job/117936495037)); an earlier job measured 201,649/423,781, within the unchanged 50-allocation tolerance. This tightens the existing budgets and changes no production code, tolerance, published baseline artifact, or historical result.

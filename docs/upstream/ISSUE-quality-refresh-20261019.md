# Keep local TLS quality scans on the correct branch and revision

## Problem

Review findings on [PR 6](https://github.com/stephenlclarke/swift-nio-ssl/pull/6) show that a local scan omits branch context and accepts coverage left behind by a different source checkout. That can replace main's measurements or attach historical coverage to a new commit.

## Expected behavior

Record the clean source revision before coverage generation and verify it again afterward. Admit only a matching revision and report checksum at scan time. Explicitly supply the local branch; preserve supported GitHub Actions pull-request detection.

## Compatibility

Old coverage needs one regeneration to create provenance sidecars. No threshold, source exclusion or baseline changes. See [implementation](PR-quality-refresh-20261019.md).

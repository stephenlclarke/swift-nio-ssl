# chore: synchronize container dependency with upstream

## Changes

Retain upstream certificate-directory suffix parsing and collision tests; preserve non-overlapping fork changes.

Upstream: [apple/swift-nio-ssl@322f3c2a4a21](https://github.com/apple/swift-nio-ssl/commit/322f3c2a4a21df31c84ca416bf65ee5e9059e440).

## Validation

Bazel NIOSSLTests passed (18.3 seconds). Source-only staged trees were tested through the reduced container Bazel workspace. Logs, test reports, and pre-merge bundles are retained under `ContainerFamily/retained/container-only/upstream-sync/20260927T123656Z`.

## Compatibility and risks

No history rewrite or dependency migration. This focused check does not claim a new complete container runtime benchmark.

## Related work

See [the matching issue](ISSUE-upstream-sync-20260927.md).

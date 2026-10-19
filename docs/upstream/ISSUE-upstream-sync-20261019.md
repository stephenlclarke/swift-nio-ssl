# Refresh BoringSSL and confine alert pointer handling

## Problem

The fork lacks upstream's BoringSSL refresh and closed-channel write correction. The review of [upstream PR 605](https://github.com/apple/swift-nio-ssl/pull/605) also asks that custom verification return an optional alert value instead of receiving a mutable alert pointer.

## Expected behavior

Retain upstream's complete generated BoringSSL sources and wrappers. Keep the fork's optional internal alert support, but write through the alert pointer only at the existing C callback boundary. Preserve default Darwin and public custom-verifier behavior.

## Compatibility

No public API, trust acceptance rule, published baseline or upper-layer dependency pin changes. See [implementation](PR-upstream-sync-20261019.md).

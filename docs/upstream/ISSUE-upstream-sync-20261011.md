# Synchronize the SSL fork with current Apple main

## Motivation

The Stephen-owned fork main at `aee34db2144717ddce7bd145e45cf4fb9dab73fb` predates Apple main `86458a336bf0f647b080c8637515bfefd8ea08b3`, including Apple's BoringSSL refresh to `8eb25be6fa18d475291122887a7bccd3762ff236`. The fork's narrow TLS fixes must remain available without substituting the smaller upstream PR branch for the full fork.

## Acceptance

Preserve the fork and Apple refs, merge the two current Apple commits, keep Apple's complete BoringSSL source and shim additions, and retain the fork's existing TLS corrections. Apply the reviewed [PR #605](https://github.com/apple/swift-nio-ssl/pull/605) tuple and role-scoped alert change without altering public verification behavior. Focused and full SSL tests must run before this synchronization is committed or published.

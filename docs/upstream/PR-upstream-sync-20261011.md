# chore: synchronize SSL fork with current Apple main

## Changes

Merge Apple `86458a336bf0f647b080c8637515bfefd8ea08b3` into Stephen fork `aee34db2144717ddce7bd145e45cf4fb9dab73fb`. Preserve the complete fork history and Apple BoringSSL refresh, combine the alert shim with Apple's added stack shims, and use the reviewed PR605 tuple return at the Swift verification boundary. The alert is explicit only for client-side Darwin trust rejection; server and public callback behavior remains under BoringSSL's selection.

## Validation

Static conflict and source review is complete. On this merged fork, `swift test --scratch-path /Volumes/SSD/q/ssl-sync-20261011 --jobs 4 --filter CustomVerifyManagerTests` passed 7/7, followed by the same command with `--filter NIOSSLTests` passing 348/348. Raw logs and their hashes are retained under `upstream-audit/ssl-sync`. These results validate the merged source locally; hosted checks and fresh downstream SSL layer admission remain separate.

## Compatibility and risks

The SwiftPM dependency declarations and minimum tools version are unchanged. `Package.swift` records Apple's new BoringSSL revision and removes its obsolete temporary symbol-mangling product comment. Existing lower-layer binary receipts cannot be relabeled as this source revision; a fresh SSL layer build and consumer proof will be needed. No history rewrite, push, or benchmark recapture has occurred.

## Related work

See [the matching issue](ISSUE-upstream-sync-20261011.md) and [PR #605](https://github.com/apple/swift-nio-ssl/pull/605).

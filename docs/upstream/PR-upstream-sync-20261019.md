# fix(sync): refresh TLS upstream and confine verification pointer handling

## Problem and behavior

Merge Apple `15e0b9e495786807272dd4891fa4bac76aa43034`, including BoringSSL and closed-channel write fixes. Retain the explicit bad-certificate constant alongside upstream's new C wrappers. Return verification status and optional alert as a tuple, as requested in the upstream review; the C callback performs the pointer write.

## Validation

Run the original TLS test suite, the custom-verifier alert regressions and source formatting against the updated library. Preserve raw failures and measured coverage. The fork keeps its previously validated default Darwin alert policy; this does not represent a newly accepted upstream alert policy or a new published dependency layer.

## Compatibility and risks

The generated BoringSSL update remains exactly upstream's source. No public callback signature changes. The internal optional alert is absent for successful, pending and public verification results. Related: [issue](ISSUE-upstream-sync-20261019.md) and [Apple PR 605](https://github.com/apple/swift-nio-ssl/pull/605).

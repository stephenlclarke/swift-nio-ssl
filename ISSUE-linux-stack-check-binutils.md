# Keep the Linux stack check available on current Swift images

<!-- markdownlint-disable MD013 -->

The Linux 6.4 integration job stopped during setup on the `swift:6.4-resolute` image because its Ubuntu repositories do not supply the `execstack` package. The integration script still needs to reject executable stack metadata in both debug and release server binaries; deleting that check or ignoring package-install failure would hide a security regression.

Use Ubuntu's available `binutils` package and inspect each binary's ELF `GNU_STACK` program header with `readelf --wide --program-headers`. Require exactly one non-executable header and fail on missing, malformed, or executable flags.

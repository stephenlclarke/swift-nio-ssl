# Use binutils for the Linux integration stack check

<!-- markdownlint-disable MD013 -->

CI and the Docker integration image install `binutils` in place of the unavailable `execstack` package. The integration test reads both debug and release server ELF program headers and rejects an executable, missing, or malformed `GNU_STACK` entry. Darwin retains its existing skip because it does not use ELF.

Ubuntu lists `binutils` for Resolute, including `/usr/bin/readelf`; GNU documents `readelf --program-headers --wide` as a single-line program-header view. See [Ubuntu package files](https://packages.ubuntu.com/resolute/all/binutils/filelist) and [GNU readelf documentation](https://sourceware.org/binutils/docs/binutils/readelf.html).

Validation: ShellCheck passed for the changed script. CPU-light mocked invocations passed for a non-executable stack and failed for executable, missing, and unreadable metadata. The original Linux 6.4 CI setup failure remains retained; hosted integration validation is pending the new commit.

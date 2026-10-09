#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftNIO open source project
##
## Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftNIO project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

# shellcheck source=IntegrationTests/tests_01_general/defines.sh
source defines.sh

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "No ELF stack check on Darwin"
    exit 0
fi

swift build -c debug
swift build -c release

DEBUG_SERVER_PATH="$(swift build --show-bin-path)/NIOTLSServer"
RELEASE_SERVER_PATH="$(swift build --show-bin-path -c release)/NIOTLSServer"

for binary in "$DEBUG_SERVER_PATH" "$RELEASE_SERVER_PATH"; do
    headers=$(readelf --wide --program-headers "$binary") || exit 1
    if ! printf '%s\n' "$headers" | awk '
        $1 == "GNU_STACK" {
            found++
            flags = ""
            for (field = 7; field < NF; field++) flags = flags $field
            if (flags !~ /^[RWE]+$/ || flags ~ /E/) invalid = 1
        }
        END { exit !(found == 1 && !invalid) }
    '; then
        echo "Executable or missing GNU_STACK program header: $binary" >&2
        exit 1
    fi
done

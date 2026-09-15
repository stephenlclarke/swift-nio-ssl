#!/usr/bin/env python3
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftNIO open source project
##
## Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftNIO project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

"""Tests for native LCOV to SonarQube coverage conversion."""

import importlib.util
import tempfile
import unittest
from pathlib import Path


def load_module():
    """Load the converter from its filesystem path."""
    path = Path(__file__).with_name("swift_coverage.py")
    spec = importlib.util.spec_from_file_location("swift_coverage", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


coverage = load_module()


class CoverageTests(unittest.TestCase):
    """Validate path confinement, exclusions, and report output."""

    def test_project_path_rejects_external_and_test_files(self) -> None:
        """Only production files below the checkout Sources directory qualify."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(
                coverage.project_path(str(root / "Sources/API.swift"), root),
                "Sources/API.swift",
            )
            self.assertIsNone(
                coverage.project_path(str(root / "Tests/APITests.swift"), root)
            )
            self.assertIsNone(
                coverage.project_path("/private/outside/Secret.swift", root)
            )

    def test_execution_lines_confines_and_excludes_sources(self) -> None:
        """Dependency and explicitly excluded source records are omitted."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = root / "coverage.lcov"
            report.write_text(
                "\n".join(
                    [
                        f"SF:{root}/Sources/API.swift",
                        "DA:1,1",
                        "DA:2,0",
                        "end_of_record",
                        f"SF:{root}/Sources/Vendored/C.c",
                        "DA:1,1",
                        "end_of_record",
                        "SF:/private/dependency/Sources/Dependency.swift",
                        "DA:1,1",
                        "end_of_record",
                    ]
                ),
                encoding="utf-8",
            )
            self.assertEqual(
                coverage.execution_lines(report, root, ("Sources/Vendored",)),
                {"Sources/API.swift": {1: 1, 2: 0}},
            )

    def test_execution_lines_combines_duplicate_records(self) -> None:
        """The greatest count wins when linked test bundles repeat a source."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = root / "coverage.lcov"
            report.write_text(
                "\n".join(
                    [
                        "SF:Sources/API.swift",
                        "DA:4,0",
                        "end_of_record",
                        "SF:Sources/API.swift",
                        "DA:4,3",
                        "end_of_record",
                    ]
                ),
                encoding="utf-8",
            )
            self.assertEqual(
                coverage.execution_lines(report, root, ()),
                {"Sources/API.swift": {4: 3}},
            )

    def test_writer_emits_expected_line_state(self) -> None:
        """Sonar XML preserves covered and uncovered native LCOV lines."""
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "coverage.xml"
            files = {"Sources/API.swift": {1: 2, 2: 0}}
            coverage.write_sonar(files, output)
            text = output.read_text(encoding="utf-8")
            self.assertIn('lineNumber="1" covered="true"', text)
            self.assertIn('lineNumber="2" covered="false"', text)


if __name__ == "__main__":
    unittest.main()

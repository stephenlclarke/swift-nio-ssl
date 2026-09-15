#!/usr/bin/env python3
"""Tests for SwiftPM coverage conversion."""

import importlib.util
import json
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
        """Only production files below the checkout's Sources directory qualify."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(
                coverage.project_path(str(root / "Sources/API.swift"), root),
                "Sources/API.swift",
            )
            self.assertIsNone(coverage.project_path(str(root / "Tests/APITests.swift"), root))
            self.assertIsNone(coverage.project_path("/private/outside/Secret.swift", root))

    def test_sonar_lines_ignores_non_executable_segments(self) -> None:
        """Gap and non-counted segments do not become executable lines."""
        item = {
            "segments": [
                [1, 1, 3, True, True, False],
                [2, 1, 0, True, True, False],
                [3, 1, 4, False, True, False],
                [4, 1, 7, True, True, True],
            ]
        }
        self.assertEqual(coverage.sonar_lines(item), {1: 3, 2: 0})

    def test_execution_lines_confines_and_excludes_sources(self) -> None:
        """Dependency and explicitly excluded source records are omitted."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            report = root / "coverage.json"
            report.write_text(
                json.dumps(
                    {
                        "data": [
                            {
                                "files": [
                                    {
                                        "filename": str(root / "Sources/API.swift"),
                                        "segments": [[1, 1, 1, True, True, False]],
                                    },
                                    {
                                        "filename": str(root / "Sources/Vendored/C.c"),
                                        "segments": [[1, 1, 1, True, True, False]],
                                    },
                                    {
                                        "filename": "/private/dependency/Sources/Dependency.swift",
                                        "segments": [[1, 1, 1, True, True, False]],
                                    },
                                ]
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            self.assertEqual(
                coverage.execution_lines(report, root, ("Sources/Vendored",)),
                {"Sources/API.swift": {1: 1}},
            )

    def test_writers_emit_expected_line_state(self) -> None:
        """LCOV and Sonar XML share the same covered-line state."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            lcov = root / "coverage.lcov"
            sonar = root / "coverage.xml"
            files = {"Sources/API.swift": {1: 2, 2: 0}}
            coverage.write_lcov(files, lcov)
            coverage.write_sonar(files, sonar)
            self.assertIn("DA:2,0", lcov.read_text(encoding="utf-8"))
            self.assertIn(
                'lineNumber="2" covered="false"',
                sonar.read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()

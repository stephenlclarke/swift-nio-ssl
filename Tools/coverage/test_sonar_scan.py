"""Exercise local scan admission through the actual Make target."""

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class SonarScanTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.output = self.root / "scanner.args"
        shutil.copy2(Path(__file__).resolve().parents[2] / "Makefile", self.root)
        self.git("init", "--quiet", "--initial-branch=feature/coverage")
        self.git("add", "Makefile")
        self.git("-c", "commit.gpgsign=false", "-c", "user.name=Test",
                 "-c", "user.email=test@example.invalid", "commit", "--quiet", "-m", "test: fixture")
        self.head = self.git("rev-parse", "HEAD")
        self.report = self.root / "coverage.xml"
        self.report.write_text('<coverage version="1"/>\n')
        (self.root / "coverage.source-revision").write_text(self.head + "\n")
        digest = hashlib.sha256(self.report.read_bytes()).hexdigest()
        (self.root / "coverage.xml.sha256").write_text(digest + "  coverage.xml\n")
        binary = self.root / "bin"
        binary.mkdir()
        scanner = binary / "sonar-scanner"
        scanner.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$SCAN_TEST_OUTPUT"\n')
        scanner.chmod(0o700)
        # Shell startup hooks must not replace the scanner double's PATH.
        self.environment = {key: value for key, value in os.environ.items()
                            if key in {"PATH", "HOME", "TMPDIR", "LANG", "LC_ALL"}}
        self.environment.update(PATH=str(binary) + os.pathsep + self.environment["PATH"],
                                SONAR_TOKEN="fixture-only", SCAN_TEST_OUTPUT=str(self.output))

    def git(self, *arguments):
        return subprocess.check_output(["git", *arguments], cwd=self.root, text=True).strip()

    def scan(self):
        return subprocess.run(["make", "--no-print-directory", "sonar-scan"],
                              cwd=self.root, env=self.environment,
                              capture_output=True, text=True, timeout=15)

    def rejected(self):
        result = self.scan()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.output.exists())

    def test_local_scan_supplies_branch_and_exact_version(self):
        result = self.scan()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = self.output.read_text().splitlines()
        self.assertIn("-Dsonar.branch.name=feature/coverage", arguments)
        self.assertIn("-Dsonar.projectVersion=" + self.head, arguments)

    def test_supported_ci_retains_automatic_context(self):
        self.environment["GITHUB_ACTIONS"] = "true"
        result = self.scan()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(any(value.startswith("-Dsonar.branch.name=")
                             for value in self.output.read_text().splitlines()))

    def test_missing_provenance_is_rejected(self):
        (self.root / "coverage.source-revision").unlink()
        self.rejected()

    def test_old_commit_provenance_is_rejected(self):
        (self.root / "coverage.source-revision").write_text("a" * 40 + "\n")
        self.rejected()

    def test_modified_report_is_rejected(self):
        self.report.write_text("different report\n")
        self.rejected()

    def test_dirty_source_is_rejected(self):
        with (self.root / "Makefile").open("a") as stream:
            stream.write("\n# changed source\n")
        self.rejected()

    def test_detached_local_scan_is_rejected(self):
        self.git("checkout", "--quiet", "--detach", self.head)
        self.rejected()

    def test_version_override_cannot_relabel_coverage(self):
        self.environment["SONAR_PROJECT_VERSION"] = "b" * 40
        self.rejected()


if __name__ == "__main__":
    unittest.main()

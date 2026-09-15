#!/usr/bin/env python3
"""Convert SwiftPM's LLVM JSON coverage into SonarQube reports."""

from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path


def project_path(filename: str, source_root: Path) -> str | None:
    """Return a project-relative production source path."""
    try:
        relative = Path(filename).resolve().relative_to(source_root.resolve()).as_posix()
    except ValueError:
        return None
    return relative if relative.startswith("Sources/") else None


def sonar_lines(item: dict[str, object]) -> dict[int, int]:
    """Return executable source lines and their greatest execution count."""
    lines: dict[int, int] = {}
    raw_segments = item.get("segments", [])
    if not isinstance(raw_segments, list):
        return lines
    for raw in raw_segments:
        if not isinstance(raw, list) or len(raw) < 6:
            continue
        line, column, execution_count, has_count, _, is_gap = raw[:6]
        if (
            isinstance(line, int)
            and line > 0
            and isinstance(column, int)
            and column > 0
            and isinstance(execution_count, int)
            and has_count is True
            and is_gap is False
        ):
            lines[line] = max(lines.get(line, 0), execution_count)
    return lines


def execution_lines(
    report: Path,
    source_root: Path,
    excluded_prefixes: tuple[str, ...],
) -> dict[str, dict[int, int]]:
    """Load first-party executable lines keyed by project-relative path."""
    document = json.loads(report.read_text(encoding="utf-8"))
    execution_by_file: dict[str, dict[int, int]] = {}
    for datum in document.get("data", []):
        for item in datum.get("files", []):
            filename = item.get("filename", "")
            if not isinstance(filename, str):
                continue
            relative = project_path(filename, source_root)
            if relative is None or relative.startswith(excluded_prefixes):
                continue
            target = execution_by_file.setdefault(relative, {})
            for line, count in sonar_lines(item).items():
                target[line] = max(target.get(line, 0), count)
    return execution_by_file


def write_lcov(files: dict[str, dict[int, int]], output: Path) -> None:
    """Write a deterministic LCOV report."""
    records: list[str] = []
    for filename, lines in sorted(files.items()):
        if not lines:
            continue
        covered = sum(count > 0 for count in lines.values())
        records.extend(
            [
                "TN:swift-package",
                f"SF:{filename}",
                *(f"DA:{line},{count}" for line, count in sorted(lines.items())),
                f"LF:{len(lines)}",
                f"LH:{covered}",
                "end_of_record",
            ]
        )
    output.write_text("\n".join(records) + "\n", encoding="utf-8")


def write_sonar(files: dict[str, dict[int, int]], output: Path) -> None:
    """Write SonarQube generic line-coverage XML."""
    root = ET.Element("coverage", {"version": "1"})
    for filename, lines in sorted(files.items()):
        if not lines:
            continue
        file_element = ET.SubElement(root, "file", {"path": filename})
        for line, count in sorted(lines.items()):
            ET.SubElement(
                file_element,
                "lineToCover",
                {
                    "lineNumber": str(line),
                    "covered": "true" if count > 0 else "false",
                },
            )
    ET.indent(root)
    ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)


def main() -> int:
    """Convert one SwiftPM LLVM JSON report."""
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--source-root", type=Path, default=Path.cwd())
    parser.add_argument("--exclude-prefix", action="append", default=[])
    parser.add_argument("--lcov-output", type=Path, required=True)
    parser.add_argument("--sonar-output", type=Path, required=True)
    args = parser.parse_args()

    files = execution_lines(
        args.report,
        args.source_root,
        tuple(args.exclude_prefix),
    )
    if not files:
        parser.error("coverage report contains no first-party source files")
    write_lcov(files, args.lcov_output)
    write_sonar(files, args.sonar_output)
    covered = sum(count > 0 for lines in files.values() for count in lines.values())
    total = sum(len(lines) for lines in files.values())
    print(f"Swift first-party line coverage: {covered * 100.0 / total:.2f}% ({covered}/{total})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

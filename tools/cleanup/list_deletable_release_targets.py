#!/usr/bin/env python3
"""Filters unused Bazel rules down to explicit, deletable declarations."""

import argparse
import json
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import xml.etree.ElementTree as ET


def run(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, **kwargs)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "List unused Bazel targets backed by explicit rule or macro "
            "declarations in tracked BUILD files."
        )
    )
    parser.add_argument(
        "--unused-targets",
        metavar="FILE",
        help=(
            "read unused labels from FILE instead of running "
            "list_unused_release_targets.sh; use '-' for stdin"
        ),
    )
    parser.add_argument(
        "--locations",
        action="store_true",
        help="print the BUILD-file location after each label",
    )
    return parser.parse_args()


def read_unused_labels(repo: Path, source: str | None) -> list[str]:
    if source == "-":
        contents = sys.stdin.read()
    elif source:
        contents = Path(source).read_text()
    else:
        result = run(
            [str(repo / "tools/cleanup/list_unused_release_targets.sh")],
            cwd=repo,
            stdout=subprocess.PIPE,
            text=True,
        )
        contents = result.stdout

    labels = sorted({line.strip() for line in contents.splitlines() if line.strip()})
    invalid = [label for label in labels if not label.startswith("//")]
    if invalid:
        raise ValueError(f"expected workspace labels, got: {invalid[0]}")
    return labels


def tracked_files(repo: Path) -> set[str]:
    result = run(
        ["git", "ls-files", "-z"],
        cwd=repo,
        stdout=subprocess.PIPE,
    )
    return {p.decode() for p in result.stdout.split(b"\0") if p}


def location_path(location: str) -> str:
    # Bazel locations end in :line:column. BUILD paths themselves may contain
    # colons on Windows, so split from the right.
    return location.rsplit(":", 2)[0]


def target_name(label: str) -> str:
    return label.rsplit(":", 1)[1]


def bazel_query_xml(repo: Path, expression: str) -> ET.Element:
    if not expression:
        return ET.Element("query")
    bazel = shutil.which("bazelisk") or shutil.which("bazel")
    if not bazel:
        raise RuntimeError("could not find bazelisk or bazel in PATH")
    result = run(
        [bazel, "query", "--noshow_progress", "--output=xml", expression],
        cwd=repo,
        stdout=subprocess.PIPE,
    )
    return ET.fromstring(result.stdout)


def query_rules(repo: Path, labels: list[str]) -> ET.Element:
    if not labels:
        return ET.Element("query")
    expression = f"set({' '.join(json.dumps(label) for label in labels)})"
    return bazel_query_xml(repo, expression)


def package_pattern(label: str) -> str:
    package = label.rsplit(":", 1)[0]
    return f"{package}:*"


def main() -> int:
    args = parse_args()
    repo = Path(__file__).resolve().parents[2]
    labels = read_unused_labels(repo, args.unused_targets)
    tracked = tracked_files(repo)
    query = query_rules(repo, labels)
    candidate_rules = query.findall("rule")

    # A macro's primary target may be unused even though auxiliary targets from
    # the same invocation are retained. Deleting that invocation would remove
    # the retained siblings too. Query all rules in candidate packages so we
    # only emit a macro invocation when every rule it generated is unused.
    packages = sorted({package_pattern(rule.get("name", "")) for rule in candidate_rules})
    package_expression = f"set({' '.join(json.dumps(package) for package in packages)})"
    package_rules = bazel_query_xml(repo, package_expression).findall("rule")
    siblings_by_location: dict[str, set[str]] = {}
    for rule in package_rules:
        generator_location = next(
            (
                child.get("value", "")
                for child in rule
                if child.tag == "string" and child.get("name") == "generator_location"
            ),
            "",
        )
        if generator_location:
            siblings_by_location.setdefault(generator_location, set()).add(
                rule.get("name", "")
            )

    emitted = 0
    label_set = set(labels)
    for rule in candidate_rules:
        label = rule.get("name", "")
        location = rule.get("location", "")
        path = Path(location_path(location))
        try:
            relative_path = path.resolve().relative_to(repo).as_posix()
        except ValueError:
            # Generated repositories and external workspaces are not deletable
            # declarations in this repository.
            continue
        if relative_path not in tracked:
            continue

        attributes = {
            child.get("name"): child.get("value")
            for child in rule
            if child.tag == "string"
        }
        generator_name = attributes.get("generator_name")
        if generator_name and generator_name != target_name(label):
            # This is an auxiliary target emitted by a macro invocation. The
            # invocation cannot be removed unless its primary target is unused.
            continue
        generator_location = attributes.get("generator_location")
        if generator_location and not siblings_by_location.get(
            generator_location, set()
        ).issubset(label_set):
            # The primary target is unused, but deleting its macro invocation
            # would also delete at least one generated target that is retained.
            continue

        if args.locations:
            print(f"{label}\t{relative_path}:{':'.join(location.rsplit(':', 2)[1:])}")
        else:
            print(label)
        emitted += 1

    print(
        f"Found {emitted} deletable declarations among {len(labels)} unused rules.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)

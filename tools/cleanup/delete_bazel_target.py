#!/usr/bin/env python3
"""Safely deletes one unused Bazel declaration and exclusively owned sources."""

import argparse
import json
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import xml.etree.ElementTree as ET


SOURCE_ATTRIBUTES = ("srcs", "embedsrcs")
BUILDOZER_TARGET = "@com_github_bazelbuild_buildtools//buildozer:buildozer"


def run(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, **kwargs)


def bazel(repo: Path) -> str:
    command = shutil.which("bazelisk") or shutil.which("bazel")
    if not command:
        raise RuntimeError("could not find bazelisk or bazel in PATH")
    return command


def query_xml(repo: Path, expression: str) -> ET.Element:
    result = run(
        [bazel(repo), "query", "--noshow_progress", "--output=xml", expression],
        cwd=repo,
        stdout=subprocess.PIPE,
    )
    return ET.fromstring(result.stdout)


def string_attributes(rule: ET.Element) -> dict[str, str]:
    return {
        child.get("name", ""): child.get("value", "")
        for child in rule
        if child.tag == "string"
    }


def location_path(location: str) -> str:
    return location.rsplit(":", 2)[0]


def package_pattern(label: str) -> str:
    return f"{label.rsplit(':', 1)[0]}:*"


def source_labels(rule: ET.Element) -> set[str]:
    labels = set()
    for child in rule:
        if child.tag != "list" or child.get("name") not in SOURCE_ATTRIBUTES:
            continue
        labels.update(item.get("value", "") for item in child if item.tag == "label")
    return labels


def source_files(repo: Path, labels: set[str]) -> dict[str, Path]:
    if not labels:
        return {}
    expression = f"set({' '.join(json.dumps(label) for label in sorted(labels))})"
    query = query_xml(repo, expression)
    files = {}
    for source in query.findall("source-file"):
        label = source.get("name", "")
        path = Path(location_path(source.get("location", ""))).resolve()
        try:
            path.relative_to(repo)
        except ValueError:
            continue
        files[label] = path
    return files


def rule_owners(repo: Path, source_label: str) -> set[str]:
    expression = f"kind(\".* rule\", rdeps(//..., {json.dumps(source_label)}, 1))"
    return {
        rule.get("name", "") for rule in query_xml(repo, expression).findall("rule")
    }


def deletable_targets(repo: Path) -> set[str]:
    result = run(
        [str(repo / "tools/cleanup/list_deletable_release_targets.py")],
        cwd=repo,
        stdout=subprocess.PIPE,
        text=True,
    )
    return {line.strip() for line in result.stdout.splitlines() if line.strip()}


def require_clean_worktree(repo: Path) -> None:
    result = run(
        ["git", "status", "--porcelain"],
        cwd=repo,
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.stdout:
        raise ValueError("--apply requires a clean Git worktree")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Delete one explicit unused Bazel target and tracked source files "
            "owned exclusively by its declaration. The default is a dry run."
        )
    )
    parser.add_argument("target", help="an absolute workspace label, such as //pkg:target")
    parser.add_argument(
        "--apply",
        action="store_true",
        help="perform the BUILD edit and file deletions",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path(__file__).resolve().parents[2]
    if not args.target.startswith("//") or ":" not in args.target:
        raise ValueError("target must be an absolute workspace label containing ':'")

    if args.target not in deletable_targets(repo):
        raise ValueError(
            f"{args.target} is not in the current deletable-target list; refusing"
        )

    target_query = query_xml(repo, json.dumps(args.target))
    rules = target_query.findall("rule")
    if len(rules) != 1:
        raise ValueError(f"expected exactly one rule for {args.target}")
    rule = rules[0]
    location = rule.get("location", "")
    build_file = Path(location_path(location)).resolve()
    try:
        build_relative = build_file.relative_to(repo)
    except ValueError as error:
        raise ValueError("target declaration is outside this repository") from error

    attributes = string_attributes(rule)
    generator_location = attributes.get("generator_location")
    generated_siblings = {args.target}
    if generator_location:
        package_rules = query_xml(repo, json.dumps(package_pattern(args.target)))
        generated_siblings = {
            sibling.get("name", "")
            for sibling in package_rules.findall("rule")
            if string_attributes(sibling).get("generator_location")
            == generator_location
        }

    files = source_files(repo, source_labels(rule))
    exclusive_files = []
    shared_files = []
    for label, path in sorted(files.items()):
        owners = rule_owners(repo, label)
        if owners.issubset(generated_siblings):
            exclusive_files.append(path)
        else:
            shared_files.append((path, owners - generated_siblings))

    print(f"Target:       {args.target}")
    print(f"Declaration:  {build_relative}:{':'.join(location.rsplit(':', 2)[1:])}")
    if generated_siblings != {args.target}:
        print(f"Macro rules:  {len(generated_siblings)} rules from the same invocation")
    print("Delete files:")
    if exclusive_files:
        for path in exclusive_files:
            print(f"  {path.relative_to(repo)}")
    else:
        print("  (none)")
    if shared_files:
        print("Keep shared files:")
        for path, owners in shared_files:
            print(f"  {path.relative_to(repo)} ({', '.join(sorted(owners))})")

    if not args.apply:
        print("Dry run only; pass --apply to make these changes.")
        return 0

    require_clean_worktree(repo)
    run(
        [
            bazel(repo),
            "run",
            "--noshow_progress",
            BUILDOZER_TARGET,
            "--",
            "delete",
            args.target,
        ],
        cwd=repo,
    )
    for path in exclusive_files:
        path.unlink()

    test_script = repo / "tools/cleanup/test_release_root.sh"
    try:
        run([str(test_script), "--all"], cwd=repo)
    except subprocess.CalledProcessError:
        stash_message = f"Failed deletion of {args.target}"
        run(
            [
                "git",
                "stash",
                "push",
                "--include-untracked",
                "--message",
                stash_message,
            ],
            cwd=repo,
        )
        print(
            f"Test gate failed; deletion changes were stashed as: {stash_message}",
            file=sys.stderr,
        )
        raise

    changed = set(
        run(
            ["git", "diff", "--name-only"],
            cwd=repo,
            stdout=subprocess.PIPE,
            text=True,
        ).stdout.splitlines()
    )
    untracked = set(
        run(
            ["git", "ls-files", "--others", "--exclude-standard"],
            cwd=repo,
            stdout=subprocess.PIPE,
            text=True,
        ).stdout.splitlines()
    )
    expected = {build_relative.as_posix()}
    expected.update(path.relative_to(repo).as_posix() for path in exclusive_files)
    unexpected = (changed | untracked) - expected
    if unexpected:
        raise ValueError(
            "tests or deletion tooling changed unexpected files; refusing to commit: "
            + ", ".join(sorted(unexpected))
        )

    run(["git", "add", "--", *sorted(expected)], cwd=repo)
    run(
        ["git", "commit", "-m", f"Remove unused Bazel target {args.target}"],
        cwd=repo,
    )
    print("Deletion tested and committed. Removed files remain recoverable via Git.")
    return 0


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)

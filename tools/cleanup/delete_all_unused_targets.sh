#!/usr/bin/env bash

# Attempts each target in a snapshot of the deletable-target list. Successful
# deletions are tested and committed by delete_bazel_target.py. Failed attempts
# are recorded and do not stop later targets from being tried.

set -uo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repo="$(cd "${script_dir}/../.." && pwd)"
readonly failure_file="${CLEANUP_FAILURE_FILE:-/tmp/buildbuddy-delete-unused-targets.failed}"
readonly targets_file="$(mktemp)"
trap 'rm -f "$targets_file"' EXIT

cd "$repo"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Refusing to start with a dirty worktree." >&2
  exit 1
fi

: >"$failure_file"
"${script_dir}/list_deletable_release_targets.py" >"$targets_file"
target_count="$(wc -l <"$targets_file")"
attempted_count=0
failed_count=0

echo "Snapshot contains ${target_count} deletable targets."
echo "Failed targets will be written to ${failure_file}."

while IFS= read -r target; do
  ((attempted_count += 1))
  echo
  echo "[${attempted_count}/${target_count}] Attempting ${target}"

  if "${script_dir}/delete_bazel_target.py" --apply "$target"; then
    continue
  fi

  ((failed_count += 1))
  printf '%s\n' "$target" >>"$failure_file"

  # Test-gate failures are stashed by the deletion tool. Preserve changes from
  # any other failure mode too, so the next attempt starts from a clean tree.
  if [[ -n "$(git status --porcelain)" ]]; then
    stash_message="Failed deletion of ${target}"
    if ! git stash push --include-untracked --message "$stash_message"; then
      echo "Could not stash changes after ${target}; stopping." >&2
      exit 1
    fi
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Worktree is still dirty after ${target}; stopping." >&2
    exit 1
  fi

  echo "Continuing after failed deletion of ${target}." >&2
done <"$targets_file"

echo
echo "Finished: ${attempted_count} attempted, ${failed_count} failed."
echo "Failed targets: ${failure_file}"

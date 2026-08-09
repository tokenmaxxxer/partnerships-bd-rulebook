#!/usr/bin/env bash
# Each partnerships-bd methodology plugin owns its own gate test file, run
# here as its own subprocess suite.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Convention: docs/specs/test-env-resolution.md (on-the-record issue #551) —
# a suite exit 75 means SKIP (core unreachable), not a suite failure.
overall_fail=0
skipped=0
for suite in strategic-fit-gate multi-axis-scoring batna-zopa \
             evidence-discipline term-sheet-structure; do
  echo; echo "-- $suite --"
  bash "$HERE/$suite-tests.sh"
  rc=$?
  if [ "$rc" -eq 75 ]; then
    skipped=$((skipped+1))
  elif [ "$rc" -ne 0 ]; then
    overall_fail=1
  fi
done

if [ "$skipped" -gt 0 ]; then
  echo; echo "-- $skipped skipped --"
fi

exit "$overall_fail"

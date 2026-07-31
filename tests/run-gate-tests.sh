#!/usr/bin/env bash
# Each partnerships-bd methodology plugin owns its own gate test file, run
# here as its own subprocess suite.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

overall_fail=0
for suite in strategic-fit-gate multi-axis-scoring batna-zopa \
             evidence-discipline term-sheet-structure; do
  echo; echo "-- $suite --"
  bash "$HERE/$suite-tests.sh" || overall_fail=1
done

exit "$overall_fail"

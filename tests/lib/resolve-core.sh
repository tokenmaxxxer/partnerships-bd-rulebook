#!/usr/bin/env bash
# Bash-native reimplementation of the canonical core-resolution order and
# SKIP contract defined at docs/specs/test-env-resolution.md (on-the-record
# issue #551): CLAUDE_PLUGIN_ROOT_CORE (non-empty hooks/lib/gate-lib.sh) ->
# caller-supplied sibling candidates -> SKIP (exit 75, explicit stderr
# message). See docs/issue-19/decisions/2026-08-09-bash-native-resolver.md
# for why this is bash-native rather than the convention's Python reference
# module.
#
# Usage: resolve_core <candidate-dir> [<candidate-dir> ...]
#   Prints the resolved core root (containing hooks/lib/gate-lib.sh) to
#   stdout and returns 0 on success.
#   On failure, prints the SKIP message to stderr and returns 75.
resolve_core() {
  if [ -n "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] && [ -s "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/gate-lib.sh" ]; then
    printf '%s\n' "$CLAUDE_PLUGIN_ROOT_CORE"
    return 0
  fi
  for cand in "$@"; do
    if [ -s "$cand/hooks/lib/gate-lib.sh" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  echo "SKIP: core plugin unreachable — unverifiable outside spawn env" >&2
  return 75
}

#!/usr/bin/env bash
# Show that run.sh reports unexpected outcomes with a nonzero exit status.
# Copies the harness, breaks two expectations, and runs QUICK=1 ./run.sh on the copy:
#   * the perf guard limit is raised to 100000, so the baseline's expected failure disappears
#   * the first correctness example is closed with `simp` (which fails) instead of `omega`
set -uo pipefail
here="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
cp -r "$here/harness" "$here/patch" "$tmp/"
cd "$tmp/harness" && rm -rf results bench .lake/build/lib/lean/OmegaAB* 2>/dev/null
sed -i 's/maxHeartbeats 1000/maxHeartbeats 100000/' tests/omega_int_not_dvd_perf.lean
sed -i '0,/by omega$/s//by simp/' tests/omega_int_not_dvd.lean
QUICK=1 ./run.sh > fault.log 2>&1; code=$?
grep -E "UNEXPECTED|RESULT" fault.log
echo "run.sh exit status on the broken copy: $code (expected 1)"
cp fault.log "$here/harness/results/fault_injection.log" 2>/dev/null || true
rm -rf "$tmp"
[ $code -eq 1 ]

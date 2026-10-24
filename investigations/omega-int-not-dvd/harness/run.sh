#!/usr/bin/env bash
# Reproduce every number in REPORT.md. Requires the nightly-2026-10-23 toolchain on PATH (elan reads lean-toolchain).
set -euo pipefail
cd "$(dirname "$0")"
lean --version
lake build
mkdir -p results/trace bench/one suite
V="omega_base omega_patched2 omega_patched3"
for t in $V; do
  python3 gen/gen.py $t bench 31 > bench/bench_$t.lean
  lake lean bench/bench_$t.lean > results/bench_$t.txt 2>&1
  lake lean bench/bench_$t.lean > results/bench2_$t.txt 2>&1
  for w in $(python3 gen/gen.py x list); do
    python3 gen/gen.py $t one:$w > bench/one/${t}__$w.lean
    lake lean bench/one/${t}__$w.lean > results/trace/${t}__$w.txt 2>&1 || true
  done
done
python3 gen/table.py | tee results/table.md
# builtin omega must match the baseline copy split-for-split
for w in $(python3 gen/gen.py x list); do
  python3 gen/gen.py omega one:$w > bench/one/omega__$w.lean
  a=$(lake lean bench/one/omega__$w.lean 2>&1 | grep -c "Case splitting on" || true)
  b=$(grep -c "Case splitting on" results/trace/omega_base__$w.txt || true)
  [ "$a" = "$b" ] || echo "MISMATCH builtin vs baseline on $w: $a vs $b"
done
# core omega tests through each variant
for f in omega.lean omega_examples.lean omegaCanon.lean; do
  for t in $V; do
    python3 gen/subst.py tests_core/$f $t > suite/${t}__$f
    lake lean suite/${t}__$f > suite/${t}__$f.out 2>&1; echo "exit $?" >> suite/${t}__$f.out
  done
  for t in omega_patched2 omega_patched3; do
    diff <(sed "s/omega_base/OMEGA/g" suite/omega_base__$f.out) <(sed "s/$t/OMEGA/g" suite/${t}__$f.out) >/dev/null \
      && echo "core $f: $t identical to baseline" || echo "core $f: $t DIFFERS"
  done
done
# proposed regression test: expected to fail on builtin/baseline (heartbeat guard), pass on both patches
for t in omega $V; do
  python3 gen/subst.py tests/omega_int_not_dvd.lean $t > bench/test_$t.lean
  if lake lean bench/test_$t.lean > results/test_$t.txt 2>&1; then echo "regression test with $t: PASS"; else echo "regression test with $t: FAIL"; fi
done

#!/usr/bin/env bash
# Reproduce every result in REPORT.md and check each one against its expected outcome.
# Exit status 0: every outcome as expected (including the expected baseline failures listed below).
# Exit status 1: at least one unexpected result; see the UNEXPECTED lines and results/summary.txt.
#
# Requires the toolchain pinned in lean-toolchain (elan picks it up), python3, patch.
# Set BENCH_N to change the repetitions per benchmark (default 31).
# Set QUICK=1 to run only the build, tests and core-suite checks (sections 2, 2b, 3).
set -uo pipefail
cd "$(dirname "$0")"
N="${BENCH_N:-31}"
VARIANTS="omega_base omega_eager omega_lazy"
ALL="omega $VARIANTS"   # `omega` = the toolchain's builtin tactic
mkdir -p results/trace results/tests results/core bench/one bench/tests
: > results/summary.txt
unexpected=0
note()  { echo "$*" | tee -a results/summary.txt; }
ok()    { note "ok          $*"; }
bad()   { note "UNEXPECTED  $*"; unexpected=$((unexpected + 1)); }

# Error lines in Lean output: "<file>:<line>:<col>[-<line>:<col>]: error: <msg>"
errors_of() { grep -E '\.lean:[0-9]+:[0-9]+(-[0-9]+:[0-9]+)?: error' "$1" || true; }

# expect LABEL FILE OUT pass|fail REGEX [COUNT]
#   pass: exit 0 and no error lines
#   fail: nonzero exit, at least one error line (exactly COUNT if given), every one matching REGEX
expect() {
  local label=$1 file=$2 out=$3 want=$4 regex=${5:-} count=${6:-}
  lake lean "$file" > "$out" 2>&1; local code=$?
  local errs; errs=$(errors_of "$out")
  if [ "$want" = pass ]; then
    if [ $code -eq 0 ] && [ -z "$errs" ]; then ok "$label: passes"; else bad "$label: expected to pass (exit $code)"; fi
  else
    local nonmatching; nonmatching=$(echo "$errs" | grep -Ev -- "$regex" | grep -v '^$' || true)
    local nerr; nerr=$(echo "$errs" | grep -c . || true)
    if [ $code -ne 0 ] && [ -n "$errs" ] && [ -z "$nonmatching" ] && { [ -z "$count" ] || [ "$nerr" = "$count" ]; }; then
      ok "$label: fails as expected (${count:-$nerr} × $regex)"
    else
      bad "$label: expected ${count:-some} failure(s) matching '$regex' (exit $code, $nerr error lines)"
    fi
  fi
}

note "== toolchain"; lean --version | tee -a results/summary.txt
note "== prepare + build"
./gen/prepare.sh | tee -a results/summary.txt || { bad "prepare.sh failed"; exit 1; }
lake build > results/build.txt 2>&1 && ok "lake build" || { bad "lake build failed (results/build.txt)"; exit 1; }

if [ -z "${QUICK:-}" ]; then
note "== 1. baseline copy reproduces builtin omega (case splits per workload)"
for w in $(python3 gen/gen.py x list); do
  for t in $ALL; do
    python3 gen/gen.py $t one:$w > bench/one/${t}__$w.lean
    lake lean bench/one/${t}__$w.lean > results/trace/${t}__$w.txt 2>&1 || bad "trace $t/$w: elaboration failed"
  done
  a=$(grep -c "Case splitting on" results/trace/omega__$w.txt)
  b=$(grep -c "Case splitting on" results/trace/omega_base__$w.txt)
  [ "$a" = "$b" ] || bad "builtin vs baseline splits differ on $w ($a vs $b)"
done
ok "split counts compared on $(python3 gen/gen.py x list | wc -l) workloads"
fi

note "== 2. tests"
HB='maximum number of heartbeats \(1000\) has been reached'
for t in $ALL; do
  for f in omega_int_not_dvd omega_int_not_dvd_limits omega_int_not_dvd_perf; do
    python3 gen/subst.py tests/$f.lean $t > bench/tests/${f}__$t.lean
  done
  python3 gen/subst.py repro/hmod_int_sub.lean $t > bench/tests/hmod_int_sub__$t.lean
  expect "$t correctness"  bench/tests/omega_int_not_dvd__$t.lean        results/tests/correct_$t.txt pass
  expect "$t limitations"  bench/tests/omega_int_not_dvd_limits__$t.lean results/tests/limits_$t.txt  pass
  case $t in
    omega|omega_base) expect "$t perf guard" bench/tests/omega_int_not_dvd_perf__$t.lean results/tests/perf_$t.txt fail "$HB" 1 ;;
    *)                expect "$t perf guard" bench/tests/omega_int_not_dvd_perf__$t.lean results/tests/perf_$t.txt pass ;;
  esac
  # separate finding, unchanged by either patch
  expect "$t hmod repro" bench/tests/hmod_int_sub__$t.lean results/tests/hmod_$t.txt fail 'Application type mismatch' 1
  python3 gen/subst.py repro/hmod_followup_cases.lean $t > bench/tests/hmod_cases__$t.lean
  expect "$t hmod cases" bench/tests/hmod_cases__$t.lean results/tests/hmod_cases_$t.txt fail 'Application type mismatch|omega could not prove the goal' 8
done

note "== 2b. follow-up: groundInt? in the HMod case (patch/followup-hmod-groundInt.patch)"
t=omega_gi
for f in omega_int_not_dvd omega_int_not_dvd_limits; do python3 gen/subst.py tests/$f.lean $t > bench/tests/${f}__$t.lean; done
python3 gen/subst.py repro/hmod_int_sub.lean $t > bench/tests/hmod_int_sub__$t.lean
python3 gen/subst.py repro/hmod_followup_cases.lean $t > bench/tests/hmod_cases__$t.lean
expect "$t correctness" bench/tests/omega_int_not_dvd__$t.lean results/tests/correct_$t.txt pass
expect "$t hmod repro"  bench/tests/hmod_int_sub__$t.lean     results/tests/hmod_$t.txt pass
expect "$t hmod cases"  bench/tests/hmod_cases__$t.lean       results/tests/hmod_cases_$t.txt pass
# the limitations file's first two goals become provable, so `fail_if_success omega` must now trip
expect "$t limitations" bench/tests/omega_int_not_dvd_limits__$t.lean results/tests/limits_$t.txt fail 'succeeded but was expected to fail' 2

note "== 3. Lean's own omega tests through each variant"
for f in omega.lean omega_examples.lean omegaCanon.lean; do
  for t in $VARIANTS omega_gi; do
    python3 gen/subst.py tests_core/$f $t > bench/tests/core_${t}__$f
    lake lean bench/tests/core_${t}__$f > results/core/${t}__$f.out 2>&1
    echo "exit $?" >> results/core/${t}__$f.out
  done
  n=$(grep -cE '(^|[^[:alnum:]_.])omega_base' bench/tests/core_omega_base__$f)
  grep -q "^exit 0$" results/core/omega_base__$f.out && ok "core $f: baseline passes ($n omega calls)" || bad "core $f: baseline fails"
  for t in omega_eager omega_lazy omega_gi; do
    if diff <(sed "s/omega_base/OMEGA/g" results/core/omega_base__$f.out) <(sed "s/$t/OMEGA/g" results/core/${t}__$f.out) > /dev/null; then
      ok "core $f: $t output identical to baseline"
    else
      bad "core $f: $t output differs from baseline"
    fi
  done
done

if [ -z "${QUICK:-}" ]; then
note "== 4. deferred-fact invariant (lazy) and absence of deferral (baseline, eager)"
# the checker itself: accepts the good synthetic trace, rejects each bad one
python3 gen/check_pending.py lazy gen/selftest/good.txt > /dev/null || bad "checker self-test: good trace rejected"
for s in gen/selftest/bad_*.txt; do
  python3 gen/check_pending.py lazy "$s" > /dev/null && bad "checker self-test: $(basename $s) accepted"
done
ok "checker self-test (1 good, $(ls gen/selftest/bad_*.txt | wc -l) bad synthetic traces)"
python3 gen/check_pending.py lazy results/trace/omega_lazy__*.txt > results/pending_lazy.txt \
  && ok "lazy: D1-D4 hold on all $(ls results/trace/omega_lazy__*.txt | wc -l) traces" \
  || bad "lazy: deferred-fact invariant violated (results/pending_lazy.txt)"
python3 gen/check_pending.py none results/trace/omega_base__*.txt results/trace/omega_eager__*.txt > results/pending_none.txt \
  && ok "baseline/eager: no deferrals" || bad "baseline/eager: unexpected deferral"
awk '{d+=substr($3,10); f+=substr($4,9); u+=substr($5,8)} END {print "      lazy totals: deferred", d, "| flushes", f, "| deferred but unused (refuted first)", u}' results/pending_lazy.txt | tee -a results/summary.txt

note "== 5. benchmarks (N=$N, two full runs)"
for t in $VARIANTS; do
  python3 gen/gen.py $t bench "$N" > bench/bench_$t.lean
  lake lean bench/bench_$t.lean > results/bench_$t.txt 2>&1 || bad "bench $t run 1 failed"
  lake lean bench/bench_$t.lean > results/bench2_$t.txt 2>&1 || bad "bench $t run 2 failed"
done
python3 gen/table.py > results/table.log && ok "benchmarks complete; heartbeats deterministic" \
  || { cat results/table.log | grep PROBLEM | tee -a results/summary.txt; bad "benchmark consistency"; }
fi

note "== summary"
if [ $unexpected -eq 0 ]; then note "ALL RESULTS AS EXPECTED"; exit 0
else note "$unexpected UNEXPECTED RESULT(S)"; exit 1; fi

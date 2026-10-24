<!--
Draft for leanprover/lean4, bug report template. NOT FILED.
Before filing: tick the prerequisites honestly (search existing issues; re-run on the then-latest
nightly or live.lean-lang.org), fill in the AI-assistance note, and keep the numbers in sync with
REPORT.md if anything is re-measured.
-->

**Title:** `omega`: `¬ k ∣ x` on `Int` case-splits on `k = 0` even for a literal `k`, which can cause exponentially many case splits

### Prerequisites

* [ ] Check that your issue is not already filed:
      https://github.com/leanprover/lean4/issues
* [x] Reduce the issue to a minimal, self-contained, reproducible test case.
      Avoid dependencies to Mathlib or Batteries.
* [ ] Test your test case against the latest nightly release, for example on
      https://live.lean-lang.org/#project=lean-nightly
* [x] When reporting a perceived soundness bug: n/a (performance only; every proof `omega` produces type-checks).

### Description

`omega` turns a hypothesis `h : ¬ k ∣ x` with `x : Int` into the disjunction `k = 0 ∨ 0 < x % k` (`Int.emod_pos_of_not_dvd`), even when `k` is a nonzero numeral. On `Nat`, the same hypothesis becomes the plain fact `0 < x % k`. The source already notes this (`src/Lean/Elab/Tactic/Omega/Frontend.lean`, `pushNot`):

```lean
      | Int =>
        -- This introduces a disjunction that could be avoided by checking `k ≠ 0`.
        return some (mkApp3 (.const ``Int.emod_pos_of_not_dvd []) k x h)
```

`omega` splits stored disjunctions only after the problem survives without them, last-in first-out. So the fact `0 < x % k` becomes available only after every disjunction registered *after* `h` has been split. With `r` unrelated `y ≠ c` hypotheses following `h`, that is `2^(r+1) - 1` case splits.

### Context

Found while writing `omega` regression tests for residue-class arguments (sieve-style statements about `n % 30` and divisibility by 2, 3, 5).

### Steps to Reproduce

```lean
-- 1 split (the `3 = 0` branch is refuted at once)
example (x : Int) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega

-- 511 splits; fails under a limit of 1000 heartbeats (needs ≈ 4 200)
set_option maxHeartbeats 1000 in
example (x y0 y1 y2 y3 y4 y5 y6 y7 : Int) (h : ¬ 3 ∣ x)
    (n0 : y0 ≠ 0) (n1 : y1 ≠ 1) (n2 : y2 ≠ 2) (n3 : y3 ≠ 3)
    (n4 : y4 ≠ 4) (n5 : y5 ≠ 5) (n6 : y6 ≠ 6) (n7 : y7 ≠ 7)
    (h' : x % 3 = 0) : False := by omega
```

Count the splits with `set_option trace.omega true` (lines `Case splitting on …`).

**Expected behavior:** as for `Nat`: with a nonzero literal `k`, `¬ k ∣ x` contributes `0 < x % k`, both examples close without case splits, and the second fits comfortably in 1000 heartbeats.

**Actual behavior:**

| `≠` hypotheses after `h` | case splits | heartbeats | elaboration time |
| --- | --- | --- | --- |
| 0 | 1 | 43 704 | 4.1 ms |
| 2 | 7 | 83 676 | 6.7 ms |
| 4 | 31 | 250 441 | 18 ms |
| 6 | 127 | 975 713 | 73 ms |
| 8 | 511 | 4 184 519 | 289 ms |

With the `≠` hypotheses placed *before* `h`, the count stays at 1 split. Heartbeats are the raw `IO.getNumHeartbeats` difference around the tactic; times are medians of 31 runs on a 2-core x86-64 machine.

### Versions

`Lean (version 4.37.0-nightly-2026-10-23, x86_64-unknown-linux-gnu, commit f37a0276ae8b0c60dd705920c49b9fd0c16279cf, Release)`, Linux x86-64.

### Additional Information

We prototyped two changes out of tree. Each was measured as a copy of `Frontend.lean` beside the builtin tactic; neither has been built inside the compiler yet. Both use one helper lemma in `Init/Omega/Int.lean`:

```lean
theorem emod_pos_of_not_dvd_of_bne {a b : Int} (w : (a != 0) = true) (h : ¬ a ∣ b) :
    0 < b % a :=
  (Int.emod_pos_of_not_dvd h).resolve_left fun h0 => by simp [h0] at w
```

1. **Eager** (+7/−1 in `Frontend.lean`). When `groundInt? k` is nonzero, `pushNot` returns `0 < x % k` directly, matching `Nat`. Zero and symbolic `k` keep the disjunction.
2. **Deferred** (+25/−3). The same fact goes into a new `MetaProblem.pending` list. That list is added once the problem survives without it, and always before any disjunction is split.

Heartbeats relative to current `omega` (deterministic; selected workloads):

| workload | eager | deferred |
| --- | --- | --- |
| the 8-`≠` example above | −99 % | −99 % |
| 16 needed `¬ 2 ∣ xᵢ` facts | −23 % | −9 % |
| 16 *unused* `¬ 3 ∣ yᵢ` hypotheses | +503 % | −3 % |
| first example above | +12 % | −4 % |
| `¬ 2 ∣ n, ¬ 3 ∣ n ⊢ n % 6 = 1 ∨ n % 6 = 5` | +27 % | +22 % |
| 8 needed facts and an `=` goal | −1 % | +16 % |

The eager form makes unused `Int` hypotheses cost what unused `Nat` ones already cost. With 16 such hypotheses that is about 10 ms of elaboration against about 2 ms today, and kernel checking grows from about 4 ms to 11 ms because the proof term is 5× larger. The deferred form avoids that cost but adds a step to `omega`'s search loop. Kernel checking time is unaffected by the case-split blow-up, since failed branches leave no trace in the proof: for the 8-`≠` example it is about 6–7 ms with or without either change. Both pass `tests/elab/omega.lean`, `omega_examples.lean` and `omegaCanon.lean` with output identical to the current tactic. Both also produce the same results as the current tactic on 27 further examples: negative, zero, and computed literals, plus reordered, repeated, and nested hypotheses.

Questions for maintainers:

1. Is a change here welcome?
2. If so, would you prefer the eager form (smallest diff, `Nat` parity) or the deferred form (keeps unused hypotheses cheap)?
3. Would you rather address split ordering in general? The `splitDisjunctions` docstring already notes that irrelevant disjunctions are split too.

We are happy to open a PR with tests along whichever line you prefer.

*AI assistance:* [state here which parts were prepared with AI assistance and that the author has checked them, per CONTRIBUTING.md]

### Impact

Add :+1: to [issues you consider important](https://github.com/leanprover/lean4/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc). If others are impacted by this issue, please ask them to add :+1: to it.

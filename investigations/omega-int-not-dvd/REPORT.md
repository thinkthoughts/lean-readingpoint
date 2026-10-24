# `omega`: the `k = 0` split for `¬ k ∣ x` on `Int`

Investigation for milestone 5 of `ROADMAP.md`. Status: **findings only; compiler source unmodified.**
The patches in `patch/` are proposals, measured through an out-of-tree copy of `omega` (below).

## 1. Leading specification

| Item | Value |
| --- | --- |
| Source | `src/Lean/Elab/Tactic/Omega/Frontend.lean`, `pushNot`, lines 399–404 |
| Source identity | `Omega/*.lean`, `Omega.lean`, `Init/Omega/*` in the uploaded ZIP are byte-identical to the sources shipped in `lean-4.37.0-nightly-2026-10-23` (commit `f37a0276ae8b0c60dd705920c49b9fd0c16279cf`). `Frontend.lean` sha256 `46ded66a…02a4`. |
| Toolchain | `Lean (version 4.37.0-nightly-2026-10-23, x86_64-unknown-linux-gnu, commit f37a0276ae8b, Release)` |
| Platform | Linux 6.18 x86_64, Intel Xeon @ 2.10 GHz, 2 cores |
| Code in question | `¬ k ∣ x` on `Int` becomes `k = 0 ∨ 0 < x % k` (`Int.emod_pos_of_not_dvd`), with the comment “This introduces a disjunction that could be avoided by checking `k ≠ 0`.” On `Nat` the same hypothesis becomes the plain fact `0 < x % k`. |

## 2. Mechanism

`omega` stores disjunctions and splits them only after the linear problem fails without them
(`omegaImpl` → `splitDisjunction`). So for a literal `k`:

* The fact `0 < x % k` is held back until everything else has failed. The `k = 0` branch is
  refuted instantly, so the direct cost of the redundant split is one extra elimination plus an
  `Or.elim` node.
* Disjunctions are split last-in-first-out. When `¬ k ∣ x` comes *before* other disjunction-producing
  hypotheses (`y ≠ c`, `¬ (a = b)`, a `≠`/`=` goal), every one of those is split first, and the
  needed fact only appears at the leaves: **2^(r+1) − 1 case splits for r unrelated `≠` hypotheses.**
  `Nat` has no such cliff, since its fact is added immediately.

## 3. Minimal reproducer

```lean
-- one redundant split
example (x : Int) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega

-- exponential: 511 case splits today, 0 with either patch
example (x y0 y1 y2 y3 y4 y5 y6 y7 : Int) (h : ¬ 3 ∣ x)
    (n0 : y0 ≠ 0) (n1 : y1 ≠ 1) (n2 : y2 ≠ 2) (n3 : y3 ≠ 3)
    (n4 : y4 ≠ 4) (n5 : y5 ≠ 5) (n6 : y6 ≠ 6) (n7 : y7 ≠ 7)
    (h' : x % 3 = 0) : False := by omega
```

Before/after `trace.omega` for the first example (full traces in `results/traces_excerpt/`):

```
before                                         after (either patch)
[omega] adding fact: 3 = 0 ∨ 0 < x % 3         [omega] adding fact: 0 < x % 3
[omega] Case splitting on 3 = 0 ∨ 0 < x % 3    [omega] omega found a contradiction, proving False
[omega] ✅️ Assuming fact: 3 = 0
  [omega] omega found a contradiction
[omega] ✅️ Assuming fact: 0 < x % 3
  [omega] omega found a contradiction
```

## 4. Candidate corrections

Both use one new helper lemma in `Init/Omega/Int.lean` (namespace `Lean.Omega.Int`), so the side
condition is closed by `Eq.refl true` without a Meta-level `decide`:

```lean
theorem emod_pos_of_not_dvd_of_bne {a b : Int} (w : (a != 0) = true) (h : ¬ a ∣ b) :
    0 < b % a :=
  (Int.emod_pos_of_not_dvd h).resolve_left fun h0 => by simp [h0] at w
```

* **E — eager** (`patch/omega-int-not-dvd.patch`, +7 / −1 lines). In `pushNot`, a nonzero literal `k`
  (via the existing `groundInt?`) yields `0 < x % k` directly; symbolic and zero `k` keep the
  disjunction. This is exactly what the source comment suggests, and it makes `Int` match `Nat`.
* **L — lazy pending fact** (`patch/omega-int-not-dvd-lazy.patch`, +21 / −3 lines). The same fact goes
  into a new `MetaProblem.pending` list, added once the problem survives without it and *before* any
  disjunction is split.

A first draft of E that used `mkAppM ``Or.resolve_left` with `mkDecideProof` cost 5–7 % more
heartbeats than the lemma form and was dropped.

## 5. Measurements

**Method.** `Frontend.lean` was copied three times out of tree — B (verbatim), E and L (each generated
from the patched source tree) — renamed to the tactics `omega_base`, `omega_patched2` and `omega_patched3`, and natively
compiled (`precompileModules`). B matches builtin `omega` split-for-split on every workload. For
each workload: median of 31 runs, with state restored between runs.
*Heartbeats* (allocation counter) are deterministic, identical across two full runs, and they are the
primary metric. Wall time is secondary (median run-to-run deviation 3 %). *Proof objs* is
`Expr.numObjs` of the generated proof. Full table: `results/table.md`; harness in `harness/`.

| Workload | Splits B/E/L | Heartbeats B | E | L |
| --- | --- | --- | --- | --- |
| `R1` minimal (1 needed fact) | 1/0/0 | 43 704 | +12 % | −4 % |
| 16 needed facts | 16/0/0 | 1 285 180 | −23 % | −9 % |
| 8 needed facts + `=` goal | 9/1/1 | 660 519 | −1 % | +16 % |
| 16 *irrelevant* `¬ 3 ∣ yᵢ` | 0/0/0 | 20 240 | **+503 %** | −3 % |
| `¬2∣n, ¬3∣n ⊢ n%6 = 1 ∨ n%6 = 5` | 5/2/2 | 227 536 | +27 % | +22 % |
| `¬2∣n, ¬3∣n, ¬5∣n ⊢ n%30 ≠ 25` | 1/0/0 | 87 345 | +75 % | −3 % |
| `¬3∣x` then 4 `≠` | 31/0/0 | 250 441 | −79 % | −82 % |
| `¬3∣x` then 8 `≠` | 511/0/0 | 4 184 519 | **−99 %** | **−99 %** |
| same, `≠` listed first | 1/0/0 | 50 256 | +10 % | −3 % |
| symbolic `k` | 3/3/3 | 23 474 | 0 % | 0 % |
| 16 irrelevant `¬ 3 ∣ yᵢ` on **Nat** (control) | 0/0/0 | 125 477 | 0 % | 0 % |

Wall time for the 8-`≠` case: 287 ms → 4.8 ms (E) / 4.5 ms (L). Whole-file time, kernel
included, with r = 10: 2.1 s → 0.86 s / 0.80 s (≈0.75 s of that is import overhead).

**Reading.**
* Both patches remove the exponential cliff, which is the substantive gain.
* E's cost on *irrelevant* `Int` hypotheses (+119 % … +503 %, ≈ 1 → 10 ms at 16 hypotheses)
  is the cost `Nat` already pays: compare the Nat control, 125 k heartbeats, with E at 122 k.
  Since `omega` reads the whole local context, irrelevant hypotheses are the common case.
* L stays at most 4 % above the baseline everywhere except four workloads (+14–22 %), where the
  deferred facts force one extra full elimination.

**Correctness.** Lean's own `tests/elab/omega.lean`, `omega_examples.lean` and `omegaCanon.lean`,
re-run through B, E and L (200+ `omega` calls), give byte-identical output. The core test suite
has no `omega` test with negated `Int` divisibility.

## 6. Regression test

`harness/tests/omega_int_not_dvd.lean`, in `tests/elab` format (module docstring; empty expected output).
It has seven correctness examples for literal `k` (including `¬ (2 * 3) ∣ x` and a `Nat`→`Int` cast) and one
symbolic-`k` example. It ends with the 8-`≠` reproducer under `set_option maxHeartbeats 1000`.

| Run | Result |
| --- | --- |
| builtin `omega`, B | **fails** (deterministic heartbeat timeout; needs 4 000–5 000) |
| E, L | **passes** (needs 100–200, ≥ 5× headroom) |

Before upstreaming, add the issue number to the docstring (Lean's test convention).

## 7. Assessment

**Merits an upstream issue now; a PR after maintainer feedback.**

For:
* The reproducer is minimal and core-only.
* The exponential cliff is deterministic, with a 75–86× heartbeat reduction at r = 8, and it grows with r.
* The change is tiny, addresses a TODO left by the original author in the source, and comes with a test that discriminates.

Open points for the maintainers:
1. **E or L.** E is the smallest diff and gives `Nat` parity, but it regresses heartbeats on
   irrelevant hypotheses. L avoids that but adds a mechanism to `omega`'s search loop. The issue
   should show both rows and ask.
2. **A broader fix.** The cliff is an instance of `omega` splitting irrelevant disjunctions first, which
   `OmegaConfig.splitDisjunctions`' docstring already acknowledges. A maintainer may prefer a general
   split-ordering change; this proposal removes one source of disjunctions only.
3. **Real-world frequency is unmeasured.** It needs Lean's `!bench` and a Mathlib run on the PR;
   these machines cannot run Mathlib.

**Gates still open.**
* A clean in-tree build of the patched compiler plus `make test`. This 2-core machine cannot run a full Lean
  bootstrap, so the patches were type-checked only through the out-of-tree copy. The lemma also compiles on its own.
* A search of existing lean4 issues and PRs (GitHub was unreachable here).
* Lean's `CONTRIBUTING.md`: issue first, AI assistance disclosed in the PR description, and the
  submitter manually checks the patch (“PRs authored solely by AI are not welcome”).

**Draft issue title:** `omega: ¬ k ∣ x on Int splits on k = 0 even for literal k, causing exponential case splitting`

## 8. Reproduce

```sh
cd harness && ./run.sh   # needs elan; lean-toolchain pins nightly-2026-10-23
```

The script builds the harness, regenerates every workload, writes `results/table.md`, checks builtin
`omega` against B, runs the three core omega test files through each variant, and runs the
regression test against builtin `omega`, B, E and L. Expected tail:
`… builtin omega / omega_base: FAIL; omega_patched2 / omega_patched3: PASS`.

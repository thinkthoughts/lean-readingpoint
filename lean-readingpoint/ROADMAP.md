# Roadmap — v0.1

The immediate goal is **one small, reviewable upstream Lean contribution** motivated by well-specified arithmetic examples.

## Milestones

| Stage | Work | Status / gate |
| --- | --- | --- |
| 1. Source map | Locate `omega`, `grind`/`lia`, core arithmetic and tests | Inspected in uploaded source snapshot |
| 2. Initial examples | Three standalone Lean test files | Prepared; execution reported by Claude |
| 3. Independent review | Check mathematics, reused lemmas, failure interpretations | In progress |
| 4. Reproduction | Pin release and commit; run tests; save output and platform details | **Next, required before public claims** |
| 5. Small change | Investigate redundant `k = 0` split in `Omega/Frontend.lean` | Proposed, not implemented |
| 6. Upstream | Search existing issues; discuss scope; tests, benchmarks, PR | Not started |
| 7. Mathlib | Evaluate GDT-derived reusable lemmas separately | Later |

## Active hypotheses

**A — mod-30 residue lanes:** `omega` cannot close certain integer-infeasible linear constraints involving several literal moduli; `lia` and `grind` reportedly can. Lean's `Omega/Core.lean` documents missing dark/grey-shadow elimination. This is a completeness limitation, **not an unsoundness claim**. Consult `experiments/omega_residue_lanes.lean`.

**B — coprimality:** residue-to-coprime proofs require gcd facts outside pure linear arithmetic. A proposed helper is already derivable from `Nat.gcd_rec` and `Nat.gcd_comm`; check existing Lean/Mathlib names before proposing a lemma. Consult `experiments/grind_coprime_residue.lean`.

**C — symbolic modulus:** symbolic division/modulo falls outside the intended linear fragment in these examples. Library rewrites close the goals. This is a baseline, not a bug. Consult `experiments/grind_symbolic_modulus.lean`.

## Specification Grammar for each candidate

1. **Leading constraints:** exact Lean version, assumptions, minimal proposition.
2. **Engineering objects:** source modules, applicable tactics and tests.
3. **Measurable states:** success/failure, diagnostics, timing and allocations if performance is asserted.
4. **Verification:** independent proof review, kernel check, relevant test suite, full build for patches.
5. **Admissible generalizations trail leading specifications:** broaden only with new independently verified examples.

## Upstream gates

- Confirm the issue is open or obtain maintainer feedback before implementation/PR.
- Preserve a reproducer that uses only Lean Core where possible.
- Record a precise `git rev-parse HEAD` for the tested compiler checkout; the ZIP has no Git metadata.
- Compare behavior and, for a `perf:` change, resource use before and after.
- Modify compiler source only in a dedicated branch of the Lean fork, never in this companion repository.
- Follow Lean's `CONTRIBUTING.md`; disclose AI assistance and personally review the patch.

## AI-assisted work

Claude investigates source and proposes tests/patches; ChatGPT reviews mathematics and specifications; DeepSeek challenges assumptions and prepares integration material. Roles are interchangeable, and all model statements remain provisional until mechanically verified.

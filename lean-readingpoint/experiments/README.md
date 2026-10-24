# Arithmetic tactic experiments

These are exploratory tests from the initial Lean 4 source review. All `.lean` files were provided as test artifacts by the user following Claude's investigation; they are included without modification in this starter package.

| File | Intended observation | Follow-up |
| --- | --- | --- |
| `omega_residue_lanes.lean` | `omega` proves easy residue reconstruction but fails on several integer-infeasible cases; `lia` proves the latter | Reproduce on exact compiler revision; discuss documented dark/grey-shadow gap |
| `grind_coprime_residue.lean` | gcd/coprimality needs a bridge lemma; bare arithmetic tactics fail | Check duplicate names and simplify bridge via `Nat.gcd_rec` plus `Nat.gcd_comm` |
| `grind_symbolic_modulus.lean` | Symbolic modulo/divisibility goals use algebraic lemmas | Retain as a baseline; no proposed solver defect |

## Meaning of failure tests

`fail_if_success omega` passes precisely when `omega` fails. If future Lean versions improve the tactic, such tests deliberately fail and must be revised so the improved behavior is asserted directly. Do not upstream these frozen-failure tests without maintainer agreement.

## Reproduction protocol

1. Record OS/architecture, `lean --version`, toolchain name, and compiler commit.
2. Run `./verify.sh` with all three files.
3. Check output, exit status, and absence of unexpected `sorry` warnings.
4. Separately rerun any tests changed for an upstream contribution.
5. Update `verification/RESULTS.md` with commands, expected versus actual behavior, and the reviewer.

The test files are not proofs of the full General Divisor Theorem.

# Verification record

## Snapshot and toolchain

- Source inspected: user-provided `lean4-master.zip`, identifying itself as Lean `4.37.0-dev`; source ZIP has no Git commit metadata.
- Toolchain reportedly used by Claude: `4.37.0-nightly-2026-10-23`, compiler commit `f37a0276` (as reported, not independently matched to ZIP).
- This repository pins the named nightly release for repeatability. **A tag alone does not prove the ZIP and release contain identical code.**

## Status

| Experiment | Claude's reported result | Independent run for this starter package |
| --- | --- | --- |
| `omega_residue_lanes.lean` | All examples compile; `fail_if_success omega` observes failures; `lia` closes goals | Not run |
| `grind_coprime_residue.lean` | Bridge lemma and examples compile | Not run |
| `grind_symbolic_modulus.lean` | Baseline examples compile | Not run |

## Review findings

- The identity `Nat.gcd (n % m) m = Nat.gcd n m` follows from `Nat.gcd_rec m n` and `Nat.gcd_comm m n`; the current experiment retains Claude's original proof to preserve the supplied artifact. Substitution requires another checked run.
- The mod-30 test is a useful completeness benchmark, not a kernel/soundness vulnerability.
- The proposed `Omega/Frontend.lean` optimization needs a controlled before/after trace and performance result before claiming improvement.

## First independent run — pending

Record the date, person/model, OS, `lean --version`, compiler Git hash, exact commands, exit codes, relevant output, and any deviations from reported behavior here. Do not mark the work verified until this is complete.

# Lean Reading Point

Reproducible Lean 4 arithmetic-tactic experiments motivated by the General Divisor Theorem (GDT), with Specification Grammar (SG) used as a research workflow.

This is a **companion research repository**, not a fork of the Lean compiler. Compiler changes and upstream pull requests belong in [`thinkthoughts/lean4`](https://github.com/thinkthoughts/lean4); mathematical theorems belong in the GDT or Mathlib repositories as appropriate.

## Start here

- [ROADMAP.md](ROADMAP.md): priorities and contribution gates.
- [experiments/README.md](experiments/README.md): test descriptions, expected behavior, and interpretation.
- [verification/RESULTS.md](verification/RESULTS.md): reported results versus independently reproduced results.

## Run

Install [Elan](https://lean-lang.org/install/) in a supported development environment. The included `lean-toolchain` selects `leanprover/lean4:nightly-2026-10-23` as the **reported** test release. The specific ZIP tree may differ from that release; see the verification record.

```sh
lean --version
lean experiments/omega_residue_lanes.lean
lean experiments/grind_coprime_residue.lean
lean experiments/grind_symbolic_modulus.lean
```

Or run `./verify.sh` from the repository root; it stops on the first failure.

No Mathlib dependency is needed for these three experiments. Do not interpret a successful `fail_if_success omega` check as a proof by `omega`: it asserts that `omega` currently *fails* while another tactic completes the proof.

## Project boundaries

| Project | Responsibility |
| --- | --- |
| `lean-readingpoint` | Reproducers, verification records, upstream research notes |
| `thinkthoughts/lean4` | Isolated compiler/tactic branches and upstream PRs |
| GDT | Mathematical definitions, theorem statements, proofs |
| SG | General specification methodology |
| `translatepi.ai` | Public-facing explanations of verified results |

All generated assistance must be disclosed in an upstream Lean PR according to its current contribution guidelines. The Lean kernel and reproducible tests determine proof status, not agreement among AI models.

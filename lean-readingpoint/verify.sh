#!/bin/sh
set -eu
cd "$(dirname "$0")"
lean --version
lean experiments/omega_residue_lanes.lean
lean experiments/grind_coprime_residue.lean
lean experiments/grind_symbolic_modulus.lean

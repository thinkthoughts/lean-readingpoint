#!/usr/bin/env bash
# Apply patch/{eager,lazy,followup-hmod-groundInt}.patch to the pristine upstream files and generate the measured modules.
# Every line of omega code that is measured comes from upstream/ + patch/, nothing else.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build/trees && mkdir -p build/trees
for v in eager lazy followup-hmod-groundInt; do
  cp -r upstream build/trees/$v
  (cd build/trees/$v && patch -s -p1 < ../../../../patch/$v.patch)
done
F=src/Lean/Elab/Tactic/Omega/Frontend.lean; I=src/Init/Omega/Int.lean
python3 gen/mkcopy.py upstream/$F           Baseline omega_base  OmegaAB/Baseline.lean
python3 gen/mkcopy.py build/trees/eager/$F  Eager    omega_eager OmegaAB/Eager.lean
python3 gen/mkcopy.py build/trees/lazy/$F   Lazy     omega_lazy  OmegaAB/Lazy.lean
python3 gen/mkcopy.py build/trees/followup-hmod-groundInt/$F GroundInt omega_gi OmegaAB/GroundInt.lean
python3 gen/mklemma.py build/trees/eager/$I OmegaAB/Lemma.lean
python3 gen/mklemma.py build/trees/lazy/$I  build/Lemma.lazy.lean
cmp -s OmegaAB/Lemma.lean build/Lemma.lazy.lean || { echo "eager and lazy patches add different lemmas"; exit 1; }
cmp -s upstream/$I build/trees/eager/$I && { echo "eager patch did not change Int.lean"; exit 1; }
echo "prepared: Baseline (upstream), Eager (patch/eager.patch), Lazy (patch/lazy.patch), Lemma; follow-up GroundInt (patch/followup-hmod-groundInt.patch)"

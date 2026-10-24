# Extract the helper lemma a patch adds to Init/Omega/Int.lean into OmegaAB/Lemma.lean (same full name).
import sys
src, out = sys.argv[1:3]
s = open(src).read()
i = s.index("theorem emod_pos_of_not_dvd_of_bne")
j = s.index("\n\n", i)
open(out, "w").write("namespace Lean.Omega.Int\n\n" + s[i:j] + "\n\nend Lean.Omega.Int\n")

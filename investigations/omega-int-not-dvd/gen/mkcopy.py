# Turn omega's Frontend.lean into an out-of-tree module with its own namespace and tactic name,
# so the unpatched and patched frontends can run side by side against the same toolchain.
import sys, re
src, ns, tac, out = sys.argv[1:5]
s = open(src).read()
s = s.replace("module\n\nprelude\n", "", 1)
s = re.sub(r"^(public )?import .*\n", "", s, flags=re.M)
s = "import Lean\nimport OmegaAB.Lemma\n" + s
s = s.replace("public section\n", "", 1)
s = s.replace("namespace Lean.Elab.Tactic.Omega\n", f"namespace Lean.Elab.Tactic.Omega.{ns}\n", 1)
s = s.replace("@[builtin_tactic Lean.Parser.Tactic.omega]",
              f"syntax (name := {tac}Stx) \"{tac}\" optConfig : tactic\n\n@[tactic {tac}Stx]")
s = s.replace("`(tactic| omega%$tk $cfg:optConfig)", f"`(tactic| {tac}%$tk $cfg:optConfig)")
i = s.index("builtin_initialize bitvec_to_nat")
s = s[:i] + f"end Lean.Elab.Tactic.Omega.{ns}\n"
for needle in ["namespace Lean.Elab.Tactic.Omega." + ns, f"@[tactic {tac}Stx]", f"`(tactic| {tac}%$tk"]:
    assert needle in s, needle
open(out, "w").write(s)

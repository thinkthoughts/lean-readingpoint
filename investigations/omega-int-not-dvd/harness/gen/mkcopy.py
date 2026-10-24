# Build an out-of-tree, renamed copy of omega's Frontend.lean so it can run beside the builtin.
import sys,re
src,ns,tac,out=sys.argv[1:5]
s=open(src).read()
s=s.replace("module\n\nprelude\n","",1)
s=re.sub(r"^(public )?import .*\n","",s,flags=re.M)
s="import Lean\nimport OmegaAB.Harness\n"+s
s=s.replace("public section\n","",1)
s=s.replace("namespace Lean.Elab.Tactic.Omega\n",f"namespace Lean.Elab.Tactic.Omega.{ns}\n",1)
s=s.replace("@[builtin_tactic Lean.Parser.Tactic.omega]",f"syntax (name := {tac}Stx) \"{tac}\" optConfig : tactic\n\n@[tactic {tac}Stx]")
s=s.replace("`(tactic| omega%$tk $cfg:optConfig)",f"`(tactic| {tac}%$tk $cfg:optConfig)")
i=s.index("builtin_initialize bitvec_to_nat")
s=s[:i]+f"end Lean.Elab.Tactic.Omega.{ns}\n"
open(out,'w').write(s)

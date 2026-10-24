# Replace the `omega` tactic token (not words in messages) with a variant tactic name.
import sys,re
s=open(sys.argv[1]).read(); t=sys.argv[2]
s=re.sub(r'(?<![\w.`\'"])omega(?=[ \t]*($|\n|\)|;|<;>|\(config|\+|\]|,|\s+at\b|\s*-[a-zA-Z]))', t, s, flags=re.M)
print("import OmegaAB\n"+s)

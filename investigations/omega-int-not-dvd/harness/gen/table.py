# Build results/table.md from results/bench{,2}_*.txt and results/trace/*.txt.
# Exits 1 if a workload is missing, a bench file reports an error, or heartbeats differ between runs.
import re, sys, collections, subprocess, os
here = os.path.dirname(os.path.abspath(__file__))
R = os.path.join(here, "..", "results") + "/"
V = [("omega_base", "B"), ("omega_eager", "E"), ("omega_lazy", "L")]
names = subprocess.run([sys.executable, os.path.join(here, "gen.py"), "x", "list"],
                       capture_output=True, text=True, check=True).stdout.split()
pat = re.compile(r"BENCH (\S+) time_us=(\d+) heartbeats=(\d+) proof_objs=(\d+) kernel_us=(\d+) aux_decls=(\d+)")
d = collections.defaultdict(dict)
problems = []
for t, _ in V:
    for run in ("bench", "bench2"):
        txt = open(R + f"{run}_{t}.txt").read()
        if re.search(r"\.lean:\d+:\d+(-\d+:\d+)?: error", txt):
            problems.append(f"{run}_{t}: elaboration error")
        for m in pat.finditer(txt):
            d[m.group(1)][(t, run)] = tuple(map(int, m.groups()[1:]))
    for n in names:
        d[n][(t, "splits")] = open(R + f"trace/{t}__{n}.txt").read().count("Case splitting on")
noise = []
knoise = []
for n in names:
    for t, _ in V:
        a, b = d[n].get((t, "bench")), d[n].get((t, "bench2"))
        if a is None or b is None:
            problems.append(f"{n}/{t}: missing"); continue
        if a[1] != b[1]:
            problems.append(f"{n}/{t}: heartbeats differ between runs ({a[1]} vs {b[1]})")
        noise.append(abs(a[0] - b[0]) / max(1, a[0]))
        knoise.append(abs(a[3] - b[3]) / max(1, a[3]))
pc = lambda x, y: f"{100 * (y - x) / x:+.0f}%"
out = []
out.append("| workload | splits B/E/L | heartbeats B | E | L | elab µs B | E | L | kernel µs B | E | L | proof objs B | E | L |")
out.append("|" + "---|" * 14)
for n in names:
    try:
        b, e, l = (d[n][(t, "bench")] for t, _ in V)
    except KeyError:
        continue
    s = "/".join(str(d[n][(t, "splits")]) for t, _ in V)
    out.append(f"| {n} | {s} | {b[1]} | {e[1]} ({pc(b[1], e[1])}) | {l[1]} ({pc(b[1], l[1])}) | "
               f"{b[0]} | {e[0]} | {l[0]} | {b[3]} | {e[3]} | {l[3]} | {b[2]} | {e[2]} | {l[2]} |")
noise.sort(); knoise.sort()
out.append("")
out.append(f"Heartbeats identical across two runs: {'yes' if not any('heartbeats differ' in p for p in problems) else 'NO'}. "
           f"Run-to-run deviation, elaboration time: median {100 * noise[len(noise) // 2]:.0f}%, max {100 * noise[-1]:.0f}%; "
           f"kernel check time: median {100 * knoise[len(knoise) // 2]:.0f}%, max {100 * knoise[-1]:.0f}%.")
open(R + "table.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
for p in problems:
    print("PROBLEM:", p)
sys.exit(1 if problems else 0)

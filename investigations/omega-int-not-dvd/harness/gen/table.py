import re,collections,subprocess
R='/home/claude/omega-ab/results/'
V=['omega_base','omega_patched2','omega_patched3']
names=subprocess.run(['python3','/home/claude/omega-ab/gen/gen.py','x','list'],capture_output=True,text=True).stdout.split()
d=collections.defaultdict(dict); noise=[]
for t in V:
    for f in ['bench_','bench2_']:
        for l in open(R+f'{f}{t}.txt'):
            m=re.search(r'BENCH (\S+) time_us=(\d+) heartbeats=(\d+) proof_objs=(\d+)',l)
            if m: d[m.group(1)][t+f]=tuple(map(int,m.groups()[1:]))
    for n in names:
        txt=open(R+f'trace/{t}__{n}.txt').read()
        d[n][t+'_s']=txt.count('Case splitting on'); d[n][t+'_e']=('error' in txt)
print("| workload | case splits B / E / L | heartbeats B | E (Δ) | L (Δ) | median µs B | E | L | proof objs B | E | L |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
hb_same=True
for n in names:
    b,e,l=(d[n][t+'bench_'] for t in V)
    for t in V:
        if d[n][t+'bench_'][1]!=d[n][t+'bench2_'][1]: hb_same=False
        noise.append(abs(d[n][t+'bench_'][0]-d[n][t+'bench2_'][0])/max(1,d[n][t+'bench_'][0]))
    pc=lambda x,y: f"{100*(y-x)/x:+.0f}%"
    errs=[t for t in V if d[n][t+'_e']]
    print(f"| {n}{' ERR:'+','.join(errs) if errs else ''} | {d[n]['omega_base_s']} / {d[n]['omega_patched2_s']} / {d[n]['omega_patched3_s']} | {b[1]} | {e[1]} ({pc(b[1],e[1])}) | {l[1]} ({pc(b[1],l[1])}) | {b[0]} | {e[0]} | {l[0]} | {b[2]} | {e[2]} | {l[2]} |")
noise.sort()
print(f"\nheartbeats identical across two runs: {hb_same}; wall-time run-to-run deviation median {100*noise[len(noise)//2]:.0f}%, max {100*noise[-1]:.0f}%")

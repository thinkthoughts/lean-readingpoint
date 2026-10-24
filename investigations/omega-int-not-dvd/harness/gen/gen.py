import sys
def W():
    ws=[]
    ws.append(("R1_min", "(x : Int) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False"))
    for m in [1,2,4,8,16]:
        vs=" ".join(f"x{i}" for i in range(m))
        hs=" ".join(f"(h{i} : ¬ 2 ∣ x{i})" for i in range(m))
        s=" + ".join(f"x{i} % 2" for i in range(m))
        ws.append((f"W2_needed_m{m}", f"({vs} : Int) {hs} (s : {s} < {m}) : False"))
    for m in [1,2,4,8]:
        vs=" ".join(f"x{i}" for i in range(m))
        hs=" ".join(f"(h{i} : ¬ 2 ∣ x{i})" for i in range(m))
        s=" + ".join(f"x{i} % 2" for i in range(m))
        ws.append((f"W3_eqgoal_m{m}", f"({vs} : Int) {hs} (b : {s} ≤ {m}) : {s} = {m}"))
    for m in [1,4,8,16]:
        vs=" ".join(f"y{i}" for i in range(m))
        hs=" ".join(f"(h{i} : ¬ 3 ∣ y{i})" for i in range(m))
        ws.append((f"W4_irrelevant_m{m}", f"({vs} x : Int) {hs} (a : x < 0) (b : 0 ≤ x) : False"))
    ws.append(("W5_lanes6", "(n : Int) (h2 : ¬ 2 ∣ n) (h3 : ¬ 3 ∣ n) : n % 6 = 1 ∨ n % 6 = 5"))
    ws.append(("W5_lanes30_ne25", "(n : Int) (h2 : ¬ 2 ∣ n) (h3 : ¬ 3 ∣ n) (h5 : ¬ 5 ∣ n) : n % 30 ≠ 25"))
    ws.append(("W6_natcast", "(x : Nat) (h : ¬ (3 : Int) ∣ (x : Int)) (h' : x % 3 = 0) : False"))
    ws.append(("W7_symbolic_k", "(k x : Int) (h : ¬ k ∣ x) (hk : k ≠ 0) (h0 : x % k = 0) : False"))
    for m in [1,4,8,16]:
        vs=" ".join(f"y{i}" for i in range(m))
        hs=" ".join(f"(h{i} : ¬ 3 ∣ y{i})" for i in range(m))
        ws.append((f"W4N_irrelevant_nat_m{m}", f"({vs} x : Nat) {hs} (a : x < 0) : False"))
    for r in [1,2,4,6,8]:
        vs=" ".join(f"y{i}" for i in range(r))
        ns=" ".join(f"(n{i} : y{i} ≠ {i})" for i in range(r))
        ws.append((f"W8_dvd_then_ne_r{r}", f"(x {vs} : Int) (h : ¬ 3 ∣ x) {ns} (h' : x % 3 = 0) : False"))
        ws.append((f"W8_ne_then_dvd_r{r}", f"(x {vs} : Int) {ns} (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False"))
    return ws
tac=sys.argv[1]; mode=sys.argv[2]; n=int(sys.argv[3]) if len(sys.argv)>3 else 21
out=["import OmegaAB",""]
for name,stmt in W():
    if mode=="bench":
        out.append(f'example {stmt} := by bench_tac "{name}" {n} {tac}')
    elif mode=="trace":
        out.append(f'set_option trace.omega true in\nexample {stmt} := by {tac}')
    elif mode=="plain":
        out.append(f'example {stmt} := by {tac}')
if mode=="list":
    print("\n".join(n for n,_ in W()))
elif mode.startswith("one:"):
    k=mode[4:]
    st=dict(W())[k]
    print(f"import OmegaAB\nset_option trace.omega true in\nexample {st} := by {tac}")
else:
    print("\n".join(out))

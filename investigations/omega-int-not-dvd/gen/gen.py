# Benchmark workloads. Usage:
#   gen.py TACTIC bench N   -> one file, every workload wrapped in `bench_tac`
#   gen.py TACTIC one:NAME  -> one workload with `trace.omega` on
#   gen.py x list           -> workload names
import sys

def workloads():
    ws = []
    ws.append(("R1_min", "(x : Int) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False"))
    for m in [1, 2, 4, 8, 16]:
        vs = " ".join(f"x{i}" for i in range(m))
        hs = " ".join(f"(h{i} : ¬ 2 ∣ x{i})" for i in range(m))
        s = " + ".join(f"x{i} % 2" for i in range(m))
        ws.append((f"W2_needed_m{m}", f"({vs} : Int) {hs} (s : {s} < {m}) : False"))
    for m in [1, 2, 4, 8]:
        vs = " ".join(f"x{i}" for i in range(m))
        hs = " ".join(f"(h{i} : ¬ 2 ∣ x{i})" for i in range(m))
        s = " + ".join(f"x{i} % 2" for i in range(m))
        ws.append((f"W3_eqgoal_m{m}", f"({vs} : Int) {hs} (b : {s} ≤ {m}) : {s} = {m}"))
    for m in [1, 4, 8, 16]:
        vs = " ".join(f"y{i}" for i in range(m))
        hs = " ".join(f"(h{i} : ¬ 3 ∣ y{i})" for i in range(m))
        ws.append((f"W4_irrelevant_m{m}", f"({vs} x : Int) {hs} (a : x < 0) (b : 0 ≤ x) : False"))
    ws.append(("W5_lanes6", "(n : Int) (h2 : ¬ 2 ∣ n) (h3 : ¬ 3 ∣ n) : n % 6 = 1 ∨ n % 6 = 5"))
    ws.append(("W5_lanes30_ne25", "(n : Int) (h2 : ¬ 2 ∣ n) (h3 : ¬ 3 ∣ n) (h5 : ¬ 5 ∣ n) : n % 30 ≠ 25"))
    ws.append(("W6_natcast", "(x : Nat) (h : ¬ (3 : Int) ∣ (x : Int)) (h' : x % 3 = 0) : False"))
    ws.append(("W7_symbolic_k", "(k x : Int) (h : ¬ k ∣ x) (hk : k ≠ 0) (h0 : x % k = 0) : False"))
    for m in [1, 4, 8, 16]:
        vs = " ".join(f"y{i}" for i in range(m))
        hs = " ".join(f"(h{i} : ¬ 3 ∣ y{i})" for i in range(m))
        ws.append((f"W4N_irrelevant_nat_m{m}", f"({vs} x : Nat) {hs} (a : x < 0) : False"))
    for r in [1, 2, 4, 6, 8]:
        vs = " ".join(f"y{i}" for i in range(r))
        ns = " ".join(f"(n{i} : y{i} ≠ {i})" for i in range(r))
        ws.append((f"W8_dvd_then_ne_r{r}", f"(x {vs} : Int) (h : ¬ 3 ∣ x) {ns} (h' : x % 3 = 0) : False"))
        ws.append((f"W8_ne_then_dvd_r{r}", f"(x {vs} : Int) {ns} (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False"))
    # new in this round
    for m in [2, 8]:
        hs = " ".join(f"(h{i} : ¬ 3 ∣ x)" for i in range(m))
        ws.append((f"W9_repeated_m{m}", f"(x : Int) {hs} (h' : x % 3 = 0) : False"))
    ws.append(("W10_neg_literal", "(x : Int) (h : ¬ (-3) ∣ x) (h' : x % (-3) = 0) : False"))
    ws.append(("W10_zero_literal", "(x : Int) (h : ¬ (0 : Int) ∣ x) (h1 : x % 0 = 5) : x = 5"))
    ws.append(("W10_expr_zero", "(x : Int) (h : ¬ (3 - 3) ∣ x) (h1 : x % 0 = 5) : x = 5"))
    ws.append(("W10_pow_literal", "(x : Int) (h : ¬ (2 ^ 64) ∣ x) (h' : x % 2 ^ 64 = 0) : False"))
    ws.append(("W11_or_branch", "(x : Int) (h : ¬ 3 ∣ x ∨ ¬ 5 ∣ x) (h3 : x % 3 = 0) (h5 : x % 5 = 0) : False"))
    ws.append(("W11_not_and", "(x : Int) (h : ¬ (3 ∣ x ∧ 5 ∣ x)) (h3 : x % 15 = 0) : False"))
    ws.append(("W11_not_not", "(x : Int) (h : ¬ ¬ ¬ 3 ∣ x) (h' : x % 3 = 0) : False"))
    return ws

if __name__ == "__main__":
    tac, mode = sys.argv[1], sys.argv[2]
    W = workloads()
    if mode == "list":
        print("\n".join(n for n, _ in W))
    elif mode.startswith("one:"):
        st = dict(W)[mode[4:]]
        print(f"import OmegaAB\nset_option trace.omega true in\nexample {st} := by {tac}")
    elif mode == "bench":
        n = int(sys.argv[3])
        out = ["import OmegaAB", ""]
        out += [f'example {st} := by bench_tac "{name}" {n} {tac}' for name, st in W]
        print("\n".join(out))

/-!
Residue-class problems with literal moduli, of the shape that comes up in
wheel-sieve arguments (residues mod 2·3·5 = 30).

`omega` decides the single-residue and CRT-reconstruction forms. The last
group is satisfiable over the reals but unsatisfiable over the integers, and
needs the dark/grey shadows, which `omega` does not implement yet (see the
`omega` docstring). Those are checked with `lia`; the `fail_if_success omega`
lines record the current gap and should be flipped when shadows land.
-/

-- Lane splitting and CRT reconstruction: exact eliminations.
example (n : Nat) (h : n % 6 = 5) : n % 2 = 1 ∧ n % 3 = 2 := by omega
example (n : Nat) (h2 : n % 2 = 1) (h3 : n % 3 = 2) : n % 6 = 5 := by omega
example (n : Nat) : 6 ∣ n ↔ 2 ∣ n ∧ 3 ∣ n := by omega
example (n : Nat) (h : n % 30 = 29) : (n + 2) % 30 = 1 := by omega
example (n : Int) (h : n % 6 = 5) : n % 2 = 1 ∧ n % 3 = 2 := by omega

-- Integer-infeasible, real-feasible: every r ∈ {3,4,5} is even or divisible by 3 or 5.
example (r : Nat) (h2 : r % 2 = 1) (h3 : r % 3 ≠ 0) (h5 : r % 5 ≠ 0)
    (lo : 2 < r) (hi : r < 6) : False := by
  fail_if_success omega
  lia

-- The eight admissible residues mod 30.
example (n : Nat) (h2 : ¬ 2 ∣ n) (h3 : ¬ 3 ∣ n) (h5 : ¬ 5 ∣ n) :
    n % 30 = 1 ∨ n % 30 = 7 ∨ n % 30 = 11 ∨ n % 30 = 13 ∨
    n % 30 = 17 ∨ n % 30 = 19 ∨ n % 30 = 23 ∨ n % 30 = 29 := by
  fail_if_success omega
  lia

-- Pugh's classic example, with no `%` at all.
example (x y : Int) (h1 : 27 ≤ 11*x + 13*y) (h2 : 11*x + 13*y ≤ 45)
    (h3 : -10 ≤ 7*x - 9*y) (h4 : 7*x - 9*y ≤ 4) : False := by
  fail_if_success omega
  lia

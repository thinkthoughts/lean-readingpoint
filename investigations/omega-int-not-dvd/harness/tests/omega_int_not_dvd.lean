/-!
`omega` with negated `Int` divisibility by a literal, `¬ k ∣ x`.

For a nonzero literal `k`, `¬ k ∣ x` gives `0 < x % k` directly, matching how `¬ k ∣ x` on `Nat` is
handled. Previously this produced the disjunction `k = 0 ∨ 0 < x % k`, whose case split interacts
badly with unrelated disjunctions in the context (see the last example).

Issue: #NNNN (to be filed).
-/

example (x : Int) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ (2 * 3) ∣ x) (h' : x % 6 = 0) : False := by omega
example (x : Int) (h2 : ¬ 2 ∣ x) (h3 : ¬ 3 ∣ x) : x % 6 = 1 ∨ x % 6 = 5 := by omega
example (x : Int) (h2 : ¬ 2 ∣ x) (h3 : ¬ 3 ∣ x) (h5 : ¬ 5 ∣ x) : x % 30 ≠ 25 := by omega
example (x : Nat) (h : ¬ (3 : Int) ∣ (x : Int)) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ 3 ∣ x) : x % 3 = 1 ∨ x % 3 = 2 := by omega
example (x : Int) (h : 6 ∣ x) (h' : ¬ 3 ∣ x) : False := by omega

-- A symbolic `k` keeps the disjunction.
example (k x : Int) (h : ¬ k ∣ x) (hk : k ≠ 0) (h0 : x % k = 0) : False := by omega

-- The fact must be available without first splitting the eight unrelated `≠` disjunctions.
set_option maxHeartbeats 1000 in
example (x y0 y1 y2 y3 y4 y5 y6 y7 : Int) (h : ¬ 3 ∣ x)
    (n0 : y0 ≠ 0) (n1 : y1 ≠ 1) (n2 : y2 ≠ 2) (n3 : y3 ≠ 3)
    (n4 : y4 ≠ 4) (n5 : y5 ≠ 5) (n6 : y6 ≠ 6) (n7 : y7 ≠ 7)
    (h' : x % 3 = 0) : False := by omega

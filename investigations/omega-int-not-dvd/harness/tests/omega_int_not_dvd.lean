/-!
`omega` with negated `Int` divisibility, `¬ k ∣ x`.

For a nonzero literal `k` the hypothesis yields `0 < x % k`; for `k = 0` (including literals
such as `3 - 3` that evaluate to zero) and for symbolic `k` it yields `k = 0 ∨ 0 < x % k`.
These examples hold before and after the change and cover how the hypothesis is written,
ordered, repeated, and nested.

Issue: #NNNN (to be filed).
-/

-- Positive literals.
example (x : Int) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ 3 ∣ x) : x % 3 = 1 ∨ x % 3 = 2 := by omega
example (x : Int) (h : 6 ∣ x) (h' : ¬ 3 ∣ x) : False := by omega
example (x : Int) (h2 : ¬ 2 ∣ x) (h3 : ¬ 3 ∣ x) : x % 6 = 1 ∨ x % 6 = 5 := by omega
example (x : Int) (h2 : ¬ 2 ∣ x) (h3 : ¬ 3 ∣ x) (h5 : ¬ 5 ∣ x) : x % 30 ≠ 25 := by omega
example (x : Nat) (h : ¬ (3 : Int) ∣ (x : Int)) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ 3 ∣ x) : x % 3 ≠ 0 := by omega

-- Literal expressions that evaluate to a nonzero value.
example (x : Int) (h : ¬ (2 * 3) ∣ x) (h' : x % 6 = 0) : False := by omega
example (x : Int) (h : ¬ (5 - 2) ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ (2 ^ 2) ∣ x) (h' : x % 4 = 0) : False := by omega
example (x : Int) (h : ¬ ((3 : Nat) : Int) ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ (2 ^ 64) ∣ x) (h' : x % 2 ^ 64 = 0) : False := by omega

-- Negative literals: `x % (-3)` is an atom for `omega`, so only facts about that atom are used.
example (x : Int) (h : ¬ (-3) ∣ x) (h' : x % (-3) = 0) : False := by omega

-- Zero, written directly or as an expression that evaluates to zero.
example (x : Int) (h : ¬ (0 : Int) ∣ x) (h1 : x % 0 = 5) : x = 5 := by omega
example (x : Int) (h : ¬ (3 - 3) ∣ x) (h1 : x % 0 = 5) : x = 5 := by omega
example (x : Int) (h : ¬ (2 * 0) ∣ x) (h1 : x % 0 = 5) : x = 5 := by omega

-- Hypothesis order.
example (x : Int) (h' : x % 3 = 0) (h : ¬ 3 ∣ x) : False := by omega
example (x y : Int) (n : y ≠ 0) (h : ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega
example (x y : Int) (h : ¬ 3 ∣ x) (n : y ≠ 0) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h' : x % 3 = 0) : ¬ 3 ∣ x → False := by omega

-- Repeated hypotheses.
example (x : Int) (h1 : ¬ 3 ∣ x) (h2 : ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h1 : ¬ 3 ∣ x) (h2 : ¬ 3 ∣ x) (h3 : ¬ 3 ∣ x) (h4 : ¬ 3 ∣ x) : x % 3 ≠ 0 := by
  omega

-- Nested occurrences: produced only after a split, or under further negations.
example (x : Int) (h : ¬ 3 ∣ x ∨ ¬ 5 ∣ x) (h3 : x % 3 = 0) (h5 : x % 5 = 0) : False := by omega
example (x : Int) (h : ¬ (3 ∣ x ∧ 5 ∣ x)) (h3 : x % 15 = 0) : False := by omega
example (x : Int) (h : ¬ ¬ ¬ 3 ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : x % 3 ≠ 0) : ¬ 3 ∣ x := by omega

-- Symbolic divisor.
example (k x : Int) (h : ¬ k ∣ x) (hk : k ≠ 0) (h0 : x % k = 0) : False := by omega

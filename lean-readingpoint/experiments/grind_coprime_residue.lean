/-!
Coprimality with a literal modulus, reduced to residues.

`Nat.gcd` is opaque to `omega` and `lia`, so these need a library lemma
turning `gcd n m` into `gcd (n % m) m`; after that the residue goal is decidable.
Passing `Nat.gcd_rec` to `grind` instead instantiates it on both argument
orders, producing terms such as `gcd (6 % n) n` that keep unfolding.
-/

theorem gcd_mod_left' (n m : Nat) : Nat.gcd (n % m) m = Nat.gcd n m := by
  conv => rhs; rw [← Nat.mod_add_div n m]
  simp [Nat.gcd_comm _ m]

example (n : Nat) (h : n % 6 = 5) : Nat.Coprime n 6 := by
  rw [Nat.Coprime, ← gcd_mod_left', h]; decide

example (n : Nat) (h : Nat.Coprime n 6) : n % 6 = 1 ∨ n % 6 = 5 := by
  rw [Nat.Coprime, ← gcd_mod_left'] at h
  have hlt : n % 6 < 6 := Nat.mod_lt _ (by decide)
  generalize n % 6 = r at *
  revert h; revert r; decide

-- Current tactic behaviour without the lemma.
example (n : Nat) (h : n % 6 = 5) : Nat.Coprime n 6 := by
  fail_if_success omega
  fail_if_success grind
  rw [Nat.Coprime, ← gcd_mod_left', h]; decide

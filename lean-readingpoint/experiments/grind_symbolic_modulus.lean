/-!
Residues and divisibility with a symbolic modulus. These are outside linear
integer arithmetic, so `omega`/`lia` treat `n % m` and `d ∣ a` as atoms;
`simp` or `grind` with the library lemma closes them.
-/

example (n m : Nat) : (n + m) % m = n % m := by
  fail_if_success omega
  simp

example (n m k : Nat) : (n + k * m) % m = n % m := by simp

example (n m : Nat) : (n + m) % m = n % m := by grind [Nat.add_mod_right]

example (a b d : Nat) (ha : d ∣ a) (hb : d ∣ b) : d ∣ a + b := by
  fail_if_success omega
  fail_if_success grind
  grind [Nat.dvd_add]

example (a b : Nat) : Nat.gcd a b ∣ a + b := by
  grind [Nat.gcd_dvd_left, Nat.gcd_dvd_right, Nat.dvd_add]

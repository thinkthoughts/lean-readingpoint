/-!
Investigation only (not proposed upstream): goals `omega` leaves open before and after the change.
Each `fail_if_success` records a gap separate from the `k = 0` split:

* `x % (-3)` is an atom (`omega` expands `x % k` only for natural-number literals `k`),
  although `x % (-3) = x % 3` holds (`Int.emod_neg`).
* `¬ 0 ∣ x` means `x ≠ 0`, but the `k = 0` branch of `k = 0 ∨ 0 < x % k` drops that information.

If a future `omega` closes one of these, this file fails by design and should be updated.
-/

example (x : Int) (h : ¬ (-3) ∣ x) (h' : x % 3 = 0) : False := by
  fail_if_success omega
  exact h (Int.neg_dvd.mpr (Int.dvd_of_emod_eq_zero h'))
example (x : Int) (h : ¬ 3 ∣ x) (h' : x % (-3) = 0) : False := by
  fail_if_success omega
  exact h (Int.dvd_of_emod_eq_zero (by simpa [Int.emod_neg] using h'))
example (x : Int) (h : ¬ (0 : Int) ∣ x) : x ≠ 0 := by
  fail_if_success omega
  rintro rfl; exact h (Int.dvd_refl 0)
example (x : Int) (h : ¬ (3 - 3) ∣ x) (hx : x = 0) : False := by
  fail_if_success omega
  subst hx; exact h (Int.dvd_zero _)

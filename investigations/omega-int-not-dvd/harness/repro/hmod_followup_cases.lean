/-!
Goals that the follow-up `groundInt?` change (`patch/followup-hmod-groundInt.patch`) closes and
current `omega` leaves open: `Int` moduli given by ground expressions whose `Nat` and `Int`
values differ, and negative literal moduli.
-/

example (x : Int) (h : x % (0 - 3) = 1) : x % (0 - 3) < 5 := by omega
example (x : Int) (h : x % (2 - 3 + 4) = 1) : x % 3 = 1 := by omega
example (x : Int) (h : x % (-3) = 1) : x % 3 = 1 := by omega
example (x : Int) : x % (-3) = x % 3 := by omega
example (x : Int) : 0 ≤ x % (0 - 3) := by omega
example (x : Int) (h : ¬ (-3) ∣ x) (h' : x % 3 = 0) : False := by omega
example (x : Int) (h : ¬ 3 ∣ x) (h' : x % (-3) = 0) : False := by omega
example (x : Int) (h : (-3) ∣ x) : x % 3 = 0 := by omega

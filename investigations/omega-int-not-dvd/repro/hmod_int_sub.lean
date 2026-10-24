/-!
Separate finding (not part of the `k = 0` change): `omega` builds an ill-typed proof when an
`Int` modulus is a ground expression whose `Nat` and `Int` values differ, e.g. `0 - 3`.

`Frontend.lean` evaluates the modulus of `x % k` with `groundNat?`, which computes `0 - 3` as
the truncated `Nat` value `0`, and then rewrites with `Int.emod_def x 0`.
-/

example (x : Int) (h : x % (0 - 3) = 1) : x % (0 - 3) < 5 := by omega

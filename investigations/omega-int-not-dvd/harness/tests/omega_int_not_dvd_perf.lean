/-!
`¬ 3 ∣ x` on `Int` followed by eight unrelated `≠` hypotheses.

The fact `0 < x % 3` must be usable without first splitting the eight `≠` disjunctions
(2^9 - 1 case splits otherwise).

Issue: #NNNN (to be filed).
-/

set_option maxHeartbeats 1000 in
example (x y0 y1 y2 y3 y4 y5 y6 y7 : Int) (h : ¬ 3 ∣ x)
    (n0 : y0 ≠ 0) (n1 : y1 ≠ 1) (n2 : y2 ≠ 2) (n3 : y3 ≠ 3)
    (n4 : y4 ≠ 4) (n5 : y5 ≠ 5) (n6 : y6 ≠ 6) (n7 : y7 ≠ 7)
    (h' : x % 3 = 0) : False := by omega

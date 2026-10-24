namespace Lean.Omega.Int

theorem emod_pos_of_not_dvd_of_bne {a b : Int} (w : (a != 0) = true) (h : ¬ a ∣ b) :
    0 < b % a :=
  (Int.emod_pos_of_not_dvd h).resolve_left fun h0 => by simp [h0] at w

end Lean.Omega.Int

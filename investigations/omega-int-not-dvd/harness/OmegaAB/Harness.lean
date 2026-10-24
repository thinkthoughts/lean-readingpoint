import Lean
open Lean Elab Tactic Meta

/-- `bench_tac n tac`: run `tac` `n` times (state restored each time), report median
wall time, median heartbeats, and the object count of the proof term it produces;
then run `tac` once more for real. -/
syntax (name := benchTac) "bench_tac " str num tactic : tactic

private def median (xs : Array Nat) : Nat :=
  let s := xs.qsort (· < ·); s[s.size / 2]!

@[tactic benchTac] def evalBenchTac : Tactic := fun stx => do
  let label := stx[1].isStrLit?.getD ""
  let n := stx[2].toNat
  let tac := stx[3]
  let mut times := #[]
  let mut hbs := #[]
  for _ in [0:n] do
    let s ← saveState
    let h0 ← IO.getNumHeartbeats
    let t0 ← IO.monoNanosNow
    evalTactic tac
    let t1 ← IO.monoNanosNow
    let h1 ← IO.getNumHeartbeats
    s.restore
    times := times.push (t1 - t0)
    hbs := hbs.push (h1 - h0)
  let g ← getMainGoal
  let env0 ← getEnv
  evalTactic tac
  let env1 ← getEnv
  -- size of all proof terms newly added (omega hides its proof in an aux theorem)
  let pf ← instantiateMVars (mkMVar g)
  let mut aux := 0
  for nm in pf.getUsedConstants do
    unless env0.contains nm do
      if let some v := (← getConstInfo nm).value? (allowOpaque := true) then
        aux := aux + (← v.numObjs)
  let _ := env1
  logInfo m!"BENCH {label} time_us={median times / 1000} heartbeats={median hbs} proof_objs={aux}"

/-- Copy of the lemma the patch adds to `Init/Omega/Int.lean`. -/
theorem Lean.Omega.Int.emod_pos_of_not_dvd_of_bne {a b : Int} (w : (a != 0) = true) (h : ¬ a ∣ b) :
    0 < b % a :=
  (Int.emod_pos_of_not_dvd h).resolve_left fun h0 => by simp [h0] at w

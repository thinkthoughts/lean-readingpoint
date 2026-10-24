import Lean
open Lean Elab Tactic Meta

/-!
`bench_tac "label" n tac` runs `tac` `n` times on the current goal (restoring state each time),
then once more for real, and logs one line:

* `time_us`     median elaboration wall time of `tac`
* `heartbeats`  median heartbeats (small-allocation counter; deterministic for a fixed build)
* `proof_objs`  `Expr.numObjs` of the proof term(s) `tac` produced (omega hides its proof
                in an auxiliary theorem, whose value is measured)
* `kernel_us`   median time for the kernel to type-check those proof terms, re-added
                synchronously as fresh theorems `n` times
-/

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
  let pf ← instantiateMVars (mkMVar g)
  let mut objs := 0
  let mut decls := #[]
  for nm in pf.getUsedConstants do
    unless env0.contains nm do
      let ci ← getConstInfo nm
      if let some v := ci.value? (allowOpaque := true) then
        objs := objs + (← v.numObjs)
        decls := decls.push (nm, ci.levelParams, ci.type, v)
  -- kernel re-check of each auxiliary proof, under a fresh name below the original one
  let mut ktimes := #[]
  for i in [0:n] do
    let env ← getEnv
    let t0 ← IO.monoNanosNow
    for (nm, lps, ty, v) in decls do
      let decl := Declaration.thmDecl
        { name := nm ++ Name.mkSimple s!"kcheck{i}", levelParams := lps, type := ty, value := v }
      match env.addDeclCore 0 512 decl none with
      | .ok _ => pure ()
      | .error e => throwError m!"kernel re-check failed: {e.toMessageData {}}"
    let t1 ← IO.monoNanosNow
    ktimes := ktimes.push (t1 - t0)
  logInfo m!"BENCH {label} time_us={median times / 1000} heartbeats={median hbs} \
    proof_objs={objs} kernel_us={median ktimes / 1000} aux_decls={decls.size}"

<!--
Second, separate draft (found while adding regression tests for this investigation). NOT FILED.
Kept apart from ISSUE.md: one issue per problem.
-->

**Title:** `omega`: "Application type mismatch" for `x % k` when `k : Int` is a ground expression such as `0 - 3`

### Prerequisites

* [ ] Check that your issue is not already filed: https://github.com/leanprover/lean4/issues
* [x] Reduce the issue to a minimal, self-contained, reproducible test case.
* [ ] Test your test case against the latest nightly release (https://live.lean-lang.org/#project=lean-nightly)
* [x] Soundness: n/a. The ill-typed term is rejected during elaboration, so `omega` reports an error instead of closing the goal.

### Description

`omega` fails with an internal `Application type mismatch` error, instead of either proving the goal or reporting that it could not, when an `Int` modulus is a ground expression whose truncated-`Nat` value differs from its `Int` value.

In `asLinearComboImpl` (`src/Lean/Elab/Tactic/Omega/Frontend.lean`), the `HMod.hMod` case evaluates the modulus with `groundNat?` even though the expression has type `Int`:

```lean
  | (``HMod.hMod, #[_, _, _, _, n, k]) =>
    match groundNat? k with
    | some k' => do
      let k' := toExpr (k' : Int)
      rewrite (← mkAppM ``HMod.hMod #[n, k']) (mkApp2 (.const ``Int.emod_def []) n k')
```

`groundNat? (0 - 3 : Int)` returns `0`, using `Nat` subtraction. `omega` then rewrites `x % (0 - 3)` with `Int.emod_def x 0`. That breaks the contract stated in the `groundNat?` docstring ("`e` is definitionally equal to `OfNat.ofNat n`"). The neighbouring `HDiv.hDiv` case already uses `groundInt?`.

### Steps to Reproduce

```lean
example (x : Int) (h : x % (0 - 3) = 1) : x % (0 - 3) < 5 := by omega
```

**Expected behavior:** the goal is closed, since `x % (0 - 3)` occurs as the same term on both sides.

**Actual behavior:**

```
error: Application type mismatch: The argument
  …
has type
  x % 0 - (0 + 1) = …
but is expected to have type
  x % (0 - 3) - (0 + 1) = ?c
```

Related behaviour from the same cause: `x % (2 - 3 + 4)` is read as `x % 4` instead of `x % 3`. A negative literal such as `x % (-3)` is treated as an opaque atom, so `example (x : Int) (h : x % (-3) = 1) : x % 3 = 1 := by omega` fails, although `Int.emod_neg` makes it a linear fact.

### Versions

`Lean (version 4.37.0-nightly-2026-10-23, x86_64-unknown-linux-gnu, commit f37a0276ae8b0c60dd705920c49b9fd0c16279cf, Release)`, Linux x86-64.

### Additional Information

Using `groundInt?` in that case (two lines) fixes all of these in an out-of-tree prototype:

```diff
   | (``HMod.hMod, #[_, _, _, _, n, k]) =>
-    match groundNat? k with
+    match groundInt? k with
     | some k' => do
-      let k' := toExpr (k' : Int)
+      let k' := toExpr k'
```

`Int.emod_def` holds for every divisor, and the existing `HDiv` case handles negative literal divisors. With the change, `tests/elab/omega.lean`, `omega_examples.lean` and `omegaCanon.lean` produce output identical to the current tactic. The prototype has not been built inside the compiler. Lean's test suite has no `omega` test with a negative or computed `Int` modulus.

*AI assistance:* [state here, per CONTRIBUTING.md]

### Impact

Add :+1: to [issues you consider important](https://github.com/leanprover/lean4/issues?q=is%3Aissue+is%3Aopen+sort%3Areactions-%2B1-desc).

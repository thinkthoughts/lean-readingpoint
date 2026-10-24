# Check the deferred-fact mechanism of the lazy variant against its `trace.omega` output.
#
# Trace lines are in execution order. A "round" is one call of processFacts + elimination; it
# ends with a flush ("adding N deferred facts"), a contradiction, or a case split.
#
#   D1  only original negated-divisibility facts are deferred: every "deferring fact" line comes
#       directly after an "adding fact: ¬…" line (a derived `0 < x % k` is never deferred again)
#   D2  a flush of N facts flushes exactly the N facts deferred in that round
#   D3  no deferral is pending when a disjunction is split or a branch is entered
#       (deferred facts are always tried before any case split)
#   D4  processing the flushed facts defers nothing new: between a flush and the next
#       "Extracted linear arithmetic problem" there is no "deferring fact" line
#   D5  every flushed fact is then processed as an ordinary fact before that same point, unless
#       an earlier one already made the problem infeasible (omega's addFact stops adding facts to an
#       impossible problem); in that case the round must end in a contradiction
#
# Usage: check_pending.py lazy FILE...  |  check_pending.py none FILE...
import sys

mode, files = sys.argv[1], sys.argv[2:]
bad = 0
for f in files:
    msgs = [l.strip()[len("[omega] "):] for l in open(f) if l.strip().startswith("[omega]")]
    errs, pend, ndefer, nflush, discarded = [], [], 0, 0, 0
    last_added = ""
    i = 0
    while i < len(msgs):
        m = msgs[i]
        if m.startswith("adding fact: "):
            last_added = m
        elif m.startswith("deferring fact: "):
            ndefer += 1
            if not last_added.startswith("adding fact: ¬"):
                errs.append(f"D1: deferral after {last_added!r}")
            pend.append(m[len("deferring fact: "):])
        elif m.startswith("adding ") and m.endswith(" deferred facts"):
            nflush += 1
            n = int(m.split()[1])
            if n != len(pend):
                errs.append(f"D2: flush of {n} with {len(pend)} pending")
            j = i + 1
            seen = []
            while j < len(msgs) and not msgs[j].startswith("Extracted linear arithmetic problem"):
                if msgs[j].startswith("deferring fact: "):
                    errs.append(f"D4: new deferral while processing flushed facts: {msgs[j]!r}")
                if msgs[j].startswith("adding fact: "):
                    seen.append(msgs[j][len("adding fact: "):])
                j += 1
            missing = [p for p in pend if p not in seen]
            if missing:
                nxt = next((x for x in msgs[j:] if x.startswith(("omega found a contradiction",
                    "Case splitting on", "deferring fact: ")) or x.endswith(" deferred facts")), "")
                if not nxt.startswith("omega found a contradiction"):
                    errs.append(f"D5: flushed facts not processed: {missing!r}")
            pend = []
        elif m.startswith("Case splitting on") or m.startswith("✅️ Assuming fact") or m.startswith("❌️ Assuming fact"):
            if pend:
                errs.append(f"D3: {len(pend)} deferred facts pending at {m[:40]!r}")
        elif m.startswith("omega found a contradiction"):
            discarded += len(pend)
            pend = []
        i += 1
    if mode == "none" and (ndefer or nflush):
        errs.append(f"unexpected deferral ({ndefer} deferred, {nflush} flushes)")
    print(f"{'ok' if not errs else 'FAIL':4} {f.split('/')[-1]}: deferred={ndefer} flushes={nflush} "
          f"unused={discarded}" + ("" if not errs else "  " + "; ".join(errs[:5])))
    bad += bool(errs)
sys.exit(1 if bad else 0)

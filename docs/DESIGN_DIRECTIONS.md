# Design Directions (Tier 2 — directional, NOT decided)

## What This Document Is

This is a PARKING LOT for design INTENT that is not yet built and not yet
decided. Everything here is a HYPOTHESIS or a DIRECTION — revisable,
subject to change once it can be felt in-engine. It is explicitly NOT a
specification.

**Do not read any item here as "how the game works."** These are things
we are LEANING toward, captured so the thought is not lost between the
session that conceived it and the session that builds it. When an item is
actually built, its DECIDED mechanism moves to the appropriate Tier 1 doc
(ENEMY_ARCHITECTURE.md, COMBAT_CONTRACT.md) and the decided tuning to
COMBAT_FEEL.md — and it leaves here.

Why one doc instead of separate enemy/player docs: several of these
items are ENTANGLED (a player powerup that affects enemy aggro is both a
player mechanic and an enemy mechanic). Splitting by subject would tear
them in half. They live together because the roguelite layer that will
hold them is itself one entangled system.

Each item notes: the direction, what would TRIGGER building it, and which
SEAM it attaches to (so it's actionable when the time comes).

---

## Aggro / Disengage

### Per-enemy aggro-loss personality
- **Direction:** Different archetypes should LOSE aggro differently, as a
  source of personality. E.g. a heavy enemy is relentless (never disengages);
  a fast/light enemy is skittish (disengages and re-approaches, hit-and-run).
- **Why deferred:** This is feel-tier and requires FEELING the archetypes.
  Designing relentless-vs-skittish before playing against the enemies is
  guessing at feel not yet earned. Becomes obvious once multiple archetypes
  exist and can be played.
- **Attaches to:** `_lose_aggro()` in ENEMY_ARCHITECTURE. Easy-axis version
  = an archetype data field (e.g. `loses_aggro: bool`, or a disengage-style
  enum). Hard-axis version = an override of `_lose_aggro()` for a
  behaviorally-divergent enemy.
- **Trigger to build:** when the 2nd/3rd archetype is authored and the
  roster needs to feel distinct.

### Player-earned aggro-drop mechanic (stealth / disengage)
- **Direction:** A roguelite powerup that lets the player DROP aggro —
  e.g. go invisible / break detection for a window. Disengage should COST a
  resource, not be free (free disengage = the "step back and reset"
  exploit that kills tension in distance-leash systems; arena context means
  a pure distance-leash is the wrong mechanic anyway).
- **Why deferred:** part of the roguelite buff/powerup layer, which does
  not exist yet. Mechanism is clear; the system it lives in isn't built.
- **Attaches to:** `_lose_aggro()` — the powerup calls the SAME mechanical
  seam the per-enemy behaviors use. This is WHY `_lose_aggro` was built as
  a clean attach point with no side effects.
- **Trigger to build:** when the roguelite powerup/buff layer is started.

### Distance-leash: explicitly NOT the primary mechanic
- **Decided-ish direction (worth recording so it isn't re-litigated):** In
  an ARENA, the traditional distance-leash (chase X units from spawn, then
  reset) solves world-traversal problems we don't have, and introduces the
  trivial "back up to reset" exploit. The current `leash_backstop` (30
  units) is a RUNAWAY GUARD only, not a gameplay disengage. Real aggro-loss
  should be MECHANIC-driven (the powerup) and/or per-enemy personality, not
  distance.
- **Note:** if a distance element is ever wanted, randomized leash distance
  (so the safe distance can't be memorized) is the community-validated
  anti-exploit approach — but the powerup route is preferred.

---

## Combat Feel (recovery & telegraph) — cross-ref COMBAT_FEEL.md

These are feel observations surfaced in S11; the tuning-value side belongs
in COMBAT_FEEL, but the DIRECTION is captured here.

### Player attack-recovery feels over-committed
- **Observation (S11, felt live):** After hitting/staggering an enemy and
  wanting to disengage, the PLAYER feels animation-locked in attack recovery
  — too grounded, can't move/cancel out as fast as wanted.
- **Direction:** investigate an attack-recovery cancel window /
  recovery-into-movement. This is the core "how committed is a swing"
  dial — Souls (committed) vs character-action (cancellable). Current feel
  sits too far toward committed for the desired feel.
- **Why deferred:** correct value requires a real TWO-WAY exchange to tune
  against — getting caught in recovery while an enemy threatens you is the
  situation that reveals the right window. Now possible (enemy attacks as of
  S11), so this is tunable soon.
- **Pairs with:** the existing combo-handoff re-aim backlog item (also an
  attack-recovery-window concern) — address together in a player-combat-feel
  pass.

### Enemy attack telegraph is currently invisible
- **Observation:** the enemy's WINDUP phase has no visual — the hitbox
  blinks on at strike time with no readable wind-up, because there is no
  enemy swing ANIMATION. The telegraph is temporal only.
- **Direction:** a visible windup (raised sword) is what makes the enemy
  fair and PARRYABLE (the S9 parry needs a readable tell to time against).
  The windup phase structure exists; it needs an animation to carry it.
- **Why deferred:** blocked on enemy swing animations (UAL2) + weapon
  models. Final attack SPACING (attack_range + hitbox reach + stop
  distance) is also deferred to the same point — no use tuning spacing/
  timing against a sliding capsule with no swing anim.
- **Trigger to build:** when enemy animations + weapon models are imported.
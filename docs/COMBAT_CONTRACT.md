# Combat Contract -- Hit Resolution

## What This Document Is

This is FOUNDATIONAL combat infrastructure, not design or tuning. It
describes the mechanical contract by which a hit is detected, resolved,
and reacted to -- the engine-level pattern every weapon, enemy, and
defensive verb routes through. It is taste-independent and intended to
persist across project versions (V2, V3, and beyond).

Parse this doc as: "how combat events are wired at the engine level."
It is distinct from COMBAT_FEEL.md (tuning values and design rationale,
which are revisable as taste changes). If a future version changes its
art, its weapons, or its feel, THIS contract still holds -- it is the
load-bearing layer underneath all of that.

Accuracy bar: error-free. This was verified against the live source
files at Session 9, not transcribed from memory. Any change to combat
wiring must update this doc in lockstep.

## The Contract (four parts)

### 1. Attacker detects victim
The hitbox owner's Area3D `area_entered` handler identifies the victim
via `area.get_parent()` and calls the victim's `take_damage()`. The
attacker never computes the result of its own hit. (Confirmed both
directions S9: dummy->player via `_on_dummy_hit`, player->dummy via
`_on_attack_hit`.)

### 2. Receiver owns the outcome
`take_damage()` lives on the VICTIM. The victim alone decides what the
hit means -- full damage, blocked, parried, or multiplied (e.g. by a
stagger state). This is why a defensive verb (block, parry) is
implemented on the receiver, never inferred by the attacker.

### 3. Outcome returns upward via `-> bool`
`take_damage()` returns a bool reporting whether the hit was negated by
a defensive action (parry = true). The attacker reads this return to
react -- e.g. the dummy self-staggers when its hit comes back parried.
This is the channel by which a defensive action on the receiver produces
a consequence on the attacker, WITHOUT the attacker holding a reference
to the receiver's internal state and WITHOUT the receiver reaching into
the attacker.

IMPORTANT -- this is a general pattern, instantiated per-side only where
a defensive verb exists. As of S9 only the PLAYER has a defensive verb
(block/parry), so only `player.gd take_damage` returns bool. S12 lesson:
a victim MUST return bool if any attacker assigns the return to a strictly-
typed `var x: bool` -- a `-> void` victim yields Nil at a strict call site
and throws. The dummy's `take_damage` is still `-> void` (nothing reads its
return); the enemy's `take_damage` is now `-> bool` returning false on all
paths (DEAD early-return, death path, stagger path) because the dummy
assigns it to `var was_parried: bool`. No defensive verb yet -- only the
return values change when one arrives, not the signature. EXTENSION POINT:
the `-> bool` signature is already correct; a future defensive verb changes
only the return values, not the function shape.

### 4. Physics-property toggles inside signal dispatch must defer
An Area3D's `monitoring` property cannot be set directly from inside an
`area_entered` handler -- the physics engine locks state during signal
dispatch and throws ("Function blocked during in/out signal"). Use
`set_deferred("monitoring", value)` instead. The GAME-LOGIC flag that
gates behavior (`_staggered`, `_blade_live`) is set SYNCHRONOUSLY and is
what the logic reads each frame; the physics property catches up
deferred. Because logic reads the flag (not the property), deferral
opens no one-frame gap. (S9: `_enter_stagger()` sets `_staggered = true`
and `_blade_live = false` synchronously, defers `monitoring`; the
`_physics_process` swing-suppression branch reads `_staggered`.)

## Established Layer Scheme (from S8)
- Layer 4: hitboxes (attack-emitting Area3D)
- Layer 5: hurtboxes (damage-receiving Area3D)
- Hurtbox sizing is asymmetric on purpose (see COMBAT_FEEL.md): player
  hurtbox tight (fewer cheap hits), enemy hurtbox generous (>= body).

## Self-Hit Guard
Area3D has no same-body auto-exclusion. Every hit handler must guard
`if area.get_parent() == self: return` before applying damage.

## Contract Extension Confirmed: Enemy Attacker (Session 11)

The enemy is the second attacker built against this contract; the contract
held when extended.
- Enemy HitArea3D (layer 8 / mask 16, the hit-layer contract) detects the
  player via body_entered and calls the player's take_damage — attacker
  detects victim, receiver owns outcome (parts 1 & 2). Self-hit guard
  (get_parent() == self) present.
- Enemy take_damage is `-> bool` returning false on all paths (S12:
  contract-compliance fix). The dummy assigns the return to `var was_parried:
  bool`; a `-> void` victim yields Nil at that strict call site and throws.
  No defensive verb yet -- return values (all false) change when one arrives;
  the `-> bool` signature is already correct per part 3.
- Stagger-mid-swing disarms the enemy hitbox via
  set_deferred("monitoring", false) — part 4 (physics-signal re-entrancy)
  applies to the enemy's own attack interruption.
# Enemy Architecture (as-built)

## What This Document Is

This is the FOUNDATIONAL, as-built architecture of the enemy system —
the decided mechanism, not design intent or tuning. It is the enemy
sibling to COMBAT_CONTRACT.md: taste-independent, load-bearing, intended
to persist across archetypes and versions. It describes how an enemy is
structured, how its state machine is wired, and the SEAMS where future
behavior attaches.

Accuracy bar: as-built and verified. Everything here was built and
confirmed in-engine through Session 11 (nav spike → base enemy →
detection → chase → attack). Where a field or seam EXISTS but is not yet
consumed, it is marked "declared, awaiting consumption" — do not read
those as active behavior.

Distinct from:
- DESIGN_DIRECTIONS.md — undecided, revisable design intent (Tier 2).
- COMBAT_FEEL.md — tuning values and feel rationale (Tier 2).
This doc is the decided mechanical layer underneath those.

---

## Scalability Direction (the spine)

Built so the 3 ship archetypes (basic swordsman / fast-light / heavy)
become 3 DATA files, not 3 code paths, while leaving the door open for a
behaviorally-divergent enemy (ranged, boss) to extend the base.

- **One enemy.gd + one enemy.tscn** hold the SHARED infrastructure: state
  machine, navigation, detection, health / take_damage / stagger, attack
  phases. Concrete archetypes do NOT duplicate this.
- **EnemyArchetype resource (.tres)** is the TUNING AXIS. The archetypes
  differ in DATA only. Mirrors the WeaponResource pattern.
- **Data-driven for the easy axis, inheritance-open for the hard axis.**
  Speed/health/damage/ranges/timing differences are data. A future
  enemy with genuinely different LOGIC (ranged, boss) `extends Enemy` and
  overrides — the base is structured so its seams are overridable methods,
  not inlined constants.

As of Session 11: the spine is built; ONE archetype authored
(basic_swordsman.tres); single enemy proven end-to-end. Architecture
supports 3; one is instantiated.

NOT built (deliberately deferred): the enemy SPAWNER (waves, respawn,
max-count). The enemy instances cleanly with no hard scene dependencies,
so it is spawn-ready, but the spawner is the run-loop session, not this one.

---

## State Machine

Enum-based, dispatched via `match` in `_physics_process` — the same idiom
as the player's state machine (no new structural concept).

    enum State { IDLE, CHASE, ATTACK, STAGGER, DEAD }
    var _current_state: State = State.IDLE

    match _current_state:
        State.IDLE:    _process_idle(delta)
        State.CHASE:   _process_chase(delta)
        State.ATTACK:  _process_attack(delta)
        State.STAGGER: _process_stagger(delta)
        State.DEAD:    _process_dead(delta)

Transitions assign `_current_state` inside dedicated `_enter_*()`
functions (the player's `_enter_attack` idiom).

State status as of Session 11:
- IDLE — built. Stands; polls for player; transitions to CHASE on detect.
- CHASE — built. Steers to player; faces movement dir; holds at engage
  range facing the player; gives up on aggro loss.
- ATTACK — built. Windup → active → recovery swing; state-gated cadence.
- STAGGER — built (carried from the dummy's pattern, adapted to state).
  Freezes movement, runs timer, returns to IDLE; interrupts CHASE and
  ATTACK; suppresses steering and kills any live hitbox.
- DEAD — DECLARED, NOT BUILT. Enum member + stub `_process_dead`. Wiring
  (health-zero → DEAD → stop processing → despawn/ragdoll) is the next
  session's opener.

---

## The Seams (where future behavior attaches)

These are deliberate extension points. Each does the taste-independent
mechanical minimum now; future behavior attaches without restructuring.

### `_lose_aggro()` — aggro-drop attach point
Mechanical core ONLY: `_current_state = State.IDLE`. Does NOT touch
`_player_ref` (see detection ownership below).
- Current sole caller: a generous distance backstop (`leash_backstop`,
  default 30, > arena size) — a runaway guard, NOT a gameplay mechanic.
- FUTURE attach point for: a player-earned stealth/disengage powerup;
  per-archetype disengage behaviors (relentless enemies never call it;
  skittish ones call it and reposition). Those are DEFERRED, Tier 2 —
  see DESIGN_DIRECTIONS.md. Decided here: this is the function they hang on.
- Open for override: a divergent enemy may override `_lose_aggro` entirely.

### `_get_engage_range() -> float` — stop/attack distance
Returns `archetype.attack_range` today (null-guarded fallback). The chase
hold-branch and attack spacing read THIS, never the field directly.
- FUTURE growth: multiple attacks with differing reach change what this
  RETURNS (max reach, or the chosen attack's reach, or a min/max BAND).
  Callers never change. The single-number-today becomes a band-tomorrow
  behind a stable signature.

### `_can_detect_player() -> bool` — detection decision
Returns proximity result today (`_player_ref != null`, maintained by the
detection area). Structured so a line-of-sight raycast slots in as an
`and _has_line_of_sight()` INSIDE this one function — no restructure.
- Layered-detection-ready: proximity now (gray-box has no walls);
  LoS raycast attaches here when cover geometry exists.

### Windup / Active / Recovery — attack phasing
ATTACK runs three phases with `@export` durations (windup_time,
active_time, recovery_time) for feel tuning. The attack HITBOX is live
ONLY during ACTIVE; explicitly dead in WINDUP and RECOVERY.
- WINDUP is the telegraph (currently temporal only — VISUAL telegraph
  awaits a swing animation; see COMBAT_FEEL / DESIGN_DIRECTIONS).
- FUTURE: phase timing becomes animation-driven once enemy swing anims
  exist; durations stop being free timers and key off animation frames.

---

## Detection (single-owner state + edge/level hybrid)

The detection design that the Session 11 `_player_ref` bug forced into
its correct shape. This pattern is LOAD-BEARING for multi-enemy setups.

- **DetectionArea (Area3D)**: SphereShape3D, radius from
  `archetype.aggro_range`. `monitoring = true`. `collision_mask` = the
  PLAYER body's layer (2). Its own `collision_layer = 0` — DELIBERATE:
  it is a detector, not a detectable (the official Godot detector pattern).
- **`_player_ref` has ONE owner: detection.** Written only in three sites,
  all detection-concern: `body_entered` (set), `body_exited` (clear),
  and the IDLE level-poll re-acquire. NOTHING ELSE writes it — stagger,
  lose-aggro, and attack are all detection-NEUTRAL.
- **Edge signals fire transitions; a level poll makes IDLE robust.**
  `body_entered`/`body_exited` are edge-triggered (fire once on boundary
  cross). For "is the player still present" — e.g. after a stagger while
  the player stood motionless inside the sphere — IDLE polls
  `get_overlapping_bodies()` and re-acquires. Trigger + polling combined;
  CHASE still uses the ref + distance checks (no per-frame polling there).
- **Lazy-guarded reference.** The player is never cached at `_ready()` /
  `@onready` — resolved lazily, guarded against null, to survive
  spawn-order (bites multi-enemy setups).

---

## Combat Wiring (instantiates COMBAT_CONTRACT)

The enemy is the second attacker built against COMBAT_CONTRACT.md;
the contract held when extended.

- **take_damage(amount) -> void** — void return is correct: the enemy has
  no defensive verb yet (contract part 3 — bool is for parry/block, which
  is player-only as of now). Taking a hit transitions to STAGGER.
- **Attack hitbox** — HitArea3D, layer 8 / mask 16 (the S8 hit-layer
  contract; mirrors the dummy). `body_entered` calls the player's
  take_damage (receiver owns outcome). Self-hit guard:
  `get_parent() == self` early-return.
- **Damage** = `archetype.attack_damage`. **Cadence** =
  `archetype.attack_interval`.
- **Cannot-drift debug convention** — the HitArea's monitoring and its
  DebugMesh visibility are set TOGETHER at every site, gated by
  `debug_draw_hitboxes`. Reused from the dummy; reuse for all hit-emitters.
- **Stagger-mid-swing** kills the hitbox via
  `set_deferred("monitoring", false)` (physics-signal re-entrancy lesson),
  debug off, phase abandoned.

---

## Generous Hurtbox (carried principle)

The enemy HurtArea capsule (r=0.55, h=2.0) is LARGER than its body capsule
(r=0.4, h=1.8) — the player-favoring asymmetric-hurtbox principle (swings
that look like hits land). Do NOT shrink the hurtbox to match the body.

---

## EnemyArchetype — fields

The resource shape is FINAL (authored once, the WeaponResource lesson).
Later increments WIRE existing fields; they do not reshape the resource.

| Field | Status as of S11 |
|---|---|
| display_name | declared |
| max_health | consumed (health pool) |
| move_speed | consumed (chase steering) |
| attack_damage | consumed (attack) |
| aggro_range | consumed (detection sphere radius) |
| attack_range | consumed (engage/stop distance via _get_engage_range) |
| attack_interval | consumed (attack cadence) |
| stagger_duration | consumed (stagger timer) |
| stagger_damage_mult | consumed (stagger damage) |
| equipped_weapon (WeaponResource) | DECLARED, awaiting consumption — enemies do not yet carry weapons; hitbox reach is fixed in-scene, not weapon-driven |

---

## Engine Behavior Learned (Session 11)

Enemy-specific lessons. The cross-cutting ones (marked ‡) are candidates
to migrate to CLAUDE.md global gotchas.

- ‡ **Area3D detects a BODY via the AREA's mask vs the BODY's layer.** The
  area's own layer is irrelevant to what IT detects. A pure detector sets
  layer 0, mask = target-body-layer (the official pattern). Inverting this
  is the cause of "area never fires."
- ‡ **A code-constructed Area3D defaults collision_mask to 1, not the
  .tscn value.** If you build/configure an area in `_ready()`, set the
  mask explicitly — the .tscn value is not authoritative once code touches
  it. (This was the detection-never-fires bug.)
- ‡ **`body_entered` is edge-triggered, not level.** For ongoing presence
  use `get_overlapping_bodies()`. Don't make recovery depend solely on a
  past edge signal.
- **Shared state needs one owner.** `_player_ref` written by multiple
  concerns (detection + stagger) caused the post-stagger no-re-aggro bug.
  One writer (detection); other states are neutral. When a behavior's
  correctness depends on an assumption about shared state, design the
  dependency OUT (level-poll recovery), don't just protect the invariant.
- **Nav map isn't queryable until the physics frame AFTER bake.** An
  instanced enemy must guard against requesting a path before the map is
  ready (`map_get_iteration_id == 0` → bail that frame). Do NOT cache nav
  state at `_ready()`. (Same spawn-order discipline as the player ref.)
- **`get_overlapping_bodies()` returns an untyped Array** — declare
  `var bodies: Array = ...`, not `:=` (strict-typing inference fails).
- **Hitbox active-phase must be the ACTIVE phase, explicitly.** Hitbox
  live only in ACTIVE; explicitly dead in WINDUP (the telegraph must not
  deal damage) and RECOVERY. Guard with explicit-off on phase entry so no
  phase inherits a stale-live hitbox.
- **Engage range must sit INSIDE effective hitbox reach.** An enemy that
  stops beyond its own reach whiffs. effective reach = hitbox offset.z +
  (box depth / 2); stop distance must be < reach, with margin for a MOVING
  player (a static-overlap margin of ~0.2 is too thin — player movement
  during windup escapes it).
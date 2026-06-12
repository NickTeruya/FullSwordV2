# Build Sequence & Method

## What This Document Is

This is the **how and why of building**, not the what. Other docs describe
the game's mechanisms (ENEMY_ARCHITECTURE, COMBAT_CONTRACT), its undecided
intent (DESIGN_DIRECTIONS), or its tuning (COMBAT_FEEL). This one captures
the *method* used to build them and the *order* things get built in.

It has three layers, stable at the top, living at the bottom:

1. **Portable principles** — the working method. Project-independent. These
   transfer to V3, or to a different game entirely. Read this to know HOW
   to work.
2. **V2 as-built decisions (archaeology)** — the load-bearing architectural
   calls V2 made, and WHY. A rebuild reads this to know what to carry
   forward versus what to discard. The code won't survive a rebuild; these
   decisions are the asset that should.
3. **The living sequence** — the current build order and backlog, and the
   reasoning that orders it. Updates each session.

The intent: if V2 is ever rebuilt (V3), this doc is the foundation it rests
on — so the hard-won reasoning isn't re-derived from scratch.

---

# LAYER 1 — PORTABLE PRINCIPLES (the method)

## Recon before edit

Every non-trivial change opens with a **read-only, fenced recon** — read
the relevant code and report current state BEFORE any edit. Decide the
change against what's actually there, then make it. This is why increments
land first-try: the gap is understood before it's filled. The bugs that
slip past recon are the runtime/timing kind invisible to a static read
(e.g. a tree-lock during `add_child`) — not the logic kind, which recon
catches.

Corollary: **read the file you're about to depend on.** When wiring code to
a method on a file not yet read, confirm the signature exists as assumed
before building against it.

## Testability-first sequencing

Pick the next build target by **what it makes verifiable**. A feature that
can't yet be seen, pressed, or measured is a weaker session goal than the
system that unlocks its verification.

- Build the system that gives the next feature a feedback surface first.
  Dummy before hit-detection (a hit needs something to land on). DEAD
  before spawner (a spawner that can't reap dead entities leaks). Spawner
  before waves (waves need something to spawn).
- When a feature's payoff isn't yet testable, build only the half that is,
  and defer the rest to the session where it becomes verifiable.
- Each build should produce something to look at, press, or measure.

## Build for what's consumed, not what's coming

Build the piece something uses NOW. Defer the piece nothing listens to yet,
even when you can see it coming.

- Example: enemy live-tracking. Built the group membership (consumed now —
  "who's alive" is queryable). Deferred the death *signal* (nothing reacts
  to a death yet). When respawn/wave/death-split logic arrives to consume
  it, build the signal then — designed against its real consumer.
- This resists the "build the complete system because I can see the whole
  shape" pull, which is what inflates increments and bakes in guesses.
- Pairs with the CLAUDE.md rule: no speculative scaffolding. Don't add
  fields, methods, or nodes nothing currently references.

## Seams over inlined constants

At points where future divergence is expected, build an overridable method
(a *seam*), not an inlined constant. The seam does the taste-independent
mechanical minimum now; future behavior attaches without restructuring.

- Two axes of growth, kept separate:
  - **Data axis** — variants that differ only in values become DATA files
    (a Resource / `.tres`), not code paths. (Enemy archetypes, weapons.)
  - **Inheritance axis** — variants with genuinely different LOGIC
    `extends` the base and override the seams.
- A single value today (`_get_engage_range()` returns one number) can
  become a band tomorrow behind a stable signature — callers never change.

## Tier docs by stability

Every documented fact lives in a tier that signals how much to trust it and
when it's allowed to change. Mixing tiers in one doc destroys this signal.

- **As-built / decided** (taste-independent, load-bearing, persists across
  versions) — e.g. COMBAT_CONTRACT, ENEMY_ARCHITECTURE. Changing combat
  wiring updates these in lockstep.
- **Undecided intent** (directional, revisable, a parking lot) —
  DESIGN_DIRECTIONS. "We're leaning toward X." Never read as how the game
  works.
- **Tuning** (values and feel rationale, revisable as taste changes) —
  COMBAT_FEEL.
- A decided mechanism moves UP a tier when built: from intent →
  as-built, with its tuning split into the tuning tier.

## One change at a time, attributable

When two adjacent changes affect the same feel, land them separately so you
can attribute what each one does. Bundling a cancel-window change with a
combo-window change means you can't tell which fixed (or broke) the feel.
Note the deferred one; do it next.

## Diagnostics before tuning

Instrument and measure; don't iterate by feel on a problem that has a
number. Read actual values, math the answer. Tune by feel only the things
that ARE feel (jump apex gravity, cancel-window timing) — not the things
that are arithmetic (engage range vs. hitbox reach).

## Defer by default

When scope is uncertain, defer. A parked item with its trigger-to-build
recorded is cheap; a half-built speculative system is expensive. The
backlog growing is fine as long as it's ordered (see Layer 3) and each item
knows what unblocks it.

---

# LAYER 2 — V2 AS-BUILT DECISIONS (archaeology for a rebuild)

These are the load-bearing architectural calls V2 made. A V3 rebuild should
read each as "here's what V2 decided and why" — then consciously carry it
forward or reject it, not re-derive it blind.

## Combat resolution is a contract, receiver-owned

Hit resolution routes through one taste-independent contract
(COMBAT_CONTRACT). The decisions that proved durable:

- **Receiver owns the outcome.** The victim's `take_damage()` decides what a
  hit means (full / blocked / parried / stagger-multiplied). The attacker
  never computes the result of its own hit. This is why a defensive verb
  lives on the receiver, never inferred by the attacker.
- **`take_damage` returns `-> bool`** — the channel by which a defensive
  action on the receiver produces a consequence on the attacker, without
  either side reaching into the other's internals. EVERY `take_damage` an
  attacker might hit must return a bool, even one with no defensive verb
  (it returns `false` — "nothing negated"). A `-> void` victim assigned to
  a strict `: bool` at the call site returns Nil and throws. (Learned S12:
  the dummy hitting a spawned enemy whose `take_damage` was still `-> void`.)
- **Physics-signal re-entrancy: defer the toggle.** An Area3D's `monitoring`
  can't be set from inside its own `area_entered`/`body_entered` handler
  (physics state is locked during dispatch). Set the GAME-LOGIC flag
  synchronously (logic reads the flag); defer the physics property
  (`set_deferred("monitoring", value)`). No one-frame gap because logic
  reads the flag, not the property.
- **Self-hit guard everywhere.** Area3D has no same-body auto-exclusion.
  Every hit handler guards `if area.get_parent() == self: return`.

## Scalable entities: data axis + inheritance axis

The spine pattern for any entity that needs variants (enemies, weapons):

- ONE base scene + ONE base script hold shared infrastructure (state
  machine, navigation, detection, health, attack phases). Variants do NOT
  duplicate this.
- A Resource (`.tres`) is the DATA/TUNING axis — variants that differ only
  in values (speed/health/damage/ranges) are data files.
- The base's seams are overridable methods, so a behaviorally-divergent
  variant (ranged, boss) can `extends` and override without touching the
  shared base.
- The Resource SHAPE is authored once and treated as final; later
  increments WIRE existing fields, they don't reshape the resource. A field
  can be "declared, awaiting consumption" — present but not yet read.

## Shared mutable state needs exactly one owner

A reference written by multiple concerns produces order-dependent bugs.
(S11: `_player_ref` written by both detection and stagger → post-stagger
no-re-aggro bug.) Fix: ONE writer (the concern that owns the meaning);
other states stay neutral. And where correctness depends on an assumption
about shared state, design the dependency OUT (a level-poll recovery)
rather than just protecting the invariant.

## Spawn-order discipline (nothing cached at _ready)

An entity that can be instantiated at runtime at an arbitrary time/place
must not assume the world is ready when it is.

- Resolve external references LAZILY, guarded against null (the player ref
  is resolved on detection, never cached `@onready`).
- The nav map is NOT queryable until the physics frame AFTER bake. Guard
  (`map_get_iteration_id == 0` → bail that frame); retry next frame. Don't
  cache nav state at `_ready()`.
- A node added from inside its parent's setup hits a tree-lock ("parent
  busy setting up children"). Defer the spawn pass (`call_deferred`) so it
  runs after the spawner is itself in-tree. (S12.)
- Net rule: a freshly instantiated entity completes `_ready()` using only
  its OWN subtree — no `get_parent()`, no `../` paths, no cross-scene
  lookups at ready time.

## State machines: enum + match, transitions in _enter_*

Both player and enemy use an enum dispatched via `match` in the physics
process, with transitions assigned inside dedicated `_enter_*()` functions.
A terminal state (DEAD) is *absorbing* — nothing transitions out, and the
entry guard blocks re-entry. The gameplay state machine drives the
AnimationTree, never the reverse (CLAUDE.md non-negotiable).

Caveat the player SM surfaced (S12): when attack phases are read from
AnimationTree node names + clip positions rather than explicit phase timers,
the phase logic is more implicit and clip-coupled than a clean timer-driven
SM. Workable, but a rebuild might prefer explicit phase enums + timers for
the player too (as the enemy has), to decouple feel-logic from clip length.

## Engine gotchas worth carrying (see CLAUDE.md for the full list)

- Area3D detects a BODY via the AREA's mask vs the BODY's layer; the area's
  own layer is irrelevant to what it detects. A pure detector is layer 0,
  mask = target layer.
- A code-touched Area3D defaults `collision_mask` to 1, not the `.tscn`
  value — set it explicitly in code.
- `.tscn` sub-resource properties are not reliably applied at runtime; set
  critical ones in `_ready()` via script, keep `@export` for tunability.
- Edge-triggered signals (`body_entered`) need a level-poll companion
  (`get_overlapping_bodies()`) for "still present" logic.

---

# LAYER 3 — THE LIVING SEQUENCE (current order + backlog)

## The ordering principle: inside-out (build the fun first)

Validated against external game-design consensus (core-loop / prototyping
literature). The principle: **find the fun in the smallest unit before
building outward.** Strip to the bare minimum and ask "is the single act —
striking an enemy — satisfying?" before adding systems that wrap it.

There are nested loops, built innermost-first:

- **Layer 0 — the strike.** Does one attack against one enemy feel good?
  Game feel: responsive control, readable telegraphs, weight, impact.
- **Layer 1 — the encounter (mechanics loop).** Multiple/varied enemies;
  reading and surviving a fight.
- **Layer 2 — the run (meta loop).** Waves, level/run structure, rewards.
- **Layer 3 — meta progression.** Stats, levels, equipment.

**Each outer layer is only worth building once the layer it wraps is
proven.** Building a progression system (L3) to reward a fight (L0) that
doesn't feel good yet is decorating a problem. The meta loop is designed
AFTER there's a proven core for it to reward — not before.

**Portfolio lens sharpens this:** a combat demo is judged on whether combat
*feels* good, not on progression depth. That points even harder at finishing
Layer 0 before reaching outward.

Signal that confirmed L0 isn't done (S12): three spawned enemies produced an
"how do I deal with this?" reaction — good challenge, but the player toolkit
felt inadequate to it. The fix is L0 (player agency/feel), not L1 (more
enemies) or L2 (run structure).

## Current order

**Layer 0 — make the single fight feel good (ACTIVE focus):**
1. Cancel-window pass — attack-recovery cancel into move/turn/block (Option
   A: single `cancel_window_open` threshold, all cancels unlock together;
   cancel-into-block included). Scoped & prompt-ready as of S12 wrap.
2. Jump float — tuned via `jump_peak_gravity_multiplier` (Inspector knob,
   not a build item). Effectively done; tune further to taste.
3. Enemy swing animations + weapon models — THE keystone. Unlocks the
   enemy telegraph → activates the already-built (S9) parry, which is
   currently dormant for want of a readable tell → makes attack spacing
   tunable. Heaviest L0 lift; crosses into the animation pipeline. Highest
   leverage in the backlog because it lights up existing code.

**Layer 1 — make the fight varied and legible (after L0 feels good):**
4. Enemy health bars — readability gap (no visual enemy health since S11).
   Clean standalone increment; good palate-cleanser between heavier work.
   Independent of everything.
5. 2nd / 3rd archetype (`.tres` authoring) — proves "instantiate N from
   data" with real variety. Archetype FEEL (relentless vs. skittish) can't
   be tuned until the fight is good and multiple exist to play against, so
   this follows the L0 feel work.

**Layer 2 — encounter / run structure (DESIGN-GATED, not yet buildable):**
6. Wave / progression design conversation — decide what a "wave" is vs.
   discrete levels (clear 1 → advance 2) vs. both. Gates the spawner's next
   increment AND the L3 cluster. Likely output: PROGRESSION_DIRECTIONS.md
   (Tier 2). This is a CONVERSATION, not a build.
7. Death-split enemy (dies → spawns smaller copies) — bridges L1↔L2; wants
   the death SIGNAL deliberately deferred in S12 (multiple things react to
   a death → signal, not group-polling). Ties to spawn points.

**Layer 3 — meta progression (build LAST):**
8. Character levels & stats + equipment — entangled cluster (levels gate
   progression, stats scale with levels, equipment modifies stats).
   Equipment has a live seam (`equipped_weapon` on EnemyArchetype,
   declared-awaiting-consumption; WEAPON_SYSTEM exists). Huge surface area;
   only pays off wrapped around a proven loop. Wants its own design doc when
   picked up. Consensus is blunt: do NOT build this early.

## Feel-flags logged (tuning concerns, not increments)

- **Combo chain window never closes** — a late attack press chains right up
  to clip end; you can't *not* chain on a fumbled late press. Separate dial
  from the cancel window; revisit during combat-feel work once the cancel
  window is in.
- **Enemy stun-lock** — fast hits can chain-stagger an enemy to death with
  no recovery window (observed: 5 staggers→DEAD in one log). Infinite stun
  removes enemy threat. Tune during the combat-feel pass.

## Out of scope for V2 ship (from CLAUDE.md)

Online multiplayer, persistent meta-progression, audio production,
cutscenes/narrative, tutorial. (Note: the L3 stats/equipment cluster is
in-game progression, distinct from *persistent* meta-progression across
runs, which stays out of scope.)

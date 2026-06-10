# V2 Architecture

This document defines the architectural direction for the v2 prototype.
It captures lessons from v1 (sessions 1-18) and commits to a clean
foundation for the next phase of the project.

See also:
- `docs/REFERENCES.md` — design north stars (Sandfire as primary)
- `docs/WORKFLOW_REFLECTION.md` — meta-reflection on agentic workflow
- `FULLSWORD_DEMO_SPEC.md` (root) — original v1 design spec

## Design Pillars (Inherited and Sharpened from v1)

1. **Feel is the secret sauce.** Level design, textures, and assets are
   polish layered on top of mechanics that already feel good in a gray
   box. If the gray box isn't fun, no amount of art saves it.
2. **Skill reliably overcomes chaos.** Players should understand why
   they won or lost. Emergent physics moments are spice, not the meal.
3. **Agency density.** Every frame of input has a clear, satisfying
   consequence. No animation locks the player out longer than needed.
   Cancel windows, input buffering, and forgiveness systems are
   non-negotiable.
4. **Fun and unserious.** Fantasy roguelite. Visual jank from gameplay
   modifiers (e.g., absurdly long swords) is a feature, not a bug.

## Feel References

Primary architectural reference: **Sandfire** (see REFERENCES.md). Same
engine, same solo dev constraint, same broad combat shape.

Aspirational feel references — what the tuning is reaching toward:

- **Celeste** — input buffering, coyote time, invisible forgiveness
  systems, dash precision, cancel windows.
- **Warframe** — traversal expressiveness, movement vocabulary that
  combines fluidly, agency density across every input frame.

We will not match Celeste or Warframe in v2. The point is that the
architecture must make tuning toward that bar **possible**. Every feel
parameter is an exported variable, tunable live in the Inspector.

## What Carries Forward from v1

- Resource-based weapon definitions (`WeaponResource.tres`). Proven
  pattern, extends cleanly to enchantments.
- HitArea3D / HurtArea3D component pattern with proper layer scheme
  (4: hitboxes, 5: hurtboxes).
- BoneAttachment3D for weapon-to-hand binding.
- Animation-driven swings with hitbox timing via playback percentage
  polling (avoids glb AnimationPlayer ownership issues).
- Quaternius asset ecosystem (UAL1, UAL2, Universal Base Characters,
  Modular Character Outfits Fantasy) — native skeleton compatibility,
  no Mixamo→Humanoid remap fights.
- All feel parameters exposed as `@export` for live Inspector tuning.

## What Changes from v1

### Player: CharacterBody3D, not RigidBody3D

v1 used RigidBody3D for the player. This was the root cause of:
- Jolt force-application unreliability (Session 5)
- Orbit artifact on direction change (Session 14, known engine
  limitation under continuous PhysicalBoneSimulator3D)
- Need for manual velocity assignment workarounds

v2 uses CharacterBody3D with `move_and_slide()`. Deterministic
movement. No force absorption. No orbit. Standard Godot pattern used
in 95% of shipped third-person games.

### Ragdoll: Death state, not continuous simulation

v1 ran PhysicalBoneSimulator3D continuously with `influence` blending
between 0.0 (animation) and 1.0 (ragdoll). This solved T-pose-snap
on stagger recovery but created the orbit artifact and complex
tween management.

v2 ragdoll is a **state transition**, not a continuous condition:
- On death: hide animated mesh, spawn ragdoll prop in same pose,
  transfer inherited velocity + killing impulse.
- Ragdoll exists for ~5s for the death animation, then despawns
  or remains as static corpse prop.
- Stagger is a short canned animation with input lockout, not
  physics blending. Procedural impact reactions (spine bend, arm
  push-back via IK) layered on top if needed.

### Explicit two-layer state machine

v1 state was scattered across nodes: `is_attacking` on
WeaponController, `_crouching` on CharacterMovement, `ragdoll_active`
on QuaterniusRagdoll, tweens fighting each other.

v2 uses an explicit two-layer state machine:

**Outer layer (mode):**
- `Combat` — normal gameplay
- `Dead` — death sequence playing
- `Cutscene` — non-interactive moments (post-arena, buff selection)

**Inner layer (action, within Combat):**
- `Grounded` — idle, walking, running
- `Airborne` — jumping, falling
- `Attacking` — attack animation playing (light, heavy, weapon-specific)
- `Dodging` — dodge roll with i-frames
- `Staggered` — hit recovery, input locked
- `Recovering` — post-action recovery frames (cancellable to specific states)

Each action state has **cancel windows defined as data**, not code:
- `Attacking_Light`: cancellable to `Dodging` after frame N
- `Attacking_Heavy`: cancellable to nothing until `animation_finished`
- `Dodging`: cancellable to `Attacking` during recovery frames X-Y

### Animation: AnimationTree with embedded StateMachine

v1 drove animations directly via `AnimationPlayer.play()` calls from
multiple scripts, with `is_attacking` flag guarding against locomotion
override.

v2 uses Godot's `AnimationTree` with an embedded `AnimationNodeStateMachine`
as the visual layer. The gameplay state machine drives the AnimationTree
parameters; the AnimationTree drives the visuals. **Gameplay state
machine drives animation state, never the other way around.**

### Root motion for committed attacks

v1 attacks were stationary swings — the character did not advance into
the strike.

v2 attacks use **root motion** from the UAL2 animations. The animator's
forward motion during a heavy swing is extracted via
`AnimationTree.get_root_motion_position()` and applied to the
CharacterBody3D's velocity. Attacks feel weighty and committed because
the character physically leans into them — the way Sandfire's attacks do.

## Feel Architecture

Five systems that separate "physics combat prototype" from "game that
feels good." All five are first-class architectural concerns, not
afterthoughts.

### 1. Cancel windows (per-state, data-driven)

Each action state declares its cancel rules as exported data:

```gdscript
@export var cancel_to_dodge_frame: int = 8
@export var cancel_to_attack_frame: int = 12
@export var animation_finishes_frame: int = 20
```

The state machine checks the current playback frame against these
thresholds on each transition request. Cancel rules tunable live in
Inspector without code changes.

### 2. Input buffering

A ring buffer of recent input events with timestamps. On every state
transition, check the buffer for inputs that occurred within the last
`input_buffer_ms` (~100-150ms) and consume them if the new state
accepts them.

This is the single most common reason indie action games feel stiff
when they shouldn't. Adding it once at the input layer fixes every
state transition simultaneously.

### 3. Coyote time

If the player presses jump within `coyote_time_ms` after walking off
a ledge, the jump still registers. Same pattern for other
context-sensitive inputs (e.g., dodge during hit-flinch i-frames).

### 4. i-frames on dodge/dash

The `Dodging` state has explicit start/end frames during which the
player is invulnerable. Hitboxes that overlap the hurtbox during
i-frames are ignored. Tunable per dodge variant.

### 5. Hit recovery cancel windows

After taking a hit, the player can cancel out of stagger early by
attempting a specific action (dodge, attack). This is what makes
combat feel like a conversation rather than a punishment.

## Combat System

### Player

- CharacterBody3D with capsule collision
- AnimationTree driving Quaternius rig
- Two-layer state machine (gameplay)
- Stamina pool that gates heavy attacks and dodges
- Light attack, heavy attack, dodge, jump as core verbs

### Enemies

Target for v2 ship: **3 enemy archetypes**, all on the same Quaternius
skeleton for animation reuse:

1. **Basic swordsman** — UAL2 sword animations on Quaternius rig.
   Medium speed, medium damage. The roguelite tutorial enemy.
2. **Fast/light enemy** — smaller Quaternius character. Higher speed,
   lower damage, more aggressive.
3. **Heavy enemy** — slow, high damage. Forces deliberate spacing.

Enemy AI is **state-machine driven** (same pattern as player, simpler
states): Patrol, Aggro, Attacking, Staggered, Dead. Behavior tuned via
exported parameters.

### Weapons

Target for v2 ship: **3 weapon archetypes**, leveraging existing
WeaponResource pattern:

1. **Sword** (medium reach, medium speed, medium damage) — UAL2
   Sword_Regular animations.
2. **Dagger** (short reach, fast, low damage, fast combos) — UAL2
   Sword_Light animations or custom timing.
3. **Greatsword** (long reach, slow, high damage, committed swings) —
   UAL2 Sword_Heavy animations.

Each weapon defines: reach, damage, swing duration, stamina cost,
animation set, root motion intensity.

### Enchantments and Buffs

`WeaponEnchantment` (Resource) — additive modifiers applied to a
weapon at runtime. Fields include:
- `damage_multiplier`
- `length_multiplier` (scales blade mesh + hitbox shape)
- `swing_speed_multiplier`
- `damage_type` (fire, ice, lightning — visual + future status)
- `visual_effect_scene` (optional particle/shader overlay)

Multiple enchantments stack via multiplication on numeric fields.
Visual jank from extreme modifiers (e.g., 4x length sword clipping
through floor) is **part of the design**, consistent with the
"fun and unserious" pillar.

Player stat buffs follow the same pattern: `PlayerBuff` resources
applied to the player on selection, modifying base stats
(max_health, stamina_regen, dodge_iframes, etc.).

## Run Loop (Roguelite Scope)

Minimal viable run loop for v2 ship:

1. **Arena** — one combat space. Stylized fantasy aesthetic via
   Quaternius Medieval Village + Stylized Nature MegaKits.
2. **Waves** — 3-5 waves of enemies per run, escalating in count
   and difficulty.
3. **Buff selection** — between waves, player picks one of three
   randomly offered buffs (weapon enchantment or player stat buff).
4. **Death** — full run reset. No persistent progression in v2.

Polish targets (deferred unless time allows):
- Multiple arenas
- Persistent meta-progression
- Unlockable weapons or characters
- Boss encounters

## Asset Pipeline

Documented in detail elsewhere (see asset audit, deferred). Summary:

- **Characters:** Quaternius Universal Base Characters + Modular
  Character Outfits Fantasy. All on the Humanoid Rig.
- **Animations:** UAL1 (locomotion), UAL2 (combat). Both purchased
  Source tier. Compatible with Universal Base Characters out of
  the box.
- **Environment:** Quaternius Medieval Village MegaKit, Fantasy Props
  MegaKit, Stylized Nature MegaKit. Standard (free) tier first,
  Source tier (~$15 each) for shaders and Godot project integration
  if budget allows.
- **No mixing of skeleton families.** KayKit and other CC0 character
  packs are excluded from the player + main enemy roster to avoid the
  Mixamo→Humanoid remap pain that consumed Session 15.

## Out of Scope for v2 Ship

- Online multiplayer (decision made Session 18 — too large for solo
  scope, possible far-future direction)
- Persistent meta-progression beyond the run
- Audio production (placeholder SFX acceptable)
- Cutscenes and narrative framing
- Tutorial system beyond a help overlay

## What "Done" Looks Like

v2 ships when a player can:
1. Launch the game, see a clean main menu
2. Start a run, fight 3-5 waves of enemies in one arena
3. Pick buffs between waves that change how their character feels
4. Die, reset, run again with different buff combinations
5. Feel that the movement and combat are *good* — that hits feel
   weighty, that they can recover from mistakes via dodge cancels,
   that input feels responsive

Production polish is secondary. Feel is the ship criterion.

# Full Sword V2 — Project Context

## Engine & Language
- Godot 4 (not Godot 3 — reject any Godot 3 patterns or deprecated node names)
- GDScript only, no C#
- Strict type hints on all new scripts
- All tunable values exposed as @export from the moment they are introduced

## Project Goal
A fantasy roguelite combat arena with animation-driven melee combat,
feel-first design, and a minimal run loop. Built with an agentic
AI-assisted workflow as a deliberate portfolio artifact.

See V2_ARCHITECTURE.md for full design spec.

## Architecture Constraints (non-negotiable)
- Player is CharacterBody3D with move_and_slide() — not RigidBody3D
- Ragdoll is a death-state transition only — not continuous simulation
- Gameplay state machine drives AnimationTree — never the other way around
- One scene per major game object (player, enemy archetype, weapon, arena)
- Scripts are short and single-responsibility

## Current Scope
Defined per-session in docs/sessions/SESSION_NOTES.md. When in doubt, defer.

## Out of Scope for v2 Ship
- Online multiplayer
- Persistent meta-progression
- Audio production (placeholder SFX acceptable)
- Cutscenes or narrative framing
- Tutorial system

## Conventions
- Signals for inter-node communication — avoid direct node references
- No speculative scaffolding — don't add fields, methods, or nodes that
  nothing currently uses
- Dead declaration audit once per session (grep @export/const/var for
  anything unreferenced)

## Known Engine Behavior

### .tscn sub-resource properties silently ignored at runtime

Godot's scene loader does not reliably apply sub-resource property
values from .tscn files in all cases. Confirmed occurrences:

- Session 2: AnimationTree active, transitions, and source_node
  properties stripped on Ctrl+S in editor.
- Session 4: Environment background_mode, background_color, and
  ProceduralSkyMaterial colors present on disk but rendered with
  default values at runtime. D3D12 + AMD RX 6900 XT on Godot 4.6.3.

**Convention:** When a .tscn sub-resource property does not take effect
despite being correct on disk, set it in _ready() via script. Use
@export vars so the values remain Inspector-tunable. This is the
reliable path — .tscn serialization is the fallback, not the
source of truth.

### ProceduralSkyMaterial does not render on D3D12

ProceduralSkyMaterial sky renders black on D3D12 12_0 with AMD
Radeon RX 6900 XT in Godot 4.6.3. Background mode Color (BG_COLOR)
works. Workaround: set background_mode = Environment.BG_COLOR in
_ready(). Investigate Vulkan as alternative renderer in a future
session.

## Verification
- After any change, state what to run/test in Godot and what "working" looks like
- Do not claim success — show what to look for

## When Stuck
- State the constraint clearly before proposing a workaround
- Prefer the simpler Godot-native solution over a clever custom one
- Web search after 2 failed diagnostic loops — do not attempt a third
  without new information

## Session Bootstrap
At the start of every session, read docs/sessions/SESSION_STATE.md before any other work.

### Area3D detection & collision (Session 11)
- An Area3D detects a BODY via the AREA's collision_mask vs the BODY's
  collision_layer. The area's OWN layer is irrelevant to what it detects.
  A pure detector sets collision_layer = 0, mask = the target body's layer
  (the official Godot detector pattern).
- A code-constructed/configured Area3D defaults collision_mask to 1 — NOT
  the .tscn value. If code touches the area in _ready(), set the mask
  explicitly; the .tscn value is not authoritative once code is involved.
- body_entered / area_entered are EDGE-triggered (fire once on boundary
  cross). For ongoing "is X still inside" use get_overlapping_bodies()
  (level poll). Don't make recovery logic depend solely on a past edge.
- get_overlapping_bodies() returns an UNTYPED Array — declare
  `var bodies: Array = ...`, not `:=` (strict-typing inference fails).
- Shared state needs ONE owner. A reference written by multiple concerns
  (e.g. detection + stagger both touching a player ref) produces
  order-dependent bugs. One writer; other states stay neutral.

### Navigation (Session 11)
- Bake from STATIC COLLIDERS, not visual meshes
  (PARSED_GEOMETRY_STATIC_COLLIDERS + geometry_collision_mask = floor
  layer). Visual-mesh baking stalls rendering (GPU→CPU transfer).
- navmesh cell_size MUST match the navigation map's cell_size (map default
  0.25). Mismatch risks edge rasterization errors. Change both together or
  neither.
- The nav map is NOT queryable until the physics frame AFTER bake — even
  with a synchronous bake. Instanced agents must guard
  (map_get_iteration_id == 0 → bail that frame); do NOT cache nav state at
  _ready(). Same spawn-order discipline as lazy node references.
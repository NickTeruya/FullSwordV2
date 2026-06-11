# Animation Pipeline — Full Sword V2

How animations and characters are wired so that assets are plug-and-play.
This is foundational infrastructure intended to port forward to v3 and
beyond. Read this before touching any animation or skeleton work.

Status: Adopted Session 5. Supersedes the Session 2 pose-copy workaround.

---

## The Core Principle

**One skeleton at runtime. Animations are data loaded onto it, not a
second character instanced beside it.**

Every Full Sword character and every animation source lives on the
Quaternius Universal Base Characters Humanoid rig, mapped to Godot's
SkeletonProfileHumanoid via a BoneMap. Because every asset shares that
profile, any animation retargets onto any character with zero per-asset
glue code. That shared profile is the entire reason the pipeline is
plug-and-play -- protect it.

This is the native Godot 4 retargeting workflow, not a custom system.
We are using the engine the way its retargeting was designed to be used.

---

## What Changed and Why (Session 2 workaround -> Session 5 migration)

Sessions 2-4 ran a workaround: UAL1.glb was instanced into the player
scene as a second, hidden character. Its GeneralSkeleton was animated by
direct AnimationPlayer.play() calls, and a _copy_pose() function copied
bone transforms from UAL1 onto the Superhero skeleton every
_physics_process frame.

That worked for binary Idle/Walk switching but had a hard ceiling:

- AnimationTree silently failed because its tracks could not resolve
  across the instanced-scene boundary to a foreign skeleton.
- No root motion (an AnimationTree feature -- V2_ARCHITECTURE depends
  on it for committed attacks).
- No blend spaces for directional locomotion.
- A per-frame pose copy running forever as baseline cost.

Root cause: two skeletons in the tree. The fix is to have one.

The correct Godot workflow imports animation .glb files as Animation
Libraries (mesh and skeleton stripped, clips retargeted to the Humanoid
profile) and loads those libraries onto the single AnimationPlayer that
belongs to the actual character skeleton. AnimationTree then points at
that one player and everything -- state machine, blending, root motion
-- works natively.

---

## Import Rules (non-negotiable, per asset type)

### Character meshes (the model you actually see)
- Import As: Scene
- Assign BoneMap + SkeletonProfileHumanoid in Advanced Import Settings.
- This is the only skeleton that exists at runtime.
- Examples: Superhero_Male_FullBody, Modular Outfit pieces.

### Animation sources (UAL1, UAL2, any future pack)
- Import As: Animation Library -- NOT Scene.
- Assign the same BoneMap + SkeletonProfileHumanoid.
- Result: a library of retargeted clips, no mesh, no skeleton.
- The library is loaded onto the character AnimationPlayer in _ready().

### Static props (weapons)
- Import As: Scene, no skeleton, no BoneMap.
- Attached via BoneAttachment3D to a hand bone. Unrelated to this
  pipeline -- listed here so the contrast is explicit.

If an asset is ever imported under the wrong mode, nothing downstream
works correctly. The import mode is the load-bearing decision.

---

## Named Library Convention (established Session 5)

Load each animation pack under a named key, not the default empty
namespace. Address clips as library/ClipName.

    var ual1_lib: AnimationLibrary = load("res://assets/animations/UAL1.glb")
    var ual2_lib: AnimationLibrary = load("res://assets/animations/UAL2.glb")
    _anim.add_animation_library("ual1", ual1_lib)
    _anim.add_animation_library("ual2", ual2_lib)
    # Clips addressed as: ual1/Idle, ual1/Walk, ual2/Sword_Regular_A, etc.

Why named over merged namespace: prevents clip-name collisions when
adding future packs. The merged (empty-key) namespace fails silently
when two packs share a clip name -- the second shadows the first with
no error. Named libraries make the source explicit at every call site
and make collisions impossible by construction. AnimationTree state
machine nodes use the same namespacing.

---

## Runtime Scene Structure

    Player (CharacterBody3D)
    +-- CollisionShape3D
    +-- CameraPivot (Node3D)
    |   +-- CameraArm (SpringArm3D)
    |       +-- Camera3D
    +-- MeshPivot (Node3D)
    |   +-- Superhero_Male_FullBody (instanced .gltf)
    |       +-- Armature (Node3D)
    |           +-- GeneralSkeleton (Skeleton3D)  <-- THE skeleton, only one
    |               +-- (mesh MeshInstance3D nodes)
    +-- CharacterAnimPlayer (AnimationPlayer)      <-- at Player level, not
    |                                                  inside mesh instance
    +-- AnimTree (AnimationTree)

Key design decisions baked into this structure:

CharacterAnimPlayer is a child of Player, not inside the Superhero
instance. This makes the animation rig character-agnostic: swapping the
character mesh does not require rebuilding the AnimationPlayer, its
libraries, or the AnimationTree wiring. The rig belongs to the player,
not to a specific mesh.

root_node is set in _ready() to the Superhero instance so that
percent-sign GeneralSkeleton unique-name tracks resolve correctly. The
retargeted library clips use the percent-sign unique-name form for bone
tracks, which requires root_node to point at the node whose scene owns
that unique name.

    _anim.root_node = _anim.get_path_to($MeshPivot/Superhero_Male_FullBody)

What is gone versus the Session 2-4 workaround:
- No UAL1.glb instance in the scene tree.
- No second skeleton.
- No _copy_pose() in _physics_process.

---

## AnimationTree Conventions

Set ALL AnimationTree runtime state in _ready(), NEVER in the .tscn.
Godot strips AnimationTree sub-resource state on editor Ctrl+S. This
destroyed session 2 work and is documented in CLAUDE.md. The node in
.tscn is bare; the state machine is built entirely in code.

    _anim_tree = $AnimTree
    _anim_tree.anim_player = _anim_tree.get_path_to(_anim)
    var sm := AnimationNodeStateMachine.new()
    # ... build nodes and transitions ...
    _anim_tree.tree_root = sm
    _anim_tree.active = true
    _state_machine = _anim_tree.get("parameters/playback")
    _state_machine.start("Idle")

The gameplay state machine drives AnimationTree parameters. The
AnimationTree drives the visuals. Never the reverse (V2_ARCHITECTURE).

---

## Transition Mechanism: travel() vs Auto-Advance

**Default rule: code-driven travel() via ADVANCE_MODE_ENABLED.**

ADVANCE_MODE_ENABLED means the transition is only usable by travel() --
it never fires on its own. ADVANCE_MODE_DISABLED means the transition
does not exist as far as travel() is concerned -- pathfinding skips it
entirely. ADVANCE_MODE_AUTO fires every frame when its condition is true.

The three modes in plain terms:
- ENABLED: travel()-only. Use for all reactive, code-driven transitions.
- DISABLED: unusable. Do not use -- set ENABLED and gate in code instead.
- AUTO: self-firing. Use only for one-shot-returns-to-neutral (see below).

    var node := _state_machine.get_current_node()
    if node != "Walk":
        _state_machine.travel("Walk")

**Auto-advance (ADVANCE_MODE_AUTO) is permitted only for two categories:**

1. One-shot committed flows where the animation finishing IS the
   transition -- not a reaction to input:
   - Jump_Start -> Jump: auto-advance so Jump_Start plays to natural
     completion before entering the fall loop.
   - Jump_Land -> Idle: uninterrupted landing settles to neutral.

2. Committed attack swings flowing into their recovery clips:
   - Attack_A -> Attack_A_Rec, Attack_B -> Attack_B_Rec: the swing is
     a committed one-shot; recovery always follows. Use SWITCH_MODE_AT_END
     so the swing plays fully before the recovery begins. SWITCH_MODE_AUTO
     (immediate) fires on entry and truncates the swing.

Attack _Rec clips are NOT one-shot returns to neutral -- they are
decision points (chain or settle). Their exits are code-driven ENABLED
transitions, not AUTO. See cancel-window pattern below.

Auto-advance is NOT used for: locomotion changes, attack entry, cancel
windows, dodge, or any _Rec exits. Those are always travel().

**CRITICAL -- transition topology and travel() pathfinding:**

travel() uses A* to find the shortest path of ENABLED transitions from
the current node to the target. It plays every intermediate node on the
path. If the only ENABLED route from Walk to Idle passes through
Attack_A, travel("Idle") will play the full attack animation.

Rules that prevent phantom transitions:
- Every node must have a direct ENABLED path to every node it legitimately
  needs to reach without passing through unrelated states.
- DISABLED transitions are invisible to pathfinding -- they cannot cause
  phantom paths, but they also cannot be used for travel(). Never use
  DISABLED as a "dormant but available" state; use ENABLED.
- When building a new subgraph (attack states, dodge states, etc.),
  immediately add direct ENABLED exits back to all locomotion states.
  Omitting these exits forces travel() to route through the subgraph.

---

## travel() Frame-Ordering Idiom (established Session 5)

travel() requests are queued and resolved by the AnimationTree on its
own update pass, not synchronously within the calling function. Within
a single frame, last travel() wins.

This means: if two travel() calls fire in the same frame (e.g.
_process_airborne sets travel("Jump_Land") and then _update_animation
_conditions sets travel("Walk")), the second overwrites the first before
the tree acts on either.

Guard travel() calls with get_current_node() checks against the states
where the travel is valid:

    var node := _state_machine.get_current_node()
    if node == "Walk" or node == "Sprint":
        _state_machine.travel("Idle")
    # On Jump_Land: do nothing -- let AUTO handle it

This pattern applies to all future combat cancel windows. A cancel
window travel() is only valid from specific states; guard accordingly.

---

## Cancellable Landing (Session 5 pattern)

When landing while moving, Jump_Land is immediately overwritten by the
Walk/Sprint travel in the GROUNDED branch (same-frame last-travel-wins).
Fix: a protect window suppresses Walk/Sprint travel for
landing_protect_window seconds after touchdown. Animation-only -- no
movement lockout.

    var in_landing_protect := _landing_started_ms >= 0 and \
        (Time.get_ticks_msec() - _landing_started_ms) < int(landing_protect_window * 1000.0)

landing_protect_window is an @export read live each frame (not baked at
_ready()), so Inspector edits apply without an F5 rebuild.

---

## Feel Parameters and Tuning Loop

All transition xfade times are exposed as @export grouped by category.
Tuned values as of Session 5:

    @export var locomotion_xfade: float = 0.25      # Idle/Walk/Sprint cross-blends
    @export var jump_entry_xfade: float = 0.15      # ground state -> Jump_Start
    @export var jump_chain_xfade: float = 0.25      # Jump_Start->Jump, Jump->Jump_Land
    @export var landing_cancel_xfade: float = 0.15  # Jump_Land -> Walk/Sprint/Jump_Start
    @export var landing_settle_xfade: float = 0.15  # Jump_Land -> Idle (AUTO)
    @export var landing_protect_window: float = 0.12

xfade values are baked into transition objects at _ready() -- Inspector
edits require an F5 to apply. landing_protect_window is read live each
frame and takes effect immediately without a rebuild.

Tuning loop: edit value in editor Inspector on Player node -> F5 -> feel
-> repeat. A live-rebuild hook (so xfade edits apply without F5) is
deferred until combat tuning makes the F5 loop painful.

---

## Future: Swappable Character Models

The CharacterAnimPlayer-at-Player-level placement was chosen explicitly
to enable this. To swap character models:

1. Replace the mesh instance under MeshPivot.
2. Re-point _anim.root_node to the new instance in _ready().
3. All animation libraries, the AnimationTree, and state machine wiring
   stay put -- they belong to Player, not to any specific mesh.

This works because every character is on SkeletonProfileHumanoid
(the skeleton-family rule in ASSET_AUDIT.md). The retargeted clips
resolve onto any compatible skeleton identically.

A proper character-slot system (the mesh as a swappable reference, path
resolved dynamically) is deferred. The current direct path is swap-ready
by architecture; the slot system layers on top when needed.

---

## Future: Swappable Skins

Swappable skins (Modular Outfit pieces) are a separate axis from
character-model swapping. Skins attach to the skeleton by binding to
GeneralSkeleton's bone names. The Skin.set_bind_name() remap procedure
for Mixamo-named outfits is documented in docs/skin_remap_design.md.

As long as every character uses SkeletonProfileHumanoid, any skin binds
to any character. The skeleton contract enables both swap features
independently.

---

## Root Motion (the combat payoff)

With AnimationTree owning a real single-skeleton player, committed
attacks use root motion natively. The character physically moves through
the strike -- the Sandfire feel reference.

### Setup (required, in _ready() before active = true)

    _anim_tree.root_motion_track = NodePath("%GeneralSkeleton:Root")

Track path notes:
- Capital R on "Root" -- the BoneMap maps the source rig's "root" bone
  to the profile slot named "Root". Retargeted tracks use the profile
  name. Case-sensitive: "root" returns zero every frame silently.
- The BoneMap Root slot (the circle at the bottom-center of the profile
  silhouette in Advanced Import Settings) must be populated. It is NOT
  auto-mapped by the green-track check -- the green-check passes without
  it. Verify manually: Root slot shows "root" in the bone picker.
  If empty, root motion extraction returns (0, 0, 0) with no error.
- Set on the AnimationTree, not the AnimationPlayer. AnimationTree
  extends AnimationMixer and syncs root_node from the assigned
  anim_player -- do not set root_node separately on the tree.

### Extraction and application (in _process_attacking())

    var rm: Vector3 = _anim_tree.get_root_motion_position()
    var rm_world: Vector3 = _mesh_pivot.global_transform.basis * rm * root_motion_scale
    velocity.x = rm_world.x / delta
    velocity.z = rm_world.z / delta
    # Do NOT touch velocity.y -- gravity code owns it

Key points:
- get_root_motion_position() returns a per-frame delta in animation-local
  space, not velocity. Divide by delta for move_and_slide() compatibility.
- Rotate by _mesh_pivot.global_transform.basis to convert animation-local
  forward into world-space facing direction. Without this rotation, every
  attack lunges in a fixed world direction regardless of character facing.
- Apply x/z only. Gravity owns y; attacks off ledges fall correctly.
- root_motion_scale is an @export float (default 1.0) applied before
  division. Read live each frame -- Inspector edits take effect
  immediately without F5. 1.0 is the animator's intent; tune from there.
- When root_motion_track is set, the engine strips the root translation
  from the visual mesh AND returns it from get_root_motion_position().
  If extraction is misconfigured (wrong track path, empty BoneMap Root
  slot), the translation leaks through visually as a slide-and-snap
  with (0, 0, 0) returned from the extraction call.

### Confirmed working (Session 6)
- UAL2 Sword_Regular_A/B/C all carry root motion on %GeneralSkeleton:Root
- CharacterBody3D advances through attacks; camera follows
- Character falls off ledges mid-combo as expected

---

## Adding a New Animation Pack (the plug-and-play test)

1. Drop the .glb in assets/animations/.
2. Import As: Animation Library, assign BoneMap + SkeletonProfileHumanoid.
3. Load in _ready() under a named key:
       var pack_lib: AnimationLibrary = load("res://assets/animations/NewPack.glb")
       _anim.add_animation_library("pack", pack_lib)
4. Reference clips as pack/ClipName from AnimationTree state machine.

No new skeleton, no pose copy, no per-asset glue code. If a future pack
does NOT retarget cleanly to SkeletonProfileHumanoid, it does not enter
the project. Compatibility is enforced at the asset-acquisition gate.

---

## Holding a One-Shot's Mid-Clip Pose (Freeze-Frame Hold)

A reusable pattern for holding a stance from a clip that wasn't authored
as a sustained loop. Established Session 7 for the block guard pose;
applies to any "play into a pose, then hold it" need (block, charge-up,
ready-stance, aim-hold).

### The problem

Some clips are authored as a full motion -- raise into a pose, hold
briefly, then return to neutral -- not as a sustainable loop. Sword_Block
is exactly this: a 1.23s clip that raises into a guard at ~0.5s then
reverts toward idle. Neither loop mode works:
- LOOP_NONE: plays once, then the pose sags back to idle (the final
  frame IS near-idle, since the clip returns).
- LOOP_LINEAR: replays the whole raise-and-return on a cycle -- the
  character visibly re-guards every clip length.

The held pose you want is in the MIDDLE of the clip (the peak), not at
either end.

### The solution: synthetic single-key freeze frame + two-node hold

Build a synthetic Animation at runtime that holds exactly one pose --
the clip sampled at its peak. A single-key track has nothing to advance
toward, so it holds that pose indefinitely with zero loop seam.

Then split the stance into two AnimationTree state machine nodes:
- Enter node: plays the source clip (LOOP_NONE).
- Hold node: plays the synthetic single-key freeze.

Advance Enter -> Hold via code-driven travel() when play position
reaches the peak timestamp -- NOT via SWITCH_MODE_AT_END.

Why not AT_END: SWITCH_MODE_AT_END waits for the source clip to play to
its full end (1.23s) before switching. But the guard pose peaks at
~0.50s and the clip then reverts toward idle through its remaining
runtime. With AT_END, Block_Enter would play the full clip -- raise,
peak, AND the return-to-idle -- before the transition fired, so the
player would see the guard raise then lower, then snap back up when the
frozen Hold pose (locked at 0.50) kicked in. We must switch AT the peak,
not at clip end. A code-driven travel() guarded on
get_current_play_position() >= block_peak_time does exactly this.

Secondary reason this is the right call: AUTO advance mode (which pairs
with AT_END for one-shots) is documented as unreliable during travel()
-- and this project's entire state machine is travel()-driven (Session
6). A code-driven peak-advance is consistent with that topology; an
AUTO/AT_END transition would fight it.

Because the freeze is sampled at the same timestamp the live clip is at
when we transition, the Enter -> Hold blend is between two identical
poses -- visually seamless.

### Finding the peak timestamp

Do not eyeball the editor scrubber (no numeric readout, imprecise).
Sample the most-moving upper-body bone's rotation at fine intervals
across the candidate window and compute per-interval delta magnitude.
The flattest interval (minimum delta) is the most stable pose -- the
best freeze point, because residual motion there would cause drift.
For Sword_Block this was t=0.50 (RightHand fully static 0.50-0.55,
RightLowerArm at minimum delta). Sampling logic is throwaway debug --
run once, read the result, remove it.

### The freeze-frame helper

A helper duplicates a source Animation's pose at a sample time into a
single-key Animation, iterating tracks and using
position/rotation/scale_track_interpolate() to sample each, inserting
one key at t=0. Register the result into the animation library under a
"_Hold" name, then reference it from the Hold node. See
_make_freeze_frame_animation() in player.gd for the implementation. It
handles TYPE_POSITION_3D / ROTATION_3D / SCALE_3D explicitly and warns
on any fallback track type (none hit for Sword_Block's 60 tracks).

### Why this is foundation-grade

Works identically whether you have one clip you're splitting or two
separate enter/hold clips from an asset pack later. The structure
doesn't change -- only the clip source does. When a future asset ships
dedicated guard-enter and guard-hold clips, drop them into the same
two-node Enter/Hold topology and delete the synthetic freeze. The state
machine wiring, the code-driven peak-advance, and the release exits all
stay.

---

## Known Risks and Watch-Fors

- Destructive save on AnimationTree: set ALL runtime state in _ready().
  Never set tree_root, active, or parameters in the .tscn. This is the
  same bug that ended Session 2.
- BoneMap drift: if a future Quaternius pack updates its rig, the BoneMap
  may need re-confirming. The green-track check in Advanced Import
  Settings is the canary.
- Scene Tab Collision Protocol applies to every .tscn edit (AGENTIC_FLOW
  .md). Close the scene tab before any Claude Code .tscn text edit.
- xfade values are baked at _ready(): Inspector edits require F5. Do not
  confuse with landing_protect_window which IS live-readable.
- percent-sign GeneralSkeleton track resolution requires root_node to
  point at the Superhero instance root. If root_node is wrong or unset,
  the result is a T-pose with no error thrown. Confirmed working in
  Session 5 through the editable-instance boundary.
- BoneMap Root slot is not verified by the green-track check: the auto-
  mapper leaves it empty and the green canary still passes. Verify the
  Root slot (bottom-center of profile silhouette) manually for every
  animation asset. Empty Root slot = get_root_motion_position() returns
  (0, 0, 0) silently with no error.
- ADVANCE_MODE_DISABLED makes transitions invisible to travel()
  pathfinding -- they cannot be traveled and cannot cause phantom paths.
  ADVANCE_MODE_ENABLED is the correct mode for code-driven transitions.
  Never use DISABLED as "dormant but available."
- Transition topology creates phantom travel() paths: if the only ENABLED
  route between two locomotion states passes through attack states,
  travel() plays the full attack animation silently. Ensure every node
  has a direct ENABLED path to all legitimate targets. Symptoms: attack
  animation plays with no input, usually on stop or on spawn.
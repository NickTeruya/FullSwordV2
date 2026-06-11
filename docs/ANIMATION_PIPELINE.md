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

**Default rule: code-driven travel() via ADVANCE_MODE_DISABLED.**

The gameplay state machine calls travel() when it decides a state should
change. The tree executes the blended transition. The decision stays in
gameplay code; the tree is the visual blend layer.

    var node := _state_machine.get_current_node()
    if node != "Walk":
        _state_machine.travel("Walk")

**Auto-advance (ADVANCE_MODE_AUTO) is permitted only for one-shot
returns to neutral**, where the animation finishing IS the state
transition -- not a reaction to input. Current uses:

- Jump_Start -> Jump: Jump_Start is a committed launch that always leads
  to the fall loop. Code-driving this on the apex check caused a snap
  because the check fired before Jump_Start visually played (no pose to
  blend from). Auto-advance lets Jump_Start play to natural completion.
- Jump_Land -> Idle: uninterrupted landing settles to neutral on its own.
  Player input via travel() overrides it if present.

Auto-advance is NOT used for reactive transitions (locomotion changes,
attack entry, cancel windows, dodge). Those are always travel().

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
attacks use root motion natively:

- Set the AnimationTree root motion track to the skeleton's root bone.
- Read AnimationTree.get_root_motion_position() each frame during an
  attack state and feed it into CharacterBody3D velocity before
  move_and_slide().

This is what makes heavy swings lean into the strike (the Sandfire feel
reference). It was impossible under the pose-copy workaround. It is
available now. Root motion is the primary reason the pipeline migration
was the right Session 5 investment before building combat.

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

## Session 19 — V2 Repo Setup and Planning

**Outcome:** V2 repo live at github.com/NickTeruya/FullSwordV2. Foundational
workflow docs committed. Asset inventory complete. Session 1 plan defined.

### What Was Done

**Repo created**
- github.com/NickTeruya/FullSwordV2 — public from day one
- Rationale: open dev process is the portfolio signal. v2 may become v3;
  the commit history of a reasoned pivot is itself portfolio value.
- No license added — all rights reserved by default. Revisit if Steam
  becomes a concrete goal.

**Foundational docs committed**
- CLAUDE.md — engine constraints, architecture guardrails (CharacterBody3D
  not RigidBody3D, ragdoll as death state only, gameplay state machine
  drives AnimationTree), conventions, no speculative scaffolding rule
- AGENTIC_FLOW.md — full workflow doc refined from v1. Dropped Session 6
  narrative (lessons distilled into conventions). Added parallel agent
  lanes. MCP capabilities stub with audit required at Session 1.
- docs/ASSET_AUDIT.md — full inventory of owned assets, retarget status,
  Session 1 asset checklist, weapons section

**Assets acquired and staged**
- Quaternius LowPoly Medieval Weapons downloaded (CC0, free) — 22 weapons
  in FBX/OBJ/Blend, static meshes, no retarget required
- Asset folder structure established: assets/characters/, assets/animations/,
  assets/weapons/, assets/textures/polyhaven/
- Decision: UAL1_Standard.glb kept as fallback reference only.
  UAL1.glb is v2 canonical locomotion source.

**Key decisions made**
- UAL1_Standard.glb dropped as primary source — UAL1.glb Source tier only,
  retarget configuration required at Session 1
- Modular Outfits Fantasy Source tier NOT purchased — Standard tier glTF
  bind name audit deferred to Session 1 (may already be Humanoid names
  in updated version; 2-minute check before deciding)
- Environment MegaKits deferred until combat loop works in gray box
- Weapon meshes: Quaternius LowPoly Medieval Weapons (CC0) — stays inside
  Quaternius visual family, static mesh attached via BoneAttachment3D

### Session 1 Milestone Definition

**Session 1 complete = CharacterBody3D player moves with WASD in an empty
scene, driven by UAL1 locomotion animations via AnimationTree.**

Specifically:
- Godot project created at repo root, Jolt physics enabled, collision
  layers named, .gitignore in place
- start-session.ps1 and fullsword PowerShell profile function created
  for v2 project path
- Claude.ai project created with v2 knowledge files uploaded
- UAL1.glb retarget configured in Advanced Import Settings
- UAL2.glb retarget audited (configure if missing)
- Modular Outfit glTF bind names checked (remap if still Mixamo)
- CharacterBody3D with capsule collision
- WASD movement and mouse camera via move_and_slide()
- AnimationTree with embedded StateMachine driving Idle and Walk minimum
- F5 runs, character moves, animation plays, no console errors

Pre-flight asset work (UAL retarget + outfit audit) budgeted at 1-2 hours.
Movement milestone is the second half of Session 1.

### What's Deferred

- start-session.ps1 for v2 — to be created as first task of Session 1
- Claude.ai project creation — to be done at start of Session 1
- First milestone (CharacterBody3D + AnimationTree locomotion) — Session 1
- Environment MegaKit purchases — after combat loop works
- Modular Outfits Source tier decision — after bind name audit at Session 1

## Session 1 — Godot Project Setup and WASD Movement

**Outcome:** Godot project live at repo root. All assets pre-flighted.
WASD movement and mouse look working. F5 runs, no console errors.

### What Was Done

**Pre-flight completed**
- start-session.ps1 created from v1 copy, updated for FullSwordV2
- Godot project created at repo root (full-sword-v-2 subfolder issue
  resolved — contents moved to root)
- Jolt Physics enabled, collision layers named (world/player/enemy/
  hitboxes/hurtboxes)
- .gitignore in place
- MCP audit complete: 14 tools, documented in docs/AGENTIC_FLOW.md
- UAL1.glb, UAL2.glb — retarget pre-configured, GeneralSkeleton
- Modular Outfits (Male_Ranger) — BoneMap configured, GeneralSkeleton
- Universal Base Characters — re-downloaded (missing .bin fixed),
  BoneMap configured, GeneralSkeleton
- Blender import disabled (not needed for v2)

**Session 1 milestone**
- scenes/player.tscn — CharacterBody3D with CapsuleShape3D collision,
  SpringArm3D camera rig
- scripts/player.gd — WASD movement via move_and_slide(), mouse look
  with pitch clamp, gravity
- scenes/arena.tscn — floor StaticBody3D with BoxMesh, Player instanced
- WASD input actions added to project.godot
- F5 runs, WASD moves, mouse look works, zero console errors

### Issues Encountered
- Godot project created in full-sword-v-2 subfolder instead of repo
  root — resolved by moving contents up
- Universal Base Characters missing .bin files — re-downloaded from
  quaternius.itch.io
- jump_velocity dead declaration caught and removed before commit
- CameraArm pitch clamp Vector3 copy issue caught and fixed
- Type inference failure on := with node path — fixed with explicit
  Vector3 type annotation

### What's Deferred
- AnimationTree with UAL1 locomotion animations — Session 2
- Player visible mesh (character model) — Session 2
- Fall-off-floor recovery / arena walls — deferred
- T_Eye_Normal_png.png missing texture warning — low priority, defer

### Key Decisions
- AnimationTree deferred to Session 2: original Session 1 definition
  included UAL1 locomotion animations as a completion criterion.
  Movement mechanics verified working first; AnimationTree adds
  visual polish on top of a confirmed-working foundation. Deliberate
  descope, not an oversight.

## Session 2 -- Animation Pipeline Working (AnimationTree Deferred)

**Outcome:** Superhero_Male_FullBody mesh animates with Idle/Walk via WASD.
AnimationTree route abandoned mid-session; replaced with direct AnimationPlayer
calls plus a per-frame script-based pose copy from UAL1 skeleton to Superhero
skeleton. Session 2 goal met by a different path than planned.

### What Was Done

**UAL1 retarget configured.** SkeletonProfileHumanoid populated in Advanced
Import Settings on UAL1.glb. All bones mapped green. Superhero_Male_FullBody
was already configured from pre-flight.

**Scene composition:**
- Superhero_Male_FullBody.gltf instanced as child of Player (mesh source)
- UAL1.glb instanced as child of Player, visible = false (animation source)
- AnimationTree node added but not active
- No RetargetModifier3D -- removed after the architecture proved
  incompatible with our scene structure

**Pose copy script.** _copy_pose() in player.gd iterates all bones of UAL1's
GeneralSkeleton and writes position/rotation/scale onto Superhero's
GeneralSkeleton each _physics_process. Works because both skeletons share
the Quaternius Humanoid bone order and count.

**Animation switching.** Direct AnimationPlayer.play() calls from
_update_animation_conditions() switch between Idle and Walk based on
velocity.length() vs walk_threshold (0.1).

### Key Findings

**RetargetModifier3D requires parenting.** Per the Godot 4.6 PR that added
this node (TokageItLab #97824), the target (child) skeleton must be a child
of RetargetModifier3D in the scene tree to guarantee process order. Our
Superhero skeleton is inside an instanced subscene -- not reparentable
without major restructuring. Script-based pose copy is the workaround.

**AnimationTree silently fails when wired across instanced scenes.**
Setting AnimationTree.root_node to the UAL1 instance did not fix track
resolution. AnimationPlayer.play() directly on UAL1's AnimationPlayer
works perfectly. AnimationTree integration deferred to a future session
when blend trees become necessary (Sprint, directional Jog, attacks).

**Godot save behavior is destructive on AnimationTree state.** Multiple
edits to player.tscn had transitions, active=true, and source_node
properties stripped on Ctrl+S in editor. Script-set properties survive.
Lesson: set AnimationTree runtime properties in _ready() rather than .tscn
when reliability matters.

**Output panel rendering can glitch.** print() output didn't display
multiple times during this session despite messages being emitted. File
output via FileAccess to res://tmp/ was the reliable debug channel.

### Deferred to Future Sessions

- AnimationTree with blend trees for directional locomotion (Jog_Fwd_L/R,
  Sprint blend, etc.)
- Root motion extraction for committed attacks (V2_ARCHITECTURE pillar)
- Combat state machine layer (Light/Heavy/Dodge from V2_ARCHITECTURE)
- AnimationPlayer is a placeholder solution -- AnimationTree will be
  required once we move beyond binary state switching

### Process Notes

- Two failed loops on RetargetModifier3D triggered the planned web search.
  Search found the parenting requirement, leading to the script-based
  pivot. Working as designed.
- Session 2 was longer than expected (estimated single milestone, took a
  significantly larger arc). Root cause: AnimationTree wiring assumed
  knowledge from v1 that didn't transfer cleanly to a two-skeleton
  source/target setup. Acceptable cost given foundational understanding
  gained.
- MCP capability audit deferred -- never blocked progress this session.
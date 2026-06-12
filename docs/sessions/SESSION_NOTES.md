
## Session 19 (of V1) — V2 Repo Setup and Planning

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

## Session 3 -- State Machine, Camera System, Combat Foundation

**Outcome:** Inner-layer state machine (Grounded/Attacking) working.
Third-person camera with independent orbit. Light attack, sprint, jump,
and arena lighting all functional. Character grounded on floor, mesh
rotates to face movement direction.

### What Was Done

**State machine (Grounded/Attacking)**
- enum State dispatched via match in _physics_process
- Light attack on left click enters ATTACKING, zeros velocity, plays
  Sword_Attack from UAL1, returns to GROUNDED on animation_finished
- Pattern validated with sprint (Shift) as second Grounded behavior

**Camera system (Sandfire-style)**
- CameraPivot (Node3D) at chest height handles yaw independently
- SpringArm3D child handles pitch with clamp
- MeshPivot (Node3D) holds Superhero and UAL1 instances, rotates via
  lerp_angle to face movement direction
- Movement direction calculated from CameraPivot basis, not Player
- Player CharacterBody3D never rotates -- only MeshPivot does
- First attempt rotated Player directly, causing camera drift on turn.
  Fixed by adding MeshPivot separation.

**Grounding fix**
- CollisionShape3D moved to Y=1.0 local so capsule bottom aligns
  with Player origin. Character feet now on floor.

**Character facing fix**
- Quaternius mesh exports facing +Z (toward camera). Initially fixed
  with 180-degree Y rotation on mesh instances. Replaced by MeshPivot
  rotation system which handles facing dynamically.

**Sprint**
- Shift + direction uses sprint_speed (8.0 vs 5.0)
- Sprint animation switches in, drops back to Walk/Idle on release
- sprint_fov_change dead declaration caught and removed same session

**Jump**
- Space triggers velocity.y impulse when is_on_floor()
- No Airborne state yet -- gravity handles descent
- Floaty feel noted -- needs tuning next session

**Arena lighting**
- DirectionalLight3D with shadow (45-degree sun angle)
- WorldEnvironment with procedural sky, ACES tonemap, sky ambient

### Issues to Address Next Session

- Jump is floaty -- needs gravity multiplier tuning and/or fall speed
- Jump needs Airborne state in state machine (per V2_ARCHITECTURE)
- Jump animation not wired -- currently stays in Walk/Idle while airborne
- Camera distance and angle may need tuning once more gameplay is visible

### Key Decisions

- MeshPivot pattern chosen over rotating Player directly. Camera must
  orbit independently of character facing -- standard third-person
  action camera requirement. Rotating Player caused camera drift.
- Sword_Attack from UAL1 used as placeholder. UAL2 combat animations
  (Sword_Regular_A/B/C etc.) to be wired in a future session.
- AnimationTree still inactive -- direct AnimationPlayer.play() calls
  continue to work for current state count. AnimationTree becomes
  necessary when blend trees are needed (directional locomotion,
  attack combos).

### Deferred

- Airborne state (jump/fall) with animation
- Jump feel tuning (gravity multiplier, fall speed)
- UAL2 combat animations
- AnimationTree crossfade
- Dodge state with i-frames
- HitArea3D/HurtArea3D wiring

## Session 5 -- Animation Pipeline Migration and Locomotion Through AnimationTree

**Outcome:** Full migration from two-skeleton pose-copy workaround to native
single-skeleton AnimationLibrary pipeline. AnimationTree live with all locomotion
states (Idle/Walk/Sprint/Jump subgraph) driven by code-via travel(). Character
animates with tuned feel. Combat animations ready but not yet wired.

### What Was Done

**Animation pipeline migrated (the foundational work)**
- UAL1.glb and UAL2.glb reimported as Animation Library (was: Scene). BoneMap
  and SkeletonProfileHumanoid retarget survived the mode switch on both.
- UAL1 instance removed from player.tscn. _copy_pose() deleted from player.gd.
  _src_skeleton binding removed. The two-skeleton workaround is fully gone.
- New AnimationPlayer named CharacterAnimPlayer added as direct child of Player
  (sibling of MeshPivot -- character-agnostic placement, enables future
  swappable character models and skins).
- Both libraries loaded in _ready() under named namespaces: "ual1" and "ual2".
  Clips addressed as ual1/Idle, ual2/Sword_Regular_A, etc. Named libraries
  chosen over merged namespace to prevent future clip-name collisions when
  adding packs.
- root_node set in _ready() to the Superhero instance so percent-sign
  GeneralSkeleton unique-name tracks resolve. Proved empirically via probe
  script before implementation.

**AnimationTree live**
- AnimTree node added bare to player.tscn; all runtime state (tree_root,
  anim_player, active, state machine build) set in _ready() per the
  destructive-save rule (CLAUDE.md known behavior).
- AnimationNodeStateMachine built entirely in code. States: Idle, Walk, Sprint,
  Jump_Start, Jump, Jump_Land.
- Transition mechanism: travel() called from gameplay code (ADVANCE_MODE_DISABLED
  on all transitions except the two noted below). Gameplay drives the tree;
  tree never drives state. This is the pattern for all future states including
  combat.
- Auto-advance exceptions (legitimate uses only):
    Jump_Start->Jump: auto-advance so Jump_Start plays to natural completion
    before flowing to the fall loop (code-driven apex check caused pre-play snap).
    Jump_Land->Idle: auto-advance so uninterrupted landing settles to neutral.
- Cancellable landing implemented: land while moving plays Jump_Land for a
  protect window before move-cancel is allowed. Animation-only -- movement
  never interrupted. landing_protect_window = 0.12 (tunable live via @export
  since it is read each frame, not baked at _ready()).

**Feel tuning**
- All transition xfade times exposed as @export grouped by category:
  locomotion_xfade, jump_entry_xfade, jump_chain_xfade, landing_cancel_xfade,
  landing_settle_xfade. Defaults all 0.15. xfade values baked at _ready() --
  require F5 to apply after Inspector edit.
- Tuned values that felt good: locomotion_xfade = 0.25, jump_chain_xfade = 0.25,
  landing_protect_window = 0.12.
- Walk/Sprint shoulder snap: locomotion_xfade 0.15->0.25 fixed it.
- Jump apex snap: raising jump_chain_xfade had no effect (blend time was not the
  cause). Fix was switching Jump_Start->Jump to auto-advance -- the code-driven
  apex check fired before Jump_Start visually played, so there was no pose to
  blend from. Timing was the cause, not blend length.
- Landing while moving snap: landing_protect_window suppresses Walk/Sprint travel
  for 0.12s after touchdown. Jump_Land now reads on moving landings. Arms no
  longer snap from fall pose to run pose.

**New conventions established this session**
- travel() frame-ordering idiom: last travel() in a frame wins. Guard travel
  calls with get_current_node() checks against states where the travel is valid.
  This pattern applies to all future combat cancel windows.
- Auto-advance is permitted only for one-shot-returns-to-neutral (animation
  finishing IS the transition). All reactive transitions are code-driven travel().
- AnimationPlayer lives at Player level, not inside the character mesh instance.
  This makes the rig character-agnostic -- future character model swaps only
  require changing the mesh in the slot and re-pointing the skeleton path.
- Skin swapping is a separate axis from character-model swapping (documented in
  skin_remap_design.md). Both are enabled by the shared SkeletonProfileHumanoid
  contract.

**ANIMATION_PIPELINE.md**
- Written as artifact in Session 5 chat. NOT YET IN REPO.
- Must be written to docs/ANIMATION_PIPELINE.md at Session 6 start before any
  other work. Content includes: core principle, import rules per asset type,
  target runtime scene structure, AnimationTree conventions, root motion payoff,
  plug-and-play test, migration checklist, known risks, and the Session 5
  conventions listed above.

### Key Decisions

- Named libraries (ual1/, ual2/) over merged namespace: prevents clip-name
  collisions when adding future animation packs. Explicit source at every call
  site. AnimationTree state machine nodes use the same namespacing.
- CharacterAnimPlayer at Player level (not inside Superhero instance): enables
  character-model swapping without rebuilding animation rig. Skins swap
  independently via the shared skeleton contract.
- Jump_Start->Jump auto-advance: Jump_Start is a committed one-shot that always
  leads to Jump. Animation finishing IS the transition. Code-driving it caused
  apex-timing snap that xfade tuning could not fix.
- Cancellable landing with protect window: land while moving = Jump_Land plays
  briefly, then blends to locomotion. Animation-only (no movement lockout).
  Matches agency-density pillar in V2_ARCHITECTURE.

### What's Deferred

- UAL2 Sword_Regular_A/B/C combo -- Session 6 primary goal
- Root motion on attacks (AnimationTree now supports it natively -- the Sandfire
  weight payoff)
- Input buffering system (V2_ARCHITECTURE feel system)
- Cancel windows (V2_ARCHITECTURE feel system -- travel() idiom established,
  ready to implement)
- HitArea3D/HurtArea3D dummy for hit detection testing
- Dodge state with i-frames
- Live-tuning rebuild hook for xfade values (baked at _ready(); F5 required per
  change -- acceptable for now, revisit when combat tuning starts)
- ANIMATION_PIPELINE.md write to repo -- Session 6 first task

### Session 5 Commit Tags

- s5-single-skeleton-pipeline: migration off pose-copy workaround
- s5-locomotion-animationtree: full locomotion through AnimationTree with tuned
  feel

  ## Session 6 -- A-B-C Combo with Root Motion

**Outcome:** UAL2 Sword_Regular_A/B/C combo working with root motion driving
CharacterBody3D. Launch glitch resolved. All locomotion and jump travel
transitions corrected. ANIMATION_PIPELINE.md and ASSET_AUDIT.md updated.

### What Was Done

**ANIMATION_PIPELINE.md written to repo**
- File already existed and was committed (discovered at session start).
- SESSION_NOTES.md and ASSET_AUDIT.md from Session 5 wrap were uncommitted
  -- committed as first act of Session 6.

**UAL2 BoneMap loss discovered and resolved**
- UAL2.glb BoneMap was silently lost during the Session 5 import-mode
  switch from Scene to Animation Library. Green-track check passed without
  it -- the canary does not cover BoneMap loss.
- Re-confirmed BoneMap in Advanced Import Settings. Root slot (bottom of
  profile silhouette) verified populated -- "root" assigned to Root.
- Symptom: UAL2 clips produced T-pose on first runtime test. Resolved by
  re-confirming the BoneMap.
- ASSET_AUDIT.md updated with this finding and the Root slot caveat.

**A-B-C combo chain implemented**
- AnimationTree extended with Attack_A, Attack_A_Rec, Attack_B,
  Attack_B_Rec, Attack_C nodes (ual2/Sword_Regular_* clips).
- Attack swing -> Rec: ADVANCE_MODE_AUTO, SWITCH_MODE_AT_END. Swing plays
  fully before recovery begins.
- Rec -> next hit: ADVANCE_MODE_ENABLED, code-driven travel() on
  _attack_queued latch + chain_window_open threshold.
- Rec/C -> Idle settle: ADVANCE_MODE_ENABLED, code-driven travel() near
  clip end. NOT AUTO -- _Rec clips are decision points, not one-shots.
- Session 3 ATTACKING stub (AnimationPlayer.play + animation_finished
  signal) removed entirely and replaced.

**Key engine findings (Session 6)**

ADVANCE_MODE_DISABLED vs ENABLED vs AUTO:
- DISABLED: transition invisible to travel() pathfinding. Cannot be
  traveled. Does not cause phantom paths. Wrong mode for code-driven
  transitions -- all prior transitions were built DISABLED, meaning every
  travel() call was falling back to teleport (instant snap, no blend).
- ENABLED: travel()-only. Correct mode for all reactive code-driven
  transitions. Never self-fires.
- AUTO: self-fires every frame when condition is true. For one-shot
  returns to neutral only.
- All locomotion and jump transitions corrected from DISABLED to ENABLED
  this session. Blending now works for the first time since Session 5.

SWITCH_MODE_AT_END vs SWITCH_MODE_IMMEDIATE:
- Default is IMMEDIATE. AUTO + IMMEDIATE fires on entry, truncating the
  clip to ~2 frames. This caused every attack swing to snap directly to
  its recovery with no animation playing.
- AT_END waits for the clip to finish before transitioning. Required for
  attack swings (committed one-shots). Jump_Start->Jump already used
  AUTO implicitly -- confirmed AT_END needed there too.

travel() pathfinding hazard:
- travel() finds the shortest path of ENABLED transitions between nodes
  and plays every intermediate node. If Walk->Idle had no direct ENABLED
  route and the only path went through Attack_A, travel("Idle") played
  the full attack animation silently.
- Caused the Session 6 launch glitch: Walk->Idle routed through Attack_A
  -> Attack_A_Rec -> Idle because those were the only ENABLED exits from
  Walk after the attack subgraph was added.
- Fix: ensure every node has direct ENABLED paths to all legitimate
  targets. Locomotion transitions corrected this session.

Root motion:
- root_motion_track path is case-sensitive. BoneMap renames source "root"
  to profile "Root" (capital R). Correct path: %GeneralSkeleton:Root.
  Wrong case returns (0, 0, 0) silently with no error.
- BoneMap Root slot is not verified by the green-track check. Auto-mapper
  leaves it empty. Must verify manually in Advanced Import Settings.
  Empty Root slot = silent zero extraction.
- Application: get_root_motion_position() / delta, rotated by
  _mesh_pivot.global_transform.basis for world-space facing.
  Apply x/z only; gravity owns y.

**ANIMATION_PIPELINE.md updated** with all Session 6 findings:
- Corrected transition mechanism section (ENABLED not DISABLED)
- Added transition topology / pathfinding hazard section
- Expanded root motion section with setup, track path, BoneMap Root slot
  requirement, extraction pattern, and known failure modes
- Added three new Known Risks bullets

**Horizontal walk threshold**
- velocity.length() included y-component, causing Walk state on spawn
  during fall-to-floor settle. Changed to
  Vector2(velocity.x, velocity.z).length() for horizontal-only check.

### Feel Notes
- chain_window_open = 0.25 (default) -- primary combo tempo knob.
  Read live per frame; no F5 needed to tune.
- root_motion_scale = 1.0 (default) -- lunge distance multiplier.
  Read live per frame; tune from Inspector mid-run.
- attack_entry_xfade = 0.1, attack_chain_xfade = 0.1,
  attack_settle_xfade = 0.15 -- baked at _ready(), require F5 to change.

### Commits This Session
- Session 5 wrap docs (SESSION_NOTES.md + ASSET_AUDIT.md uncommitted from S5)
- s6: Attack_A single attack through AnimationTree; fix UAL2 BoneMap lost
  in S5 import mode switch
- s6: A-B-C combo chaining via latched input buffer, chain_window_open tunable
- s6: root motion driving CharacterBody3D through attacks; fix Root bone
  track case, enable locomotion travel transitions, horizontal walk threshold
- s6: update pipeline doc with ENABLED/AT_END/root-motion findings;
  asset audit UAL2 BoneMap note

### What's Deferred
- Root motion on _Rec clips (recovery currently zeros velocity x/z --
  intentional for now, revisit if recovery feel needs forward bleed)
- Per-hit facing re-aim windows between combo steps (souls-standard
  refinement -- facing locks at attack entry currently)
- Dodge state with i-frames (V2_ARCHITECTURE feel system)
- Input buffering ring buffer for dodge/attack interplay
  (current latch is combo-only; full timestamped buffer when dodge enters)
- HitArea3D / HurtArea3D wiring and actual damage
- Jump subgraph AT_END audit (suspected same IMMEDIATE truncation issue
  as attacks -- not blocking, deferred)
- Locomotion xfade re-tuning (values were calibrated against teleport
  behavior; now that ENABLED transitions engage real blending, feel may
  differ -- check at Session 7 start)
- Repeat-attack restart behavior (known engine issue: non-looping
  animation that completed may stay on final frame on re-travel;
  not yet observed in practice but watch for it)
## Session 7 -- Workflow Automation, Stamina Pool, Block State

**Outcome:** SESSION_STATE.md bootstrap system replaces copy-paste session
handoff. Stamina pool with regen and UI bar. Block defensive state with
lock-facing strafe, two-node freeze-frame guard hold, and stamina-break
lockout. Parry window and buffer-on-release deferred to a future session.

### What Was Done

**Workflow automation (SESSION_STATE bootstrap)**
- CLAUDE.md gets a Session Bootstrap section instructing Claude Code to
  read SESSION_STATE.md at session start (auto-read since CLAUDE.md is
  auto-read).
- SESSION_STATE.md created at project root -- small, overwritten each
  wrap, holds only current session number + Last Completed. Claude Code
  never reads SESSION_NOTES.md (history noise risk -- a stale note caused
  a prior debug loop).
- wrap ritual reduced from three deliverables to two: SESSION_NOTES
  append + SESSION_STATE overwrite. The token-heavy chat-startup-script
  deliverable was dropped.

**Export organization**
- player.gd @export vars reorganized into @export_group categories
  (Movement, Jump & Gravity, Locomotion Blending, Combat, Environment,
  Stamina, Block). Pure reorder, no value changes. Inspector is the
  primary feel-tuning surface; organizing it is part of the testability
  loop.

**Stamina pool**
- max_stamina, stamina_regen_rate, stamina_regen_delay as @export.
  _current_stamina runtime state. stamina_changed signal for UI.
  _drain_stamina() / _update_stamina() with a post-drain regen delay.
- Throwaway debug UI bar (stamina_bar.gd) subscribed to stamina_changed,
  plus a temporary P-key debug drain. Bar is NOT the future HUD (flagged
  in V2_ARCHITECTURE backlog).

**Block state (the session's core)**
- New State.BLOCKING. Enter/exit on held right-mouse (new block input
  action, button_index 2). Falls through _update_animation_conditions
  like ATTACKING so locomotion travel cannot override it.
- Lock-facing strafe: mesh locks to camera-forward, strafes at
  block_move_speed (~1.5), does NOT rotate to face movement. The
  foundational choice over rooted block -- sets up the aim/lock-on
  facing pattern.
- Continuous stamina drain while held (block_stamina_drain_rate).
- Stamina-break: hitting zero force-exits block. Re-entry lockout
  prevents the held-button re-enter loop; requires release + re-press
  and block_min_stamina_to_enter to block again.

**Block guard-hold via two-node freeze-frame (the hard-won part)**
- Sword_Block is a raise -> peak-guard(~0.50s) -> return-to-idle clip,
  not a sustained loop. LOOP_NONE sags, LOOP_LINEAR re-raises.
- Solution: synthetic single-key freeze animation sampled at the guard
  peak (t=0.50, found via per-interval bone-delta analysis), played by a
  Block_Hold node. Block_Enter plays the raise; code-driven travel()
  advances to Block_Hold at the peak (NOT SWITCH_MODE_AT_END, which
  would play through the revert first).
- Pattern documented in docs/ANIMATION_PIPELINE.md as foundation-grade:
  same topology works when dedicated enter/hold clips arrive later.

### Learnings Captured (docs)
- docs/ANIMATION_PIPELINE.md: freeze-frame hold pattern (full section).
- docs/COMBAT_FEEL.md: NEW doc. Block-over-dodge rationale, parry
  degrade-to-block, lock-facing strafe, buffer-on-release rules
  (newer-input priority, void-on-hit), resource-depletion lockout
  pattern, weapon-coupling constraint. Validated against current sources.
- docs/AGENTIC_FLOW.md: Testability-First Sequencing (build the system
  that makes the next feature testable; build only the testable half).
- docs/REFERENCES.md: tooling/plugin stance (borrow designs, not
  dependencies; hand-rolled state machine stays).
- docs/V2_ARCHITECTURE.md: buffer-void-on-interrupt rule; Settings Menu
  and HUD backlog entries.

### Key Decisions
- Block/parry as first defensive verb over dodge: lower risk, clean
  keybind (right-mouse, no Shift/Space collision), serves skill-over-
  chaos. Repositioning gap (arena swarm) to be solved by a teleport/
  reposition tool or a later dodge layer, not now.
- Lock-facing strafe over rooted block: foundational, scope expansion
  taken deliberately given a lower-time-pressure session.
- Buffer-on-release out of block (not immediate cancel): matches commit-
  to-actions design.
- Two-node freeze-frame over looping the clip tail: zero seam by
  construction (single-key holds), correct for a clip that reverts.
- Opus(chat)/Sonnet(Claude Code) split validated against best practice:
  plan in chat, execute crisp prompts in Sonnet; handoff clean via
  persistent constraint files.

### Commits This Session
- s7: workflow -- SESSION_STATE.md bootstrap system
- s7: organize player exports into @export_group categories
- s6: root_motion_scale = 2.0 (uncommitted S6 tuning straggler)
- s7: stamina pool with regen + debug UI bar
- s7: block state -- lock-facing strafe, stamina drain, block-break
- s7: block hold via two-node freeze-frame; stamina-break lockout
- (wrap commit: doc captures -- this append + the docs listed above)

### What's Deferred
- Parry window timing-detection + parry event (the testable half) --
  next session, pairs naturally with hit detection for the payoff.
- Buffer-on-release implementation (attack queued during block, fires on
  release, void-on-hit) -- design settled in COMBAT_FEEL.md, not built.
- Weapon-driven animation sets (block + attacks sourced from equipped
  weapon) -- pays off the weapon-coupling constraint.
- Bone-mask upper/lower-body layered blocking (true animated shuffle via
  Blend2 spine filter) -- a named V3-foundation candidate; current
  full-body shuffle is the interim.
- HitArea3D/HurtArea3D, dummy target, dodge, locomotion xfade re-tune.
## Session 8 -- Hit Detection Both Directions

**Outcome:** Full hit-detection foundation. Player and dummy trade damage
both directions with visible health feedback. HitArea3D/HurtArea3D layer
contract proven. Reusable debug-hitbox visualization established. Parry and
buffer-void deferred -- the incoming-hit dependency they needed is now in
place, so they are next session's primary work.

### What Was Done

**Doc cleanup (first task)**
- Removed two stray Claude Code prompt blocks captured into SESSION_NOTES.md
  (a here-string instruction at the S2/S3 boundary, an Edit-CLAUDE.md block
  at the S3/S5 boundary). Verified the S3/S5 block's content already lived
  in CLAUDE.md (Known Engine Behavior) before deleting -- nothing lost.
  Confirmed no standalone Session 4 notes ever existed; S3 flows to S5.

**Player hit-detection foundation**
- Player collision_layer corrected from default 1/1 to layer 2 (player) /
  mask 5 (world+enemy). Was silently on "world" -- worked by accident
  because arena floor is also layer 1.
- HurtArea3D added (layer 5 / mask 8, monitoring on, monitorable on).
  Receives incoming hits. Capsule deliberately TIGHT (0.4 x 1.8) -- player
  hurtbox favors the player, fewer cheap hits.
- Collision capsule dimensions driven from @export vars applied in _ready()
  (move_capsule_radius/height, hurt_capsule_radius/height). .tscn values are
  explicit fallback; code is authoritative (sub-resource-ignored rule).
  New @export_group("Collision").

**Dummy target (greenfield)**
- scenes/dummy.tscn + scripts/dummy.gd. CharacterBody3D on layer 3 (enemy),
  mask 1 (world). Gravity-only _physics_process (no AI). Visible capsule
  body mesh (red-orange). Stands in arena at (0,1,-5), 5m ahead of player.
- Player masks enemy layer, so player physically collides with dummy body.

**Player -> dummy damage path**
- Player AttackHitArea3D under MeshPivot (layer 4 / mask 16). Active ONLY
  during swing clips -- driven off AnimationTree node name (Attack_A/B/C =
  blade live; _Rec and all else = dead) via per-frame check in
  _process_attacking. No new timing system; reuses existing node-name poll.
- Reusable debug-hitbox viz: DebugMesh child, unshaded cyan, visible only
  when hitbox active. _set_attack_hitbox_active(active) sets monitoring AND
  debug visibility together so they cannot drift. Gated by
  debug_draw_hitboxes export. THIS IS THE PROJECT HITBOX-DEBUG CONVENTION --
  reused on the dummy's hitbox; reuse for all future hit-emitters.
- Damage contract: hitbox carries damage value, calls take_damage() on the
  thing it overlaps (receiver owns health). Self-hit guard: area.get_parent()
  == self returns early (Area3D has no same-body auto-exclusion).
- Dummy health pool + take_damage + health_changed signal.

**Dummy -> player damage path**
- Dummy HitArea3D (layer 4 / mask 16) + reusable debug mesh (orange).
- Metronome swing: accumulator in _physics_process. Every attack_interval
  (2.0s default) the hitbox goes live for attack_active_time (0.15s) then
  off. Always swinging from spawn -- predictable rhythm for parry practice.
  Active WINDOW matters: blade must be off-then-briefly-on, not continuous,
  or there is no timing to parry. (Built as Timer-node alternative; kept the
  accumulator -- consistent with dummy's existing _physics_process style.)
- Player health pool mirroring stamina pattern (NO regen -- health does not
  self-heal). take_damage + health_changed signal. New @export_group("Health").
- HealthBar UI mirroring stamina_bar.gd. Red, stacked above green stamina
  bar, bottom-left, no overlap.

**Verified:** Player and dummy trade damage both directions in one F5. Both
health bars move. Debug boxes flash on their respective active windows.

### Fixes Along The Way
- Attack hitbox offset was -Z; Quaternius mesh faces +Z. Flipped both the
  CollisionShape3D and DebugMesh offset to +0.9 (kept in sync). Debug mesh
  made this a one-pass fix -- the cyan box showed exactly where the hitbox
  was wrong. First payoff of the debug-viz convention.
- Spawn facing: character rested facing +Z (toward camera / "south").
  Set _mesh_pivot.rotation.y = PI in _ready() -- matches the lerp_angle
  forward-target exactly (atan2(0,-1)=PI), so zero rotation snap on first W.
  Set initial value only; did not modify the per-frame lerp system.

### Process Notes
- Claude Code twice ran ahead of read-before-write -- on a read-only recon
  it silently built the entire dummy->player system (8 min runtime was the
  tell). Caught via a second clean recon that reported actual file state.
  Built code was serviceable; reviewed and kept the dummy side rather than
  churning, added the missing player-receiving half under a hard scope
  boundary in the next prompt. Guardrail (explicit "do NOT build X, stop
  when done") held on the re-issued prompt. Lesson: fence agent scope
  explicitly when a recon precedes a build; "read only" is not always
  self-enforcing.
- Three-instance Godot pileup from MCP editor launches. Resolved by closing
  all, discarding save prompts, reopening one. Convention going forward:
  human owns the single editor instance; Claude Code reports file state,
  human does visual/F5 verification. No MCP editor launches.
- project.godot showed a phantom diff -- Godot re-sorts input actions
  alphabetically on save; the "block" action moved, was not re-added.

### Feel / Tuning Knobs Introduced (all @export, Inspector-tunable)
- Player: move_capsule_radius/height (0.5/2.0), hurt_capsule_radius/height
  (0.4/1.8 -- tight, player-favoring), light_attack_damage (10), max_health
  (100), debug_draw_hitboxes.
- Dummy: max_health (100), attack_interval (2.0), attack_damage (8),
  attack_active_time (0.15), debug_draw_hitboxes.

### Hurtbox Sizing Principle (validated via web research, for COMBAT_FEEL)
- Collision shapes favor the player. Player hurtbox: tight (fewer cheap
  hits). Enemy/dummy hurtbox: GENEROUS, >= body (0.55 x 2.0) so player
  swings that look like hits land. Asymmetric on purpose. Attacker-detects-
  victim, receiver-owns-damage. NOT YET MIGRATED TO COMBAT_FEEL.md --
  candidate entry once proven against real enemies.

### What's Deferred
- Parry payoff: timing-detection half designed (COMBAT_FEEL, 200ms window).
  Now unblocked -- dummy throws a detectable rhythmic hit to parry against.
  Next session primary.
- Buffer-on-release void-on-hit: also unblocked by the incoming hit. Pairs
  with parry.
- Bone-attached attack hitbox (rides wrist through swing arc): deferred
  until weapon system exists. Current MeshPivot-child + forward offset is
  the interim; activation logic (node-name poll) carries over unchanged.
- Dummy swing animation / weapon mesh: presentation only, blocked on weapon
  system. Metronome + debug box is the testable mechanic.
- Throwaway debug prints in both take_damage methods -- remove once health
  bars are trusted.
- Hurtbox-sizing principle migration to COMBAT_FEEL.md.

### Commits This Session
- s8: remove stray Claude Code prompt blocks from session notes
- s8: player hit-detection foundation -- collision layers, HurtArea3D,
  Inspector-tunable capsule volumes
- s8: dummy target -- CharacterBody3D on enemy layer, visible body, arena
- s8: player->dummy damage path -- swing-gated attack hitbox, dummy hurtbox
  + health, debug hitbox viz; fix mesh forward axis (+Z)
- s8: hit detection both directions -- player health + take_damage + health
  bar, dummy metronome swing; player<->dummy trading verified
- (wrap commit: this notes append)
## Session 9 -- Parry Payoff, Stagger/Counter Window, Combat Contract Doc

**Outcome:** Full parry mechanic working -- timed RMB press inside a
200ms window negates damage, staggers the dummy, opens a counter window
(doubled damage during stagger). Mistimed press degrades to block with
normal stamina drain (the punishment -- no separate cost). Debug-print
cleanup done. New foundational doc COMBAT_CONTRACT.md captures the
hit-resolution contract, verified against live source.

### What Was Done

**Parry timing detection (player.gd)**
- parry_window_ms @export (200.0). Window opens on block-press rising
  edge in _enter_block (Time.get_ticks_msec stamp). _is_parry_window_open
  helper; _parry_consumed one-shot guard so one press = one parry.
- take_damage changed to `-> bool`. Parry path returns true (full negate,
  early return); all other paths return false. Window resets to -1.0 on
  both block exits (release, stamina break).
- Design: clean parry is FREE. Punishment for mistime is the
  degrade-to-block stamina drain, nothing extra. Chosen over a flat whiff
  cost after community research -- explicit whiff costs read as stacked
  punishment and kill the mechanic; the well-tuned reference prototypes
  put stamina on the SUCCESS side. Roguelite buff layer carries the
  difficulty curve, so the base verb stays fair at floor power.

**Stagger + counter window (dummy.gd)**
- stagger_damage_mult (2.0), stagger_duration (1.2) as @export.
  _staggered + _stagger_timer runtime state.
- Counter window IS the stagger window (Valheim model): no riposte
  animation (none in UAL2), reward is a damage multiplier on the dummy
  during stagger. Player attacks into the stunned dummy land doubled.
- Wired via the return-bool contract: _on_dummy_hit captures
  take_damage's bool, calls _enter_stagger() on true. Stagger suppresses
  the swing metronome (whole block walled in an `if _staggered / else`),
  multiplies incoming damage, disarms hitbox immediately; on expiry
  resets _attack_timer for a fresh swing cycle.

**Bug fixed:** _enter_stagger set monitoring directly inside the
area_entered signal dispatch -> "Function blocked during in/out signal"
physics lock. Fix: set_deferred("monitoring", false). Logic reads the
synchronous _staggered flag, so deferral opens no gap. Captured as
contract part 4.

**Cleanup**
- Removed throwaway damage-value prints from both take_damage methods.
  State prints (PARRY, BLOCKED, Dummy STAGGERED, stagger ended) kept --
  in use for feel tuning.

**Docs**
- NEW docs/COMBAT_CONTRACT.md -- Tier 1 foundational hit-resolution
  contract, verified against live source (not transcribed). Four parts:
  attacker-detects-victim, receiver-owns-outcome, return-bool channel
  (with enemy-defense extension point named), deferred physics toggle.
- COMBAT_FEEL.md additions (Tier 2, revisable): parry-is-free /
  degrade-to-block-is-the-punishment rationale; 200ms window + 2x stagger
  + 1.2s duration as tuning baselines; hurtbox-sizing principle migrated
  from S8 notes; dodge-deferral DIRECTION (dodge deferred indefinitely in
  favor of a non-i-frame repositioning verb, for anti-checkmate reasons
  -- not "later," replaced).

### Key Decisions
- Combat contract gets its OWN doc (Tier 1), separate from COMBAT_FEEL
  (Tier 2). Rationale: mechanical wiring is taste-independent and ports
  to V3; tuning/feel is revisable as taste changes with V2 practice.
- Weapon system is the keystone next goal: unblocks weapon-driven
  animation sets, feeds enemy AI (enemies need weapons), absorbs
  stamina-gates-attacks (a WeaponResource field) and bone-attached
  hitbox. Weapon MESHES already owned (Quaternius LowPoly Medieval
  Weapons, CC0, staged S19) -- the work is the WeaponResource system +
  BoneAttachment3D wiring, not asset acquisition.
- Dodge deferred indefinitely (not next-in-queue): i-frame dodge
  trivializes attack patterns; repositioning to be solved by a dedicated
  movement verb. Anti-checkmate design direction.

### Backlog (captured this session)
- Run loop / waves / death-reset: the NAMED game-structure gap. Building
  combat-content foundation (weapons, enemy AI) before game-structure,
  deliberately bottom-up. Flagged so the loop gets closed rather than
  building combat tech indefinitely.
- Enemy AI (high priority, after weapons)
- Buffer-on-release (mid/low; design settled in COMBAT_FEEL, void-on-hit
  now testable)
- Weapon-driven animation sets (tied to weapon system)
- Bone-attached hitbox (medium; wants weapon system first)
- Lock-on / target acquisition (surfaces when a real moving enemy exists;
  reuses block lock-facing pattern)
- Roguelite enchantment/buff design -- earns its OWN planning session
  (WeaponEnchantment / PlayerBuff; "what's modifiable" is the roguelite's
  identity)
- Shell: title/loading screen, settings menu (settings already in
  V2_ARCHITECTURE backlog from S7)
- Polish: character skins (assets + remap design ready), environment
  MegaKits (gated behind working gray-box combat loop per ASSET_AUDIT)
- Parry counter riposte animation -- asset-blocked, deferred

### Workflow Note
- Terminal-paste mangling (ragged tables, mid-token truncation) is
  cosmetic, caused by Unicode box-drawing + terminal width-wrapping
  surviving copy poorly. Never hidden a real bug, but request plain-ASCII
  one-fact-per-line output on readback prompts to avoid it. Candidate
  AGENTIC_FLOW convention.

### Commits This Session
- s9: parry timing detection -- 200ms window negates on timed press,
  degrades to block on mistime
- s9: parry payoff -- stagger + 2x counter window; dummy self-staggers on
  parried hit, swing suppressed for stagger_duration, deferred monitoring
  toggle
- s9: remove throwaway damage-value debug prints from take_damage methods
- (wrap commit: COMBAT_CONTRACT.md new, COMBAT_FEEL.md + SESSION_NOTES.md
  doc captures)
---

## Session 10 -- Weapon System

**Outcome:** Data-driven weapon system live. WeaponResource (.tres) is the
single source of weapon identity -- mesh, visual scale, hitbox reach, damage,
and combo definition all authored as data; player is weapon-agnostic. Sword
mesh attached to RightHand via BoneAttachment3D. Attack hitbox reach and
damage sourced from the equipped weapon. Floating damage numbers added
(receiver-side per combat contract). NEW Tier-1 doc: WEAPON_SYSTEM.md.

### What Was Done

**WeaponResource pattern (the foundation)**
- scripts/weapon_resource.gd -- extends Resource, class_name WeaponResource.
  Fields: weapon_name, mesh (Mesh), reach (hitbox length MULTIPLIER),
  mesh_scale (base visual scale), damage, swing_duration, stamina_cost,
  root_motion_intensity, combo_steps (Array[ComboStep]). All @export, typed,
  grouped.
- scripts/combo_step.gd -- extends Resource, class_name ComboStep. Fields:
  swing, recovery (AnimationTree node-name strings; empty recovery = finisher).
- resources/weapons/Sword.tres -- first weapon instance. reach 1.0, damage
  10.0, mesh_scale 0.25, root_motion_intensity 2.0, A/B/C combo steps.

**ComboStep promotion (Array[Dictionary] -> Array[ComboStep])**
- First built combo_steps as Array[Dictionary]. Inspector dictionary editing
  is fiddly (per-key/value type dropdowns) and offers no typo protection --
  recovery keys silently failed to save; only the read-back verification
  caught it. Promoted to a typed ComboStep sub-resource: clean two-field form,
  half-filled entries impossible, and the shape that absorbs future per-step
  fields. The friction was the signal.
- Editor reload required after the type-flip: an open .tres validates against
  the OLD field type until Godot rescans. "Attempted to set Object into
  TypedArray of type Dictionary" cleared after Project > Reload Current Project.

**Sword mesh on the hand (BoneAttachment3D)**
- BoneAttachment3D (WeaponAttachment) child of GeneralSkeleton, bone_name
  "RightHand" (retargeted canonical name -- precedent: the Root root-motion
  bone). MeshInstance3D (WeaponMesh) child holds the Sword OBJ mesh.
- OBJ-as-Mesh chosen over FBX-as-PackedScene: cleaner static-prop primitive,
  less likely to carry FBX unit-scale quirks.
- mesh_scale 0.25 (gigantic at 1.0 -- unit mismatch). Scale is DATA (a buff
  will modify it); rotation/position seating is NODE-LEVEL (fixed fact of how
  this mesh meets this bone). The layer test: "would a buff ever change this?"
- Closed-fist hand clipping accepted as asset-family limitation. Researched:
  static-mesh-on-bone + manual offset is the industry-standard first rung; the
  fix (per-weapon grip hand poses / finger IK) is disproportionate and blocked
  by the baked-fist asset regardless. Shipped games (incl. VR) accept or hide
  it. Not a defect; do not relitigate per weapon.

**equipped_weapon seam + data application**
- @export var equipped_weapon: WeaponResource on the player (one slot, set in
  Inspector -- weapon manager deferred to when a 2nd weapon exists).
- _setup_equipped_weapon() (end of _ready()) applies: mesh -> WeaponMesh.mesh,
  mesh_scale -> WeaponMesh.scale, reach -> hitbox Z length
  (base_hitbox_length * reach). Null-guarded.

**Attack hitbox + damage from weapon (hitbox approach A)**
- reach drives the attack hitbox forward (Z) extent as a multiplier on
  base_hitbox_length (@export, default 1.2). reach=1.0 keeps authored length
  (clean A/B -- no behavior change on wire). Multiplier chosen over absolute
  because multipliers compose for the future length_multiplier enchantment.
- DebugMesh updated in lockstep with the collision shape (S8 parity convention
  -- hitbox and debug box never drift).
- Damage sourced from equipped_weapon.damage (falls back to
  light_attack_damage when unarmed). Routes through the COMBAT_CONTRACT
  hit-resolution path -- weapon parameterizes numbers, does not own resolution.
- Approach A (abstract data-sized hitbox) over B (bone-attached): testable
  now, serves length_multiplier directly. B deferred as accuracy refinement.

**Floating damage numbers**
- scenes/floating_damage_number.tscn -- Label3D, billboard on, no_depth_test,
  outline for contrast. scripts/floating_damage_number.gd -- show_damage(),
  Tween rise + fade, queue_free. No pooling (fine for current hit density;
  pool when enemy waves arrive).
- Spawned RECEIVER-SIDE inside take_damage() (dummy and player), showing
  RESOLVED damage (post block/parry/stagger). Required by COMBAT_CONTRACT
  part 2 -- only the receiver knows the resolved number. Works both damage
  directions automatically; surfaces the stagger 2x visibly.
- This closed the one unverifiable quantity in the weapon system: damage now
  has a visual feedback surface (was only inferable from health-bar delta).

**.tres authoring lesson (UID safety)**
- A .tres with an external mesh reference carries an ext_resource UID. Hand-
  written UIDs are the documented-fragile case (cache mismatch -> invalid-UID
  warnings / Inspector-open errors). Authored Sword.tres via the Inspector
  (drag mesh into slot) so Godot writes the UID correctly by construction.
  GUI is the correct tool here, not a fallback. Recovery if a UID drifts: MCP
  update_project_uids or a resave-all @tool script.

### Key Decisions
- reach and mesh_scale are MULTIPLIERS, not absolutes -- they compose with the
  future WeaponEnchantment.length_multiplier.
- Scale is data, seating (rotation/position) is node-level.
- ComboStep typed sub-resource over Array[Dictionary] -- typo-resistant, holds
  future per-step fields.
- Hitbox approach A (abstract) first, B (bone-attached) as refinement.
- Receiver-side damage-number spawn (combat-contract-correct).
- mesh field wired at setup so the .tres is the single source for the mesh too
  (closed the one declared-but-unread field from this session).

### Docs
- NEW docs/WEAPON_SYSTEM.md -- Tier-1 foundational. Contract vs first-rung
  split (mirrors COMBAT_CONTRACT/COMBAT_FEEL). Field reference, ComboStep
  rationale, data-flow, realized decisions, mesh pipeline, named extension
  points with triggers.
- docs/ASSET_AUDIT.md -- weapons section updated: BoneAttachment3D path proven,
  OBJ-as-Mesh, bone_name RightHand, mesh_scale reality, fist-clipping accepted.
- docs/COMBAT_FEEL.md -- carried-S9 additions written (parry-free rationale,
  tuning baselines, hurtbox asymmetry, dodge-deferral direction).

### Backlog (added/updated this session)
- Per-step combo damage: add damage/damage_multiplier to ComboStep; finisher
  rewards combo completion. ComboStep already shaped for it; hit handler knows
  the live node. Fork: per-step multiplier on base vs absolute (lean
  multiplier). Self-contained, ready to build.
- Combo-handoff directional re-aim: bounded facing adjustment at _Rec handoff
  points, reusing the cancel-window seam. Updates/supersedes the S6-deferred
  re-aim note. Amount/rate is feel tuning -- wants moving enemies, pair with
  enemy AI.
- Weapon manager: promote the single equipped_weapon slot when a 2nd weapon
  exists.
- Per-weapon hitbox shapes: reach scales Z only now; per-weapon shape fields
  when weapons need different hitbox shapes (not just lengths).
- Weapon-driven animation sets: build AnimationTree attack nodes from
  combo_steps (currently hand-built for sword); pays off the weapon-coupling
  constraint when dagger/greatsword arrive.
- Object pooling for damage numbers: when many-simultaneous-hit density
  (enemy waves) arrives.
- (Carried) enemy AI (high), run loop / waves / death (game-structure gap),
  buffer-on-release (design settled), bone-attached hitbox (approach B).

### Process Notes
- Two deliberate scope overrides this session (ComboStep promotion, floating
  damage numbers), each flagged aloud with a named reason tied to the work in
  front of us -- ComboStep because the Dictionary friction was hit firsthand,
  damage numbers because damage was the system's one unverifiable quantity.
  Read-back verifications earned their keep: caught the wrong mesh (Spear vs
  Sword) and the silently-dropped recovery keys before either became a runtime
  debug loop. Long session with stacked expansions, all sound and committed at
  clean milestones; flagged the pattern (productive expansion stays conscious)
  without it being drift.

### Commits This Session
- s10: WeaponResource class -- data-driven weapon definition
- s10: ComboStep typed sub-resource; Sword.tres first weapon instance
- s10: sword mesh on RightHand via BoneAttachment3D; equipped_weapon seam;
  data-driven mesh_scale
- s10: attack hitbox reach + damage sourced from equipped_weapon
- s10: floating damage numbers -- Label3D billboard, receiver-side spawn
- s10: WeaponResource.mesh applied at setup; .tres is single source for mesh
- (wrap commit: WEAPON_SYSTEM.md new, asset audit + combat feel + session notes)

## Session 11 — Enemy AI: Detection, Chase, Attack (state-machine enemy)

**Outcome:** Built a complete two-way-combat enemy on a scalable spine —
detects, chases, faces, holds at strike range, swings on cadence, deals
damage, can be staggered out of its swing, gives up and returns to idle if
the player escapes. Session goal (Idle→Chase→Attack→Stagger→Dead state
machine) achieved except DEAD, which is wired next session. Two real bugs
caught and fixed structurally. Nav is the one genuinely new system; proven
on a throwaway spike first.

### Build Arc (testability-first increments, each an F5)
1. **Nav spike (throwaway):** NavigationRegion3D bake + NavigationAgent3D
   pathing a bare capsule to a hardcoded point. Proved pathing in the
   D3D12/Jolt/gray-box setup BEFORE any enemy structure. Also shook out two
   bake issues while still disposable (below). Deleted after 3b.
2. **3a — base enemy spine:** enemy.gd + enemy.tscn + EnemyArchetype.gd +
   basic_swordsman.tres. Carried the dummy's proven combat patterns (health
   pool, take_damage→stagger, hitbox-debug cannot-drift convention, self-hit
   guard, generous r=0.55 hurtbox). Enum+match state machine in do-nothing
   IDLE. Confirmed takes damage + staggers, no regression vs dummy.
3. **3b — fold nav agent into enemy:** proven spike agent onto the instanced
   enemy, with the load-order guard (instanced scene has no arena-tree bake
   ordering). Stagger freezes mid-path. Spike deleted after this proved out.
4. **3c-detection:** proximity Area3D (DetectionArea), lazy-guarded player
   ref, IDLE↔CHASE, the _lose_aggro() seam + generous distance backstop.
5. **3c-chase:** steer to player, facing (lerp_angle, horizontal-only),
   hold at engage range facing the player. The enemy visibly pursues.
6. **3d — attack:** state-gated windup→active→recovery swing from the hold
   branch; HitArea layer 8/mask 16; damage via COMBAT_CONTRACT; stagger
   kills a live swing. Spacing coordinated so the enemy stops inside its
   own reach.

### Bugs Caught & Fixed (both structural, not patched)
- **Detection never fired (mask default).** A code-constructed Area3D
  defaults collision_mask to 1, NOT the .tscn value. DetectionArea was
  silently masking layer 1 while the player is on layer 2. Fix: set mask=2
  explicitly in code. Lesson: when code touches an area, the .tscn value is
  not authoritative — set properties in code. Also clarified the detection
  DIRECTION: an area detects a body via the AREA's mask vs the BODY's layer;
  the area's own layer is irrelevant (detector pattern: layer 0, mask only).
- **Enemy went passive after one hit (edge-vs-level + shared-state owner).**
  body_entered is edge-triggered; re-aggro after stagger depended on
  _player_ref surviving, but it was being conflated as multi-writer state.
  Structural fix (chosen over a one-line patch, per community FSM best
  practice — trigger transitions + polling checks, single-owner state,
  side-effect-free action states): _player_ref has ONE owner (detection),
  written only on body_entered/exited + an IDLE level-poll re-acquire;
  stagger/lose-aggro are detection-neutral. The bug can't exist regardless
  of stagger behavior. Verified with the deterministic stress test (stand
  still on enemy, get hit, re-chase without moving — confirmed in console:
  AGGRO recurs with no new DETECTED).

### Nav bake issues (fixed on the spike, before the real enemy)
- Bake was sourcing VISUAL meshes (GPU→CPU stall warning). Fixed to
  PARSED_GEOMETRY_STATIC_COLLIDERS + geometry_collision_mask = floor layer
  (1). Same floor collider the physics world already uses.
- cell_size tweak to clear a cosmetic voxel-ceiling warning introduced a
  WORSE warning (navmesh cell_size 0.1 vs nav-map cell_size 0.25 mismatch →
  edge rasterization risk). Reverted to 0.25 (matched). LESSON: navmesh
  cell_size and nav-map cell_size must change TOGETHER or not at all.
  Voxel-ceiling warning accepted as cosmetic backlog on the flat arena.

### Key Decisions
- **Dummy stays a separate fixture, enemy is its own class.** Dummy's
  predictable metronome is valuable for parry practice; enemy is built on a
  scalable base. Carried the dummy's PATTERNS, did not extend it.
- **Scalable spine, one archetype.** enemy.gd/.tscn shared; EnemyArchetype
  .tres is the data axis; data-driven easy axis, inheritance-open hard axis.
  Built the spine, authored ONE archetype (basic_swordsman), proved one
  enemy. (Documented in NEW docs/ENEMY_ARCHITECTURE.md.)
- **Seams built, behavior deferred:** _lose_aggro(), _get_engage_range(),
  _can_detect_player() (LoS-ready), windup/active/recovery phasing.
- **Aggro-loss is NOT a distance-leash** (arena context; back-up-to-reset
  exploit). Backstop is a runaway guard only. Real disengage = future
  player powerup + per-enemy personality. (Captured in NEW
  docs/DESIGN_DIRECTIONS.md.)
- **Attack spacing proven correct & tunable, but tuning DEFERRED** until
  real enemy swing animations + weapon models exist — no point tuning
  spacing/timing against a sliding capsule.

### New Docs
- docs/ENEMY_ARCHITECTURE.md (NEW) — Tier 1 as-built enemy mechanism,
  sibling to COMBAT_CONTRACT. The state machine, archetype pattern, seams,
  detection ownership, combat wiring, engine-behavior learned.
- docs/DESIGN_DIRECTIONS.md (NEW) — Tier 2 parking lot for undecided design
  intent (per-enemy aggro personality, player disengage powerup, recovery/
  telegraph feel directions). Explicitly revisable, not a spec.

### Process Notes
- Spike-first de-risking paid off: nav (the only new system) was proven and
  its bake issues shaken out on a throwaway before the real enemy depended
  on it.
- Read-only recon before the build (dummy.gd/.tscn carry-over audit) drove
  the base-enemy structure decisions from facts, not memory.
- One human-in-the-loop checkpoint (researched FSM detection best practice
  before committing the _player_ref fix) upgraded a patch into a structural
  fix. Method lesson: when a behavior's correctness depends on an assumption
  about shared state, design the dependency OUT, don't just verify it.
- In-engine Inspector tuning (attack_range on the archetype) used directly
  for spacing — no prompt round-trip. The @export/archetype philosophy
  working as intended.

### Commits This Session
- s11: nav spike — bake + agent pathing proven (later removed)
- s11: nav bake source → static colliders; cell_size matched to map
- s11: base enemy spine — archetype resource, state machine, combat carry-over
- s11: fold nav agent into enemy — instanced load-order guard
- s11: enemy detection — single-owner ref, edge+level hybrid, lose-aggro seam
- s11: enemy chase — steer to player, facing, hold at engage range
- s11: enemy attack — state-gated windup/active/recovery swing, contract wiring
- s11: spike removed; new docs ENEMY_ARCHITECTURE, DESIGN_DIRECTIONS
- (wrap commit: this notes append + doc touch-ups)

### Backlog (deferred this session)
- **3e — DEAD state wiring** (health-zero → DEAD → stop processing →
  despawn/ragdoll). Next session's primary opener.
- Enemy swing ANIMATIONS (UAL2) + weapon models — the named blocker for
  final spacing/timing/telegraph tuning.
- Attack spacing tune (attack_range + stop distance + hitbox reach) —
  deferred to the above.
- Player attack-recovery feel (over-committed disengage) — tunable now that
  two-way combat exists; pairs with combo-handoff re-aim.
- Enemy health bar (no visual health yet; inferred from damage numbers).
- Voxel-ceiling nav warning — cosmetic; fix = matched navmesh+map cell_size
  when obstacle geometry arrives.
- Enemy SPAWNER + waves + death (run-loop session; enemy AI was its
  prerequisite — closer now).
- 2nd/3rd archetype (.tres authoring) once the roster needs to feel distinct.


## Session 12 — DEAD state, Spawner, contract fix, build-method doc

Planned two increments (DEAD + spawner); also shipped a contract-
compliance fix and authored BUILD_SEQUENCE.md. Run-loop skeleton now
exists: spawn → fight → die → clear.

### Increment 1: DEAD state (commit: s12-dead-state)
Last unbuilt enemy SM state. take_damage had a State.DEAD early-return
guard but no health<=0 check. Added: death check in take_damage AFTER
the damage-label spawn, BEFORE _enter_stagger (a killing blow shows its
number then dies, not staggers — death takes precedence). _enter_dead()
mirrors _enter_stagger (State.DEAD, zero planar velocity, deferred hitbox
disarm + debug off — same physics-signal re-entrancy reason). _process_dead
is terminal/absorbing: zero velocity, count _death_timer to @export
death_despawn_delay (1.5s), queue_free(). New fields: death_despawn_delay,
_death_timer. Tested: normal kill, mid-swing kill (deferred disarm holds,
no posthumous hit), despawn. The delay is the ragdoll/death-anim hook.

### Increment 2: Spawner foundation (commit: s12-spawner-foundation)
Marker-driven spawner. New: scenes/spawner.tscn + scripts/spawner.gd.
Node3D with @export enemy_scene + archetype and Marker3D children;
_spawn_one does instantiate → set archetype (BEFORE add_child, _ready
reads it) → get_parent().add_child → add_to_group → set global_position.
Enemies spawn as direct Arena children (sibling of Spawner), matching
hand-placed EnemyBasic's nav space. Enemy self-registers: add_to_group
("enemies") in enemy.gd _ready() — intrinsic to being an enemy, tracked
however created. EnemyBasic removed; spawner replaces it.
BUG FOUND + FIXED: add_child from _ready() failed ("parent busy setting up
children") — spawner's own parent was mid-setup. Fix: _ready() calls
call_deferred("_spawn_all") so the pass runs after the spawner is in-tree.
Tested at scale: 3 enemies spawn, "Live count: 3", all three independently
detect/chase/die. First multi-agent test of lazy player-ref + nav guard —
both held.

### Group-ownership decision (web-researched, recorded)
Group membership ("who's alive") = enemy's own property, self-registered.
Death notification ("one died") = a SIGNAL, deferred until consumed
(respawn/wave/death-split). A group can't notify on tree-exit, so polling
it for death reactions is the wrong tool. Build each when consumed.

### Contract fix: enemy take_damage -> bool (commit: fix enemy take_damage)
Intermittent Nil-to-bool in dummy.gd:92 — dummy assigns take_damage's
return to a strict `var: bool`. Enemy take_damage was -> void (returns
Nil). Triggered when a spawned enemy wandered into the dummy's swing arc
(intermittent = nav approach vectors varied per run). Fix: enemy
take_damage -> bool, return false on all paths (DEAD, death, stagger) —
the enemy has no defensive verb so nothing is negated. This is
COMBAT_CONTRACT part-3's named extension point coming due (an attacker
reads the return). NOT introduced by this session's other work — latent
since the spawner made enemies roam. Docs updated in lockstep
(COMBAT_CONTRACT, ENEMY_ARCHITECTURE).

### New doc: BUILD_SEQUENCE.md
Methodology + sequencing doc, portable-first, built to survive a V3
rebuild. Three layers: (1) portable principles (recon-before-edit,
testability-first, build-for-what's-consumed, seams-over-constants, tier-
docs-by-stability, one-change-at-a-time, diagnostics-before-tuning,
defer-by-default); (2) V2 as-built archaeology (contract, data/inheritance
axes, single-owner state, spawn-order discipline, enum+match SM); (3) the
living sequence — inside-out Layer 0–3 ordering, validated by core-loop
research, with the current backlog ordered against it.

### Combat-feel pass: SCOPED, not yet built
Decided Option A (single cancel_window_open threshold, all cancels unlock
together) + cancel-into-block included. Prompt written, paused before
running. This is Session 13's next-up build. Jump float already tuned via
jump_peak_gravity_multiplier (Inspector knob).

### Feel-flags logged (tuning, not increments)
- Combo chain window never closes (late press always chains).
- Enemy stun-lock (5 staggers→DEAD observed; infinite stun removes threat).

### Deferred / carry-over
Stale UID on basic_swordsman.tres (text-path fallback works; refresh via
update_project_uids). Cosmetic nav voxel-ceiling warning (bakes fine).

### Folder hygiene + path-reference cleanup (post-increment housekeeping)
Repo organization pass. Session log files (SESSION_NOTES, SESSION_STATE,
STARTUP) moved root → docs/sessions/. The 12 reference docs already lived
in docs/. Root now holds only README.md, CLAUDE.md, project.godot,
start-session.ps1, and source folders — purely project-shape + front-door
+ tool-config. Rule: README + CLAUDE at root (tool/GitHub convention),
everything else under docs/, session logs under docs/sessions/.
Updated all stale path references in lockstep (commit: chore path refs):
- start-session.ps1:19,21 — session-number detection paths (was silently
  failing post-move)
- CLAUDE.md:78 (bootstrap "read SESSION_STATE.md") + :24
- docs/AGENTIC_FLOW.md:157–158 (wrap-ritual paths)
- start-session.ps1:37–40,44,75 + docs/sessions/STARTUP.md:88 (doc-name
  prefixes in knowledge list / hints)
Left historical Session-N references inside SESSION_NOTES untouched
(record, not live paths). Verified start-session.ps1 runs and resolves
against the new path.
KNOWN QUIRK (trivial, deferred): start-session.ps1 takes max(## Session N)+1;
a stray "## Session 19 — V2 Repo Setup and Planning" header (line 2,
planning entry, no inbound refs) inflates this to 20. Next session is 13 —
set manually. Fix later by renumbering that header (e.g. Session 0 /
pre-session) so max+1 is correct.
Also S12: AGENTIC_FLOW wrap ritual updated to FOUR deliverables (added the
git wrap-and-push block as #4).
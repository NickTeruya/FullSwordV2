
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
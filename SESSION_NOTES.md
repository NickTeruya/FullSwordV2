
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
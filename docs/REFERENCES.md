# Design References

## Primary North Star: Sandfire by Kmitt

Sandfire is a single-player action-adventure / souls-like built solo in
Godot by Kmitt (https://kmitt.itch.io). It is the closest existing
reference for the movement feel and combat architecture we are targeting
in the v2 design.

### Why Sandfire

- **Same engine, same constraints.** Built solo in Godot (3.2 originally,
  ported to Godot 4). Proves the technical approach is viable in this
  engine for a solo developer.
- **Animation-driven, deterministic movement.** Character feels weighty
  and responsive without relying on continuous physics simulation —
  avoids the orbit artifact and force-application issues that surfaced
  in v1.
- **Committed combat.** Attacks feel decisive because they use root
  motion and explicit state commitment. Players understand why they
  won or lost an exchange.
- **Souls-like skill ceiling.** Easy to learn the controls, high
  ceiling on mastery — aligns with our design pillar of "skill
  reliably overcomes chaos."

### Reference Materials

- 2024 Demo (most current movement feel):
  https://kmitt.itch.io/sandfire-demo-2024
- Devlog #0 — Introduction to Sandfire:
  https://www.youtube.com/watch?v=QDpSO5i2R58
- Devlog #1 — Making a Dark Souls Inspired Combat System:
  https://www.youtube.com/watch?v=w29n0CCDgqc
- Full devlog playlist (15 videos):
  https://www.youtube.com/playlist?list=PLj3K0UERzFLjcDEnf2_HeV1Vd4B_F86_u
- Kmitt's itch.io page:
  https://kmitt.itch.io
- Kmitt on X:
  https://x.com/kmitt91

### What We Are Taking from Sandfire

- CharacterBody3D as player foundation (not RigidBody3D)
- AnimationTree with embedded StateMachine driving visuals
- Root motion on attack animations for weight and commitment
- Explicit player state machine for gameplay logic
- Stamina-gated commitment as the core skill expression

### What We Are NOT Taking

- The souls-like exploration/RPG framing — our v2 is a roguelite
  combat arena, not a metroidvania-style world
- Sandfire's specific art style — we are going stylized/cartoony via
  the Quaternius asset ecosystem

## Rejected Reference: Half Sword

Half Sword (built in Unreal) was the original inspiration for the v1
prototype's emphasis on physics-driven combat and emergent chaos.

We are explicitly stepping away from Half Sword as a reference for v2
because:

- Half Sword's defining feature is continuous physics-driven character
  simulation. Achieving that in Godot is a fool's errand for a solo
  developer — Godot's physics tooling is not built for this and the
  engineering cost would dominate the project.
- v1 demonstrated this directly: the orbit artifact on the player
  character is a known engine limitation under continuous
  PhysicalBoneSimulator3D, with no clean fix without abandoning that
  architecture entirely.
- The v2 design retains physics-driven moments (death ragdoll,
  weapon contact) but does not depend on continuous physics
  simulation for player movement.

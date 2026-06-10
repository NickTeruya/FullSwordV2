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
Defined per-session in SESSION_NOTES.md. When in doubt, defer.

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

## Verification
- After any change, state what to run/test in Godot and what "working" looks like
- Do not claim success — show what to look for

## When Stuck
- State the constraint clearly before proposing a workaround
- Prefer the simpler Godot-native solution over a clever custom one
- Web search after 2 failed diagnostic loops — do not attempt a third
  without new information
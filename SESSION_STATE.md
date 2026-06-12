# Session State — Full Sword V2

## Current Status
Session 11 complete, committed (squash: `s11-enemy-ai`), pushed. ENEMY AI
built and verified in-engine.

## What Exists (as of S11)
A complete two-way-combat enemy on a scalable spine:
- **State machine:** enum+match (IDLE/CHASE/ATTACK/STAGGER/DEAD), mirrors
  the player idiom. DEAD is declared/stubbed only — not wired.
- **Detection:** proximity Area3D, single-owner `_player_ref`, edge+level
  hybrid (body_entered/exited + IDLE level-poll re-acquire), lazy-guarded
  player ref. DetectionArea layer 0 / mask 2.
- **Chase:** nav agent steering to player, facing (lerp_angle, horizontal-
  only), holds at engage range facing the player. Aggro-loss via
  `_lose_aggro()` seam + generous distance backstop (runaway guard only).
- **Attack:** state-gated windup→active→recovery swing from the hold branch.
  HitArea layer 8/mask 16, damage via COMBAT_CONTRACT, stagger kills a live
  swing. Spacing coordinated (stops inside its own reach).
- **Spine:** one enemy.gd/.tscn shared; EnemyArchetype .tres is the data
  axis; basic_swordsman.tres authored. Data-driven easy axis, inheritance-
  open hard axis.
- **Nav:** NavigationRegion3D baked from static colliders, cell_size matched
  to map (0.25). Spike removed.

## Seams Built (behavior deferred)
- `_lose_aggro()` — aggro-drop attach point (future: stealth powerup,
  per-enemy personality)
- `_get_engage_range()` — stop/attack distance (future: per-attack/range-band)
- `_can_detect_player()` — LoS raycast slot-in ready
- windup/active/recovery phasing (future: animation-driven)

## Next Session (S12)
**Primary:** 3e — DEAD state wiring (health-zero → DEAD → stop processing →
despawn/ragdoll-stub). The last unbuilt state.
**Candidate 2nd increment (pick at session start):** spawner foundation
(architect-lean) / 2nd archetype / enemy health bar.
**First step:** read-only recon of enemy.gd (match dispatch, _process_dead
stub, take_damage health-check, stagger path) to confirm DEAD slot-in.

## Active Docs
- Tier 1 (mechanism): V2_ARCHITECTURE, COMBAT_CONTRACT, **ENEMY_ARCHITECTURE
  (new S11)**, ANIMATION_PIPELINE, WEAPON_SYSTEM
- Tier 2 (feel/intent): COMBAT_FEEL, **DESIGN_DIRECTIONS (new S11)**
- Process: CLAUDE.md, AGENTIC_FLOW, ASSET_AUDIT, SESSION_NOTES

## Backlog (deferred)
- Enemy swing animations (UAL2) + weapon models — blocker for spacing/
  telegraph tuning
- Attack spacing tune (attack_range, stop distance, hitbox reach) —
  deferred to above
- Player attack-recovery feel (over-committed disengage) — tunable now;
  pairs with combo-handoff re-aim
- Enemy health bar (no visual health yet)
- Voxel-ceiling nav warning (cosmetic; fix = matched navmesh+map cell_size
  when obstacles arrive)
- Enemy SPAWNER + waves + death (run-loop session; unblocked by S11)
- 2nd/3rd archetype (.tres authoring)

## Process Note (S11)
Commit discipline slipped under session duration — recovered with a squash
commit. Guardrail going forward: commit bound to F5-verify (F5 passes →
commit → next prompt), command pre-built into each build prompt. Candidate
addition to AGENTIC_FLOW as a hard ritual.
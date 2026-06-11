## Session State
Session: 8

## Last Completed
S7 complete. Block defensive state shipped: held right-mouse enters a
guard stance with lock-facing strafe (mesh locks to camera-forward,
strafes at block_move_speed), continuous stamina drain, and stamina-break
with re-entry lockout. Guard pose holds via a two-node freeze-frame
pattern (Block_Enter plays Sword_Block to its ~0.50s peak, code-driven
travel advances to Block_Hold which plays a synthetic single-key freeze
of the peak pose) -- documented in ANIMATION_PIPELINE.md. Stamina pool
(drain/regen + signal + debug UI bar) underneath it. Workflow: SESSION_
STATE.md bootstrap system replaces copy-paste handoff. Exports organized
into @export_group categories. New doc COMBAT_FEEL.md captures block/
parry feel rationale.

Block-as-a-stance is complete and committed. NOT yet built: parry window
(timing-detection + parry event -- the testable half), and buffer-on-
release (attack queued during block, fires on release, void-on-hit).
Both designed in COMBAT_FEEL.md, ready to implement. These pair naturally
with hit detection (HitArea3D/HurtArea3D) since the parry payoff and the
buffer void-on-hit both need an incoming hit to validate against.

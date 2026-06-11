# Combat Feel -- Full Sword V2

Design rationale for combat feel decisions. This captures WHY choices
were made, not how they're implemented (see ANIMATION_PIPELINE.md for
animation mechanics, V2_ARCHITECTURE.md for the spec). The purpose is so
settled questions stay settled -- when revisiting or carrying into V3,
read the reasoning here before relitigating.

Feel is the V2 ship criterion (V2_ARCHITECTURE.md design pillars). These
decisions get extra cycles on purpose.

---

## Defensive verb: block/parry first, dodge deferred

Decided Session 7. The souls-like reference (Sandfire, REFERENCES.md)
implies dodge, but dodge is not a must-have, and block/parry was chosen
as the FIRST defensive verb for concrete reasons:

- Lower implementation risk: Sword_Block animation exists and is
  audited; a dodge needs i-frame timing, recovery windows, and root-
  motion interaction -- more new surface area.
- Clean keybind: block lives on right-mouse, leaving Shift (sprint) and
  Space (jump) untouched. Dodge on Shift collides with sprint; dodge on
  Space collides with jump's reflexive role. The block keybind sidesteps
  the whole knot.
- Serves "skill reliably overcomes chaos": parry timing is pure skill
  expression. Community discourse repeatedly notes i-frame dodge can
  become a crutch that trivializes attack patterns, where parry rewards
  reading the opponent.

The cost block/parry doesn't cover: repositioning when swarmed. In an
arena roguelite with waves, getting surrounded is the default failure
state, and pure block/parry can corner you. Resolution: repositioning
will be solved by a dedicated tool (teleport / repositioning ability)
rather than dodge i-frames, OR dodge enters later as a second defensive
layer once enemies exist to reposition against. Either way it is a
deferred concern, not a Session 7 one.

## Parry mechanics: timed press, degrades to block

The defensive verb is one button (right-mouse), three outcomes by
timing:
- Hold -> block stance. Stamina-draining, reduces but doesn't negate
  damage. The floor -- no timing required.
- Timed press (just before impact) -> parry. Negates damage, staggers
  attacker, opens a counter window.
- Mistimed press (too early) -> degrades to block. Worst case is you
  blocked.

The degrade-to-block pattern (from Crimson Desert's guard system) makes
attempting a parry low-risk: the failure case is still a successful
block, not a whiff. This keeps parry approachable while preserving its
skill ceiling. Block is the forgiving floor; parry is the skill
expression on top. The three-tier (no-timing block / lenient dodge /
strict parry) spectrum is how stance-based action games keep both
low-skill and high-skill players engaged.

A sharper version of this principle, worth holding onto: the floor
should be deliberately INSUFFICIENT at high level, not merely easy.
Stance-based action games that do this well make pure blocking
unsustainable -- stamina drain and guard-break mean tanking hits with
block alone fails against serious pressure, which pulls skilled players
toward parry without forcing it on newcomers. Block keeps low-skill
players alive; its insufficiency at scale is what gives parry its
purpose. The floor/ceiling structure works because the floor is a floor,
not a substitute for the ceiling.

Parry window starts at 200ms, Inspector-tunable. 200ms is a deliberately
forgiving starting point. Shipped stance-based action games run tighter
-- on the order of 130-170ms (~8-10 frames at 60fps). The wider start
lets feel-tuning begin generous and tighten toward a higher skill
ceiling, rather than starting punishing. The reference range is recorded
so tuning has a target, not so we copy a specific game's frame data.
Payoff (damage negation + stagger) deferred to the hit-detection session -- a parry
needs an incoming hit to negate. Session 7 builds the timing-detection
half only (window opens, a timed press fires a detectable event), per
testability-first sequencing (AGENTIC_FLOW.md): build only the half you
can verify now.

## Movement while blocking: lock-facing strafe

Decided Session 7, deliberately the foundational (harder) choice over a
simpler rooted block. While blocking, the character locks facing to
camera-forward and strafes/back-pedals in the guard pose, rather than
rotating to face movement direction (which would moonwalk on backward
input).

This is the foundationally-correct behavior and sets up a pattern that
aim-while-moving, lock-on, and other camera-relative-facing states will
reuse. It overrides the normal "mesh rotates to face movement" logic
(which only the MeshPivot does; the CharacterBody3D never rotates) with
"mesh locks to camera-forward, velocity goes where input points." Slow
strafe speed (block_move_speed, ~1.5 vs walk 5.0) sells the commitment.

## Input buffering: buffer-on-release out of block

Decided Session 7. Attack input during block does NOT interrupt the
block -- it queues and fires when the player releases block. This
matches the project's existing commit-to-actions design (attacks commit
through their swing, cancel only in recovery windows). Community
discourse on stance-based block converges on this: an in-progress
committed action completes, and the next input queues rather than
interrupting.

The buffer rules (consolidated, also in V2_ARCHITECTURE.md input
buffering):
- Newer input replaces older queued input (newer-input priority).
- Getting hit / staggered voids the queue -- a queued action must never
  fire after the character has been hit and the player has seen it land
  (the "possessed character" failure, from Absolver's documented fix).
- For hold-to-cancel states like block, a quick tap-and-release voids
  the queue.

The buffer is a forgiveness system, not a commitment the player can't
take back.

Noted for later (not V2): immediate guard-cancel-into-attack (fighting-
game "guard cancel" -- interrupting block instantly to punish) is the
OPPOSITE of buffer-on-release and a higher-execution-ceiling option.
Conflicts with "block is a committed stance"; a candidate for V3's
advanced defensive vocabulary, not now.

## Resource-depletion lockout pattern

Decided Session 7, generalizable. When a held resource-consuming state
(block) drains its resource (stamina) to empty, the state force-exits
AND locks out re-entry until the input is released and re-pressed. You
cannot hold the button through empty stamina and keep re-triggering.

This makes resource-break MEAN something -- it punishes you until you
reset your input and let the resource recover. A minimum-resource-to-
enter threshold (block_min_stamina_to_enter, ~5) does double duty:
stops the re-entry loop AND prevents a useless sub-second guard at near-
empty stamina.

The same pattern applies to any future resource-gated held/triggered
state (e.g. dodge at empty stamina). Lockout-on-depletion + minimum-to-
enter is the reusable shape.

---

## Known Constraint: animation clips currently weapon-coupled

The block animation is hardcoded to ual2/Sword_Block, and the attack
combo to ual2/Sword_Regular_A/B/C. This welds the current combat to the
sword. When the dagger and greatsword archetypes (V2_ARCHITECTURE
weapons) are added, each wants its own block and attack poses -- a
greatsword guard looks nothing like a dagger guard.

This is a known limitation, NOT new debt: block being hardcoded is
consistent with how attacks are already hardcoded. Both get paid off
together when the weapon-driven animation system is built -- block and
attack clips should come from the equipped weapon's animation set (the
WeaponResource pattern already defines attack sets; block joins them),
not be baked in _ready(). Deferred to that work. Flagged here so it is
not forgotten.

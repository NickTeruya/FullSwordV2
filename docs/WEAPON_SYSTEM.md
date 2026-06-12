# Weapon System -- Full Sword V2

How a weapon is defined, equipped, and resolved. This is FOUNDATIONAL
infrastructure -- the data contract by which every weapon expresses its
identity (look, reach, damage, combo) as authored data rather than code.
It is intended to persist across project versions (V2, V3, and beyond) and
to scale to a large, growing weapon roster.

Status: Adopted Session 10. First weapon (Sword) proves the pattern.

Parse this doc as two layers, deliberately separated (same split as
COMBAT_CONTRACT vs COMBAT_FEEL):

- The contract (this doc, the sections marked CONTRACT) -- taste-
  independent wiring. The single-source-of-weapon-identity rule, the data
  flow, the resolution seam. These hold as the roster grows.
- First-rung implementations (sections marked FIRST RUNG) -- deliberately
  simple now, shaped to grow. Each names its extension point and the trigger
  condition that should promote it. A reader can rely on the contract and
  treat the first-rung parts as known placeholders, not hidden debt.

---

## CONTRACT: A weapon is data, not code

A weapon's entire identity lives in a WeaponResource (.tres). Player code
reads that resource and applies it. Nothing about "what this weapon is" is
hardcoded in the player -- the player is weapon-agnostic; it asks the
equipped resource.

This is the load-bearing principle. Adding a weapon is authoring a .tres,
not editing player logic. A dozen weapons is a dozen data files against one
unchanged code path. Protect this -- any time weapon-specific behavior is
about to land in player code, that is the signal it belongs in
WeaponResource (or a sub-resource) instead.

---

## CONTRACT: WeaponResource field reference

scripts/weapon_resource.gd -- extends Resource, class_name WeaponResource.
All fields @export, strict-typed, grouped.

| Field | Type | Meaning |
|---|---|---|
| weapon_name | String | Display/identity name. |
| mesh | Mesh | The visual mesh. Sourced from OBJ imports (see Mesh Pipeline below). Held as a direct Mesh reference, assigned in the .tres. |
| reach | float | Hitbox forward-length multiplier (not absolute). 1.0 = standard length. Drives the attack hitbox's reach axis. The axis a future WeaponEnchantment.length_multiplier scales. |
| mesh_scale | float | Base uniform visual scale of the weapon mesh. Applied to the WeaponMesh node at setup. The visual analogue of reach; future length_multiplier multiplies this too. |
| damage | float | Base damage the weapon deals. Sourced into the hit at resolution time. |
| swing_duration | float | Reference/tuning value; not yet driving playback rate. |
| stamina_cost | float | Reference value; not yet wired to the stamina pool. |
| root_motion_intensity | float | Multiplier on extracted root motion for this weapon's attacks. |
| combo_steps | Array[ComboStep] | Ordered combo definition. See ComboStep below. |

Note on .tres sparseness: Godot omits fields equal to their script default
from the saved .tres. A weapon that uses default reach/damage will show those
lines absent -- they load correctly regardless. Only off-default values
(e.g. weapon_name, a tuned mesh_scale) are written. This is normal; the
.tres is not a complete dump of the resource.

---

## CONTRACT: ComboStep -- typed combo definition

scripts/combo_step.gd -- extends Resource, class_name ComboStep.

| Field | Type | Meaning |
|---|---|---|
| swing | String | AnimationTree state-machine node name for the swing (e.g. Sword_Regular_A). |
| recovery | String | Node name for the recovery clip (e.g. Sword_Regular_A_Rec). Empty string = no recovery (finisher). |

Why a typed sub-resource and not Array[Dictionary]: the project first
tried Array[Dictionary]. Inspector editing of typed dictionaries is fiddly
(per-key/per-value type dropdowns) and offers no typo protection -- a dropped
key or a misspelled clip name fails silently at travel() time, not at
author time. The Dictionary approach actively bit during authoring (recovery
keys silently did not save; only the read-back verification caught it).
Promoting to a typed ComboStep makes each combo entry a clean two-field form,
makes half-filled entries impossible, and -- critically -- is the shape that
absorbs future per-step fields (see extension points). The friction was the
signal; the typed resource is the resolution.

Strings must match AnimationTree node names exactly (case-sensitive). A
mismatch is a silent no-op, consistent with the broader travel() pathfinding
behavior documented in ANIMATION_PIPELINE.md.

---

## CONTRACT: The data-flow path

1. Equip: the player holds a reference to the active WeaponResource.
   (FIRST RUNG: currently a single @export var equipped_weapon slot -- see
   extension points.)
2. Setup: _setup_equipped_weapon() (called at end of _ready()) reads
   the resource and applies it:
   - mesh_scale -> WeaponMesh node .scale
   - reach -> attack hitbox forward (Z) length, via base_hitbox_length * reach
   - (mesh itself is currently assigned in the editor on the WeaponMesh node;
     see Mesh Pipeline)
   - Guards on equipped_weapon == null (unarmed/fallback state stays coherent).
3. Resolution (damage): at hit time, the attack handler sources damage
   from equipped_weapon.damage (falling back to light_attack_damage when
   unarmed). This routes through the COMBAT_CONTRACT hit-resolution path --
   the weapon parameterizes the numbers; it does not own resolution.
4. Display: resolved damage is shown via a floating damage number spawned
   receiver-side (see below).

---

## CONTRACT: Damage display is receiver-side

Floating damage numbers (scenes/floating_damage_number.tscn, a billboarded
Label3D that rises and fades) are spawned from inside take_damage() on the
victim, showing the resolved amount (after block/parry/stagger math).

This is required by COMBAT_CONTRACT part 2 (receiver owns outcome): only the
receiver knows the post-resolution number. Spawning attacker-side would force
the attacker to know a value it cannot have (the receiver may have halved or
negated it). Receiver-side spawn also means the display works for both damage
directions automatically, and surfaces the stagger multiplier visibly (a
parry-staggered hit shows its doubled number) -- a free verification surface
for a system built two sessions earlier.

FIRST RUNG: spawn-and-queue_free() per hit, no object pooling. Fine for
current low hit density (one player, one dummy). EXTENSION POINT: introduce
object pooling if many-simultaneous-hit density arrives (enemy waves) -- the
standard fix, deferred until the load is real.

---

## CONTRACT: Realized system-level decisions (and why)

These are settled. Read the rationale before relitigating.

- reach is a multiplier, not an absolute length. reach = 1.0 keeps the
  authored base hitbox length unchanged; the dagger goes below 1.0, the
  greatsword above. Chosen because multipliers compose -- when
  WeaponEnchantment.length_multiplier lands, final = base x reach x
  length_multiplier just works. Absolutes do not stack cleanly, and they
  would leak engine-space dimensions into weapon authoring. Same reasoning
  applies to mesh_scale.

- mesh sourced as OBJ-as-Mesh, not FBX-as-PackedScene. The Quaternius
  weapon pack ships FBX (imports as PackedScene), OBJ (imports as Mesh), and
  Blend (not imported). For a static weapon on a bone, a bare Mesh resource is
  the cleaner primitive -- MeshInstance3D.mesh = <obj>, no scene hierarchy to
  traverse, no instanced-scene boundary. OBJ is also less likely to carry the
  baked FBX unit-scale quirk. Per CLAUDE.md "simpler Godot-native solution,"
  OBJ-as-Mesh wins for static props.

- .tres with a mesh reference is authored via the Inspector, not hand-
  written text. A .tres referencing an external mesh carries an ext_resource
  with a UID. Hand-written UIDs are the documented-fragile case (UID-cache
  mismatch -> "invalid UID" warnings, or Inspector-open errors). Letting Godot
  write the reference (drag mesh into the Inspector slot) makes the UID correct
  by construction. This is the GUI-is-the-correct-tool case, not a fallback --
  same justification as any .glb-instancing scene save. Recovery path if a UID
  ever drifts: MCP update_project_uids, or the resave-all-resources @tool script.

- Hitbox approach A (abstract, data-sized) over B (bone-attached). The
  attack hitbox is an abstract box sized from reach, reusing the S8 swing-
  gated activation (node-name poll). Chosen as the testable-now path: it
  serves the length_multiplier axis directly and does not block on getting
  bone-attached transforms right through the swing arc. B (a hitbox riding the
  weapon bone) is a strictly-more-accurate refinement -- see extension points.

---

## Mesh Pipeline (realized specifics)

- Source: Quaternius LowPoly Medieval Weapons (CC0). Use the OBJ files
  (assets/weapons/OBJ/*.obj), which import as Mesh resources.
- Attachment: a BoneAttachment3D (named e.g. WeaponAttachment) child of
  GeneralSkeleton, bone_name = "RightHand" (the retargeted canonical
  profile name -- precedent: the Root root-motion bone, same canonical-over-
  source-name pattern). A MeshInstance3D (WeaponMesh) child of the
  attachment holds the mesh.
- Scale is data; rotation and position are node-level. mesh_scale (data)
  drives the WeaponMesh .scale because size is a gameplay variable the
  roguelite layer will modify. The seating offset (rotation + position to sit
  the grip in the hand) is a fixed physical fact of how this mesh meets
  this bone -- a buff would never change it -- so it lives on the node,
  tuned once by eye. The test for which layer something belongs to: "would a
  buff ever change this?" Yes -> data. No -> node.
- Hand clipping is an accepted asset-family limitation, not a defect. The
  Quaternius hand is sculpted as a closed fist (baked geometry, not a dynamic
  grip). A static weapon overlays it. This is the industry-standard first rung
  (static mesh on hand bone + manual offset is literally step one of how every
  studio does this); the next rung (per-weapon authored grip hand poses, or
  finger IK) is disproportionate for this project's visual bar and is blocked
  by the asset pack's baked hands regardless. Shipped games -- including VR --
  routinely accept or hide this. Do not relitigate per-weapon; the dagger and
  greatsword will have the same overlay and that is fine.

---

## EXTENSION POINTS (named, with triggers)

The system is deliberately first-rung in several places. Each is shaped to
grow; promote when its trigger fires.

- Equip slot -> weapon manager. Trigger: the second weapon exists.
  Currently one @export var equipped_weapon set in the Inspector. When
  weapon-swapping, pickups, or loadouts arrive, this becomes a manager (equip
  on pickup, swap, hold a roster). The single slot is the right size for one
  weapon; the manager is the right size for many.

- mesh_scale float -> Vector3. Trigger: a weapon needs non-uniform visual
  stretch. Uniform float covers the common case (a well-proportioned mesh
  needs one size knob). Promote only when a specific weapon wants axis-
  independent scaling -- a one-weapon need, not a speculative default.

- reach scales Z only -> per-weapon hitbox shapes. Trigger: weapons need
  meaningfully different hitbox shapes (a spear's long thin reach vs a
  greatsword's wide arc), not just different lengths. Currently reach scales
  the box's forward (Z) extent; X/Y stay authored. Per-weapon shape fields on
  WeaponResource are the next step when uniform-length-scaling stops being
  enough. (This is explicitly wanted -- weapons will not all have uniform
  hitboxes that scale with reach.)

- Flat weapon damage -> per-step ComboStep damage. Trigger: the combo
  needs to mean something mechanically (incentive to finish). ComboStep is
  already the right shape -- add a damage or damage_multiplier field per
  step; the finisher rewards completion. The hit handler already knows the
  live attack node (S8 node-name poll), so it reads the current step's value.
  Fork to settle at build time: per-step multipliers on a base damage
  (enchantment-friendly, lean this way) vs absolute per-step values.

- Facing locks at attack entry -> combo-handoff directional re-aim.
  Trigger: the full A->B->C feels too long to be locked in one direction
  (agency-density). A bounded facing adjustment at the _Rec handoff points,
  reusing the existing cancel-window seam. Updates/supersedes the S6-deferred
  re-aim note. The amount (snap vs clamped rotation rate) is feel tuning
  that wants moving enemies to be meaningful -- pair the tuning with enemy AI.

- Hitbox A (abstract) -> B (bone-attached). Trigger: accuracy matters more
  than the abstract box (e.g. the visible blade and the hitbox visibly
  disagree). A hitbox riding the weapon bone through the swing arc. Same
  COMBAT_CONTRACT layer-4 emitter, different transform parent -- a contained
  swap, not a rewrite. Deferred because A is testable now and B wanted the
  weapon system to exist first.

- Weapon-coupled animation/block clips -> weapon-driven animation sets.
  (Cross-ref COMBAT_FEEL.md "weapon-coupled" constraint.) Trigger: the dagger
  and greatsword arrive, each wanting its own block and attack poses. The
  combo_steps field already declares a weapon's attack clips as data; block
  joins them. The AnimationTree attack nodes are currently hand-built in
  _ready() for the sword clips -- the next rung builds those nodes from the
  equipped weapon's combo_steps rather than hardcoding, so a weapon swap
  rebuilds the attack subgraph. This is the larger structural step the
  combo_steps data shape was chosen to enable.

---

## Known first-rung state (summary)

- One weapon authored (Sword). Pattern proven; dagger/greatsword are
  "author a .tres," validating the system is data-driven not hardcoded.
- One equip slot, no manager.
- Uniform mesh_scale, reach scales hitbox Z only.
- Flat per-weapon damage (no per-step).
- Abstract data-sized hitbox (approach A).
- AnimationTree attack nodes hand-built for sword clips (not yet built from
  combo_steps).
- Mesh assigned on the WeaponMesh node in-editor (the mesh WeaponResource
  field exists and is the intended single source; wiring the node's mesh
  from the field at setup is a natural consolidation when the weapon manager
  lands).

None of the above is hidden debt -- each is a deliberate rung with a named
trigger above. The contract sections are what to build against.
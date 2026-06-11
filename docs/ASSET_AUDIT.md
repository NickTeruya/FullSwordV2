# Asset Audit — Full Sword V2

Inventory of owned assets, skeleton families, and readiness status.
Updated as new assets are acquired or audited.

Last updated: Session 5

---

## Skeleton Family Rule

All player and enemy characters must use the Quaternius Universal Base
Characters Humanoid Rig. No mixing of skeleton families. KayKit and
other CC0 character packs are explicitly excluded to avoid
Mixamo->Humanoid remap fights.

This rule is the load-bearing constraint for the entire animation
pipeline. Every asset in this project shares SkeletonProfileHumanoid
via a BoneMap. Because they share that profile, any animation retargets
onto any character with zero per-asset glue code, and swappable
character models and skins are both possible without remap work.
See docs/ANIMATION_PIPELINE.md for the full pipeline design.

---

## Characters

### Quaternius Universal Base Characters (Standard, free)
- Source: quaternius.com / quaternius.itch.io
- Rig: Humanoid (native -- no remap required)
- Variants: Male and Female in Superhero, Regular, and Teen proportions
- Status: Ready to use. Foundation for all player and enemy characters.
- Import mode: Scene. BoneMap + SkeletonProfileHumanoid configured
  (Session 1). GeneralSkeleton is the runtime skeleton name.
- Notes: Source tier includes .blend files if custom modifications
  needed later. Not required for v2.

### Quaternius Modular Character Outfits Fantasy (Standard, free)
- Source: quaternius.com / quaternius.itch.io
- Rig: Humanoid-compatible. Standard tier glTF exports audited at
  Session 1 -- BoneMap configured against SkeletonProfileHumanoid.
- Variants owned: Male Ranger, Female Ranger, Male Peasant,
  Female Peasant
- Status: Ready to use. BoneMap configured (Session 1).
- Known omission: Male_Ranger_Arms_Bracer absent from Standard tier.
  Base mesh shows through at shoulder/chest area. Acceptable for v2.
- Notes: Skin swapping design (binding Modular Outfit meshes to
  GeneralSkeleton) documented in docs/skin_remap_design.md. The
  Skin.set_bind_name() remap procedure handles any Mixamo-named bind
  cases. As long as every character uses SkeletonProfileHumanoid, any
  skin binds to any character -- the skeleton contract enables both
  character-model and skin swapping independently.

---

## Animations

### UAL1.glb (Source tier, purchased)
- Source: quaternius.itch.io/universal-animation-library
- Rig: Humanoid. BoneMap + SkeletonProfileHumanoid configured (Session 1).
- Import mode: Animation Library (changed from Scene at Session 5).
  Clips load as a retargeted AnimationLibrary -- no mesh, no skeleton.
- Clip count: 127
- Status: Ready to use. Loaded in player.gd under library key "ual1".
  Clips addressed as ual1/ClipName.
- Notes: UAL1_Standard.glb (free tier) kept in assets/animations/ as
  fallback reference only -- not loaded or used.

#### UAL1 Locomotion Clips (currently wired in AnimationTree)
- ual1/Idle -- standing neutral loop
- ual1/Walk -- walking loop
- ual1/Sprint -- sprint loop
- ual1/Sprint_Enter, ual1/Sprint_Exit -- sprint transition clips
- ual1/Jump_Start -- jump launch (one-shot, auto-advances to Jump)
- ual1/Jump -- falling loop
- ual1/Jump_Land -- landing crouch (one-shot, auto-settles to Idle)

#### UAL1 Directional Locomotion (available for blend spaces, not yet wired)
- ual1/Jog_Fwd, Jog_Fwd_L, Jog_Fwd_R, Jog_Fwd_LeanL, Jog_Fwd_LeanR
- ual1/Jog_Bwd, Jog_Bwd_L, Jog_Bwd_R
- ual1/Jog_Left, Jog_Right
- ual1/Walk_Formal
- Notes: These enable directional locomotion blend spaces when needed.
  Not wired yet -- binary Walk/Sprint sufficient for current scope.

#### UAL1 Hit Reactions (for stagger system)
- ual1/Hit_Chest, Hit_Head, Hit_Shoulder_L, Hit_Shoulder_R, Hit_Stomach
- Notes: Directional hit reactions. Use when hit direction is known.

#### UAL1 Combat (placeholder -- superseded by UAL2)
- ual1/Sword_Attack -- original placeholder attack, now replaced by UAL2
- ual1/Sword_Attack_RM -- root motion variant
- ual1/Sword_Attack_Standing, Sword_Enter, Sword_Exit, Sword_Idle

#### UAL1 Other (available, not scoped for v2)
- Crouch variants, Climb/ClimbLedge, Crawl variants, Dodge_Left/Right
  (with _RM variants), Roll/Roll_RM, Death01/Death02, social animations
  (Dance, Celebration, Crying, etc.), Spell variants, Swim, and more.

---

### UAL2.glb (Source tier, purchased)
- Source: quaternius.itch.io/universal-animation-library
- Rig: Humanoid. BoneMap + SkeletonProfileHumanoid configured (Session 1).
- Import mode: Animation Library (changed from Scene at Session 5).
  Clips load as a retargeted AnimationLibrary -- no mesh, no skeleton.
- Clip count: 135
- Status: Ready to use. Loaded in player.gd under library key "ual2".
  Clips addressed as ual2/ClipName.
- Notes: Primary combat animation source for v2.

#### Understanding the UAL2 Clip Naming Pattern

UAL2 uses a consistent suffix convention across all combat clips:

- No suffix -- the attack swing itself (e.g. Sword_Regular_A)
- _Rec suffix -- recovery animation after the hit lands. These are the
  follow-through and return-to-guard clips. In V2_ARCHITECTURE's cancel-
  window system, _Rec clips play during the recovery frames where the
  player can cancel into a dodge or next attack. They are not optional
  polish -- they are the mechanical scaffolding for combo feel.
- _RM suffix -- root motion variant. The character physically moves
  through the strike via AnimationTree.get_root_motion_position(). These
  are the Sandfire-feel clips -- attacks that lean into the strike with
  committed forward momentum. Use these for heavy/committed attacks.
- _Combo suffix -- a single clip covering a full combo sequence.
  Alternative to chaining individual A/B/C clips.

#### UAL2 Regular Sword Combo (primary v2 combat target)
- ual2/Sword_Regular_A -- first hit
- ual2/Sword_Regular_A_Rec -- recovery after A
- ual2/Sword_Regular_B -- second hit
- ual2/Sword_Regular_B_Rec -- recovery after B
- ual2/Sword_Regular_C -- third hit / finisher
- ual2/Sword_Regular_Combo -- full A-B-C sequence as one clip
- Notes: These are Session 6's primary wiring target. Chain A->B->C
  with cancel windows between each _Rec clip.

#### UAL2 Light Sword Combo (fast/dagger archetype)
- ual2/Sword_Light_A, A_Rec
- ual2/Sword_Light_B, B_Rec
- ual2/Sword_Light_C, SwordLight_C_Rec (note: inconsistent prefix in lib)
- ual2/Sword_Light_D
- ual2/Sword_Light_Combo
- Notes: Higher speed, lower commitment than Regular. Maps to the
  Dagger weapon archetype in V2_ARCHITECTURE.

#### UAL2 Heavy Sword Combo (greatsword archetype)
- ual2/Sword_Heavy_A, A_Rec
- ual2/Sword_Heavy_B, B_Rec
- ual2/Sword_Heavy_C, C_Rec
- ual2/Sword_Heavy_D
- ual2/Sword_Heavy_Combo
- Notes: Slow, high commitment. Maps to the Greatsword archetype.
  Pair with _RM variants for full weight payoff.

#### UAL2 Root Motion Attacks (committed, physically moving strikes)
- ual2/Sword_Dash_RM -- dashing forward strike
- ual2/Sword_GroundPound_RM -- overhead slam with forward momentum
- ual2/Sword_UpperCut_RM -- upward strike with lift
- Notes: These use AnimationTree.get_root_motion_position() to move
  the CharacterBody3D through the strike. This is the Sandfire feel
  reference -- attacks lean into the target. Now natively available
  with the single-skeleton AnimationTree pipeline (Session 5).
  Not possible under the old pose-copy workaround.

#### UAL2 Block and Special
- ual2/Sword_Block -- blocking stance / parry clip
- ual2/Sword_Aerial_A, A_Rec -- aerial attack first hit
- ual2/Sword_Aerial_B -- aerial attack second hit
- ual2/Sword_Aerial_Combo -- full aerial sequence
- ual2/Sword_Aerial_Idle -- sustained aerial combat stance

#### UAL2 Hit Reactions (stagger / knockback)
- ual2/Hit_Knockback -- hit stagger (no root motion)
- ual2/Hit_Knockback_RM -- hit stagger with physics-driven knockback
- ual2/LiftAir_Hit_L, LiftAir_Hit_R -- struck while airborne, left/right
- Notes: Hit_Knockback_RM is the clip to use for weighty impact feel.
  LiftAir variants handle aerial hit reactions for airborne combat.

#### UAL2 Airborne / Aerial State Clips
- ual2/LiftAir_Idle -- sustained airborne combat idle
- ual2/LiftAir_Fall, LiftAir_Fall_Impact, LiftAir_Fall_RM -- falling
- ual2/LiftAir_RM -- launched into air (by enemy hit or mechanic)
- ual2/NinjaJump_Start, NinjaJump_Idle, NinjaJump_Land -- alternative
  jump style with tighter arms (candidate for fall clip swap if
  ual1/Jump wide-arm pose causes visual issues)
- ual2/DoubleJump -- double jump clip if that mechanic is added

#### UAL2 Movement (available, not scoped for v2 combat)
- Turn180_L_RM, Turn180_R_RM -- 180 degree turn with root motion
- Walk_Fwd/Bwd/L/R variants, Walk_Carry, Walk_Bwd variants
- SafetyVault_RM, StepUp_RM, ClimbUp_1m_RM, ClimbUp_2m_RM
- WallRun_L/R, WallRun_Jump_L/R
- Slide, Slide_Start, Slide_Exit
- Shield_Dash_RM, Sprint_Shield

#### UAL2 Other (available, not scoped for v2)
- Melee_Combo, Melee_Hook/Rec, Melee_Knee/Rec, Melee_Uppercut (unarmed)
- Zombie_* variants (enemy archetype animations)
- Social/interaction: Yes, Surprise, Consume, Bandage, Mining, etc.

---

## Textures

### Poly Haven (CC0, free)
- Source: polyhaven.com
- Assets used in v1, available for reuse:
  - cobblestone_floor_001 (2K PNG set)
  - castle_wall_slates (2K PNG set)
- Status: Ready to use.
- Notes: PNG variants only -- EXR normal maps fail to import in
  Godot 4.6.3. Always download PNG variant from Poly Haven.

---

## Environment

### Quaternius MegaKits -- NOT YET PURCHASED
- Medieval Village MegaKit -- targeted for v2 arena environment
- Fantasy Props MegaKit -- targeted for v2 props
- Stylized Nature MegaKit -- targeted for v2 outdoor elements
- Decision: Defer all purchases until combat loop is working in
  gray box. CSGBox3D primitives + Poly Haven textures for now.

---

## Weapons

### Quaternius LowPoly Medieval Weapons (free, CC0)
- Source: quaternius.itch.io/lowpoly-medieval-weapons
- Contents: 22 medieval weapons -- swords, axes, bows, hammers, shields
- Format: FBX, OBJ, Blend (no glTF -- Godot imports FBX directly)
- Rig: Static meshes only -- no skeleton, no animations
- Status: Ready to use. Drop into scene, attach via BoneAttachment3D
  to RightHand bone. No retarget required.
- Notes: Visual style matches Quaternius character assets.
  CC0 -- no attribution required.

---

## Retarget Status Summary

| Asset                    | Import Mode       | Retarget Configured      | Ready to Use |
|--------------------------|-------------------|--------------------------|--------------|
| Universal Base Characters| Scene             | Native Humanoid          | Yes          |
| Modular Outfits Fantasy  | Scene             | BoneMap configured S1    | Yes          |
| UAL1.glb                 | Animation Library | BoneMap configured S1    | Yes          |
| UAL2.glb                 | Animation Library | BoneMap configured S1    | Yes          |
| LowPoly Medieval Weapons | Scene             | None (static mesh)       | Yes          |

All animation assets import as Animation Library and load under named
library keys in player.gd _ready(). No asset requires further retarget
work before use.

---

## Future Pipeline Considerations

The current asset strategy deliberately stays within the Quaternius
ecosystem (Universal Base Characters + UAL1/UAL2 + Modular Outfits).
This sidesteps asset pipeline friction entirely: every asset shares
SkeletonProfileHumanoid, so animation retargeting and skin swapping
work with zero per-asset glue code.

This strategy has a ceiling. At larger scale -- a commercial project,
a wider variety of enemy archetypes, or content from studios outside
the Quaternius family -- you will eventually need assets that don't
share the same skeleton profile. At that point the evaluation and
onboarding questions become:

- Does the asset ship with a Humanoid-compatible rig, or does it need
  a Mixamo->Humanoid remap? (See docs/skin_remap_design.md for the
  remap procedure -- it is designed and documented, just not yet
  needed for v2.)
- If remapping is required, are the bind names accessible via the
  Skin API (set_bind_name) or is the mesh authored in a way that
  makes the vertex buffer immutable?
- Does the animation pack retarget cleanly to SkeletonProfileHumanoid,
  or do bone proportions differ enough that retargeted clips look
  wrong without manual adjustment?

These are v3+ concerns. For v2, enforce the Quaternius-only rule and
do not introduce assets that require remap work unless the combat loop
is already shipping.

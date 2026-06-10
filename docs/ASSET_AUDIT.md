# Asset Audit — Full Sword V2

Inventory of owned assets, skeleton families, and readiness status.
Updated as new assets are acquired or audited.

Last updated: Session 19

---

## Skeleton Family Rule

All player and enemy characters must use the Quaternius Universal Base
Characters Humanoid Rig. No mixing of skeleton families. KayKit and
other CC0 character packs are explicitly excluded to avoid
Mixamo->Humanoid remap fights.

---

## Characters

### Quaternius Universal Base Characters (Standard, free)
- Source: quaternius.com / quaternius.itch.io
- Rig: Humanoid (native — no remap required)
- Variants: Male and Female in Superhero, Regular, and Teen proportions
- Status: Ready to use. Foundation for all player and enemy characters.
- Notes: Source tier includes .blend files if custom modifications
  needed later. Not required for v2.

### Quaternius Modular Character Outfits Fantasy (Standard, free)
- Source: quaternius.com / quaternius.itch.io
- Rig: Described as Humanoid-compatible, but v1 (Session 15) found
  that Standard tier glTF exports shipped with Mixamo bone names
  (pelvis, spine_01, hand_r, etc.) despite the Humanoid rig.
- Variants owned: Male Ranger, Female Ranger, Male Peasant,
  Female Peasant
- Status: AUDIT REQUIRED at Session 1. Open one outfit glTF in Godot
  Advanced Import Settings and check bind names. Two outcomes:
  - Bind names are Humanoid (Hips, Spine, RightHand) — ready to use
  - Bind names are still Mixamo — run v1 EditorScript remap procedure
    (see FullSwordDemo/docs/skin_remap_design.md and apply_skin_remap.gd)
- Known omission: Male_Ranger_Arms_Bracer absent from Standard tier.
  Base mesh shows through at shoulder/chest area. Acceptable for v2.

---

## Animations

### UAL1.glb (Source tier, purchased)
- Source: quaternius.itch.io/universal-animation-library
- Rig: Humanoid — but retarget NOT pre-configured in this file
- Clips (56): Full locomotion set including Idle, Walk, Sprint, Jump,
  Crouch variants, Climb, Crawl, Jog directions, Sword_Attack,
  Sword_Idle, and more
- Status: NOT ready to use. Retarget configuration required at
  Session 1 — open in Advanced Import Settings, configure BoneMap
  with SkeletonProfileHumanoid. Same procedure used for
  UAL1_Standard.glb in v1 Session 11.
- Notes: UAL1_Standard.glb (free tier, retarget pre-configured) kept
  as fallback reference only. UAL1.glb is the v2 canonical source.

### UAL2.glb (Source tier, purchased)
- Source: quaternius.itch.io/universal-animation-library
- Rig: Humanoid — retarget status UNKNOWN
- Clips (confirmed present): Sword_Regular_A/B/C, Sword_Heavy_A/B/C/D,
  Sword_Light_A/B/C/D, Sword_Block, Sword_UpperCut_RM, Sword_Dash_RM,
  Sword_GroundPound_RM, Sword_Heavy_Combo, Sword_Regular_Combo,
  Sword_Aerial_Combo, Sword_Aerial_Idle
- Status: NOT ready to use. Retarget audit required before first use —
  open in Advanced Import Settings and check whether BoneMap is
  configured. If not, configure same as UAL1.glb.
- Notes: Primary combat animation source for v2.

---

## Textures

### Poly Haven (CC0, free)
- Source: polyhaven.com
- Assets used in v1, available for reuse:
  - cobblestone_floor_001 (2K PNG set)
  - castle_wall_slates (2K PNG set)
- Status: Ready to use.
- Notes: PNG variants only — EXR normal maps fail to import in
  Godot 4.6.3. Always download PNG variant from Poly Haven.

---

## Environment

### Quaternius MegaKits — NOT YET PURCHASED
- Medieval Village MegaKit — targeted for v2 arena environment
- Fantasy Props MegaKit — targeted for v2 props
- Stylized Nature MegaKit — targeted for v2 outdoor elements
- Decision: Defer all purchases until combat loop is working in
  gray box. CSGBox3D primitives + Poly Haven textures for Session 1.

---

## Retarget Status Summary

| Asset | Retarget Configured | Ready to Use |
|---|---|---|
| Universal Base Characters | Native Humanoid | Yes |
| Modular Outfits Fantasy | Unknown — audit S1 | Conditional |
| UAL1.glb | No — configure S1 | No |
| UAL2.glb | Unknown — audit S1 | No |

## Session 1 Asset Checklist

Before any animation or character work in Session 1:

1. Configure UAL1.glb retarget in Advanced Import Settings
2. Audit UAL2.glb retarget status — configure if missing
3. Open one Modular Outfit glTF, check bind names — run remap
   script if still Mixamo names
4. Confirm Universal Base Characters load cleanly in a fresh scene

These four steps are prerequisites for all character and animation
work. Budget 1-2 hours for the full checklist.

## Weapons

### Quaternius LowPoly Medieval Weapons (free, CC0)
- Source: quaternius.itch.io/lowpoly-medieval-weapons
- Contents: 22 medieval weapons — swords, axes, bows, hammers, shields
- Format: FBX, OBJ, Blend (no glTF — Godot imports FBX directly)
- Rig: Static meshes only — no skeleton, no animations
- Status: Ready to use. Drop into scene, attach via BoneAttachment3D
  to RightHand bone. No retarget required.
- Notes: Visual style matches Quaternius character assets.
  CC0 — no attribution required.
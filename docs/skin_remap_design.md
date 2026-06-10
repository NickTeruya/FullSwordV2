# Design: Remapping Modular Outfit Skins onto `GeneralSkeleton`

**Status:** Design only — no code written yet.
**Problem:** `Male_Ranger` (and 7 other modular outfit pieces) carry `Skin` resources whose
named binds use Mixamo-style joint names (`pelvis`, `spine_01`, `clavicle_l`, `root`, finger
bones, …). The target `GeneralSkeleton` (inside `UAL1_Standard.glb`) uses Humanoid bone names
(`Hips`, `Spine`, `LeftShoulder`, …). Godot can't resolve the binds, prints
`Skin bind #N contains named bind '<name>' but Skeleton3D has no bone by that name`, and the
mesh fails to deform.

---

## 1. Confirmed API surface

I read the 4.6 docs for `Skin`, `MeshInstance3D`, `Skeleton3D`, and — because the official docs
have **no method descriptions for `Skin`** ("There is currently no description for this method"
on every entry) — I pulled the actual engine source to confirm behavior empirically.

### `Skin` (`scene/resources/3d/skin.{h,cpp}`)

Internally, each bind is a small struct:

```cpp
struct Bind {
    int bone = -1;        // index-based reference (default: unset)
    StringName name;      // name-based reference (default: empty StringName())
    Transform3D pose;     // inverse bind pose
};
```

Confirmed methods (all present, all functional, all trigger `emit_changed()` so a live
`MeshInstance3D` picks up the change automatically — see §1 "live update" note below):

| Method | Behavior (confirmed from source) |
|---|---|
| `get_bind_count() const -> int` | Returns `bind_count` (inline getter). |
| `set_bind_count(p_size: int)` | Resizes the `binds` array, calls `emit_changed()`. **Destroys/creates slots — changes the indices that `ARRAY_BONES` refers to (see §5 risk).** |
| `get_bind_name(i) -> StringName` | Inline getter, returns `binds[i].name` (empty `StringName()` if unset). |
| `set_bind_name(i, name: StringName)` | Sets `binds[i].name`, calls `emit_changed()`, and `notify_property_list_changed()` if the "is named" state flipped. |
| `get_bind_bone(i) -> int` | Inline getter, returns `binds[i].bone` (`-1` if unset). |
| `set_bind_bone(i, bone: int)` | Sets `binds[i].bone`, calls `emit_changed()`. |
| `get_bind_pose(i) -> Transform3D` | Inline getter for the inverse bind transform. |
| `set_bind_pose(i, pose: Transform3D)` | Sets `binds[i].pose`, calls `emit_changed()`. |
| `add_bind(bone: int, pose: Transform3D)` | Appends one indexed bind (`set_bind_count(n+1)` then `set_bind_bone` + `set_bind_pose`). |
| `add_named_bind(name: String, pose: Transform3D)` | Appends one named bind (`set_bind_count(n+1)` then `set_bind_name` + `set_bind_pose`). |
| `clear_binds()` | Empties the whole bind array, `bind_count = 0`, `emit_changed()`. **No "remove single bind" exists** — only whole-array operations. |

**Live-update note (important and not documented anywhere):** `Skeleton3D` keeps a
`SkinReference` per registered `Skin` and connects to the skin's `"changed"` signal
(`skin->connect_changed(callable_mp(skin_ref, &SkinReference::_skin_changed))`). That handler
sets `skeleton_version = 0`, which forces full bind re-resolution on the very next
`_update_skins()` pass (each `Skeleton3D` process frame). **This means calling
`skin.set_bind_name(i, "Hips")` on a live, already-assigned `Skin` is enough — Godot
re-resolves automatically; no need to re-assign the `Skin`, detach/reattach the mesh, or call
`register_skin()` again.**

### `MeshInstance3D`

- `skin: Skin` — "The Skin to be used by this instance." (`get_skin()`/`set_skin()`)
- `skeleton: NodePath` — "NodePath to the Skeleton3D associated with the instance."
  (`get_skeleton_path()`/`set_skeleton_path()`)
- **4.6-specific note (directly relevant — we're on 4.6.3):** the docs carry a fresh warning:
  > "The default value of this property has changed in Godot 4.6. Enable
  > `ProjectSettings.animation/compatibility/default_parent_skeleton_in_mesh_instance_3d`
  > if the old behavior is needed for compatibility."
  This explains why each override block in `quaternius_ragdoll.tscn` must set
  `skeleton = NodePath("../../../..")` explicitly — in 4.6 a `MeshInstance3D` no longer
  automatically resolves to its nearest ancestor `Skeleton3D` by default the way older
  versions did. (This is exactly what the existing `Male_Ranger_Body` override already does —
  consistent with what we found.)

### `Skeleton3D`

- `find_bone(name: String) const -> int` — "Returns the bone index that matches `name` as its
  name. Returns `-1` if no bone with this name exists."
- `get_bone_count() const -> int` — "Returns the number of bones in the skeleton."
- `get_bone_name(bone_idx: int) const -> String` — "Returns the name of the bone at index
  `bone_idx`."

### The exact resolution algorithm (read directly from `skeleton_3d.cpp`, `_notification`/`UPDATE_FLAG_POSE` branch, ~line 360-400)

This is the crux of the whole problem — and it is **not described anywhere in the docs**, so I
quote the logic structurally:

```
for each bind i in skin (0 .. bind_count-1):
    bind_name = skin.get_bind_name(i)
    if bind_name != "":                      # NAMED bind — always tried first
        search skeleton.bones[] linearly for bone.name == bind_name
        if found:    skin_bone_indices[i] = found_index
        else:        ERR_PRINT("Skin bind #i contains named bind '<name>' but
                                Skeleton3D has no bone by that name.")
                     skin_bone_indices[i] = 0          # <-- silent fallback to bone 0!
    elif skin.get_bind_bone(i) >= 0:          # INDEXED bind — only used if name is empty
        bind_index = skin.get_bind_bone(i)
        if bind_index >= skeleton.bone_count: ERR_PRINT(...); skin_bone_indices[i] = 0
        else: skin_bone_indices[i] = bind_index
    else:
        ERR_PRINT("Skin bind #i does not contain a name nor a bone index.")
        skin_bone_indices[i] = 0
```

Three findings fall directly out of this:

1. **Named binds are tried unconditionally and exclusively when `bind_name != ""`.** A
   non-empty name *always* wins over `bind_bone`, even if the name lookup fails — there is
   *no automatic fallback* from a failed name lookup to the index value. (This matters: you
   cannot "give it both and let Godot pick the one that works." If you want index-based
   resolution you must clear the name to `StringName()`.)
2. **A failed name lookup does not leave the bind unbound — it silently snaps to skeleton bone
   index 0** and only *prints* an error (it doesn't throw or skip the vertex). Given
   `GeneralSkeleton`'s bone order (Hips appears to be bone 0, based on it being the
   parentless root in a UE-Mannequin-style rig — **verify this in the editor**, see Test Plan),
   every unmapped bind currently collapses onto the pelvis's bind pose. That is almost
   certainly the actual cause of the "stuck in T-pose" symptom described — *not* that nothing
   binds, but that *every* bind (all of them are unmapped Mixamo names right now) is rigidly
   glued to bone 0's resting transform, so the whole mesh looks frozen/undeformed relative to
   the rest of the moving skeleton.
3. **Confirms exactly which mode the Male_Ranger skin is in:** the error text
   (`"Skin bind #0 contains named bind 'root'..."`) can *only* be emitted from the
   `bind_name != StringName()` branch — so these are unambiguously **named binds**, not
   indexed binds. (This is also expected: PR #36415, "Add support for named binds in Skin"
   by `reduz`, made named binds the *default* import behavior specifically "to ensure better
   skeleton reuse in files exported from [tools like Maya / Mixamo]" — Godot's glTF importer
   writes named binds for exactly this kind of asset.)

### How `ARRAY_BONES` ties into all this (the load-bearing fact for the "drop vs. keep" question)

I traced the consumption of `skin_bone_indices` a few lines further (lines ~403-406):

```cpp
for (uint32_t i = 0; i < bind_count; i++) {
    uint32_t bone_index = E->skin_bone_indices_ptrs[i];
    rs->skeleton_bone_set_transform(skeleton, i, bonesptr[bone_index].global_pose * skin->get_bind_pose(i));
}
```

`skeleton` here is a *lightweight render-server-side skeleton* sized to exactly `bind_count`
slots (`RS::skeleton_allocate_data(skeleton, bind_count)`), and slot `i` is written using the
*bind's* index `i`, not the resolved skeleton bone index. **This is the skeleton that the
mesh's per-vertex `ARRAY_BONES` data indexes into** (confirmed: this is the well-known
mechanism — the GPU skinning pass looks up `ARRAY_BONES[k] -> bind slot -> resolved skeleton
bone transform`). In other words:

> **`ARRAY_BONES` values in the mesh's vertex data are positional indices into the `Skin`'s
> bind array — *not* into `Skeleton3D`'s bone array.** The indirection through `Skin` is the
> entire point of the resource.

**Consequence:** the bind array's *length and order* are baked into the mesh's vertex buffers
at export/import time and must not change. `clear_binds()` + rebuild-with-fewer-binds, or any
`set_bind_count()` that shrinks/reorders, would desynchronize every vertex's
`ARRAY_BONES[0..3]` from the new bind-slot layout — vertices would silently bind to whatever
bone now occupies that slot number. This would be **far worse** than the current "stuck"
symptom: instead of a uniformly frozen mesh you'd get vertices scattered onto random unrelated
bones, varying per outfit piece depending on how many binds happened to be removed before each
vertex's referenced slot. This finding directly answers design question 2 below.

---

## 2. Findings from web research

- **[Skin — Godot 4.6 class docs](https://docs.godotengine.org/en/stable/classes/class_skin.html)**
  and **[MeshInstance3D — Godot 4.6 class docs](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html)**
  and **[Skeleton3D — Godot 4.6 class docs](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html)**
  — primary API references; `Skin` itself is essentially undocumented prose-wise (every method
  says "There is currently no description"), confirming this is a low-traffic corner of the
  engine that requires reading source to use correctly.
- **[skeleton_3d.cpp (master)](https://github.com/godotengine/godot/blob/master/scene/3d/skeleton_3d.cpp)**
  and **[skin.cpp (master)](https://github.com/godotengine/godot/blob/master/scene/resources/3d/skin.cpp)**
  — ground truth for the resolution algorithm and bind-mutation semantics described above.
  This logic has been stable for years (the named-bind mechanism dates to 2020's PR #36415)
  and is extremely unlikely to differ in 4.6.3.
- **[PR #36415 "Add support for named binds in Skin" by reduz](https://github.com/godotengine/godot/pull/36415)**
  — the origin of named-bind support; explains *why* glTF imports default to named binds
  ("ensures better skeleton reuse in files exported from Maya" — i.e. so the same mesh can be
  reattached to a restructured/renamed skeleton, *exactly* our use case, just usually solved by
  matching names rather than runtime-rewriting them).
- **[Issue #106073 — model importer renames skeleton bones, breaking retargeting/BoneMap](https://github.com/godotengine/godot/issues/106073)**
  — confirms 4.3+ has known instability around multi-skeleton bone naming during import
  (Godot treats all bones in one glTF file as one namespace and silently appends `_2` suffixes
  on collisions). Not our exact bug, but useful context: bone-name mismatches between
  source-asset skeletons and target skeletons are a recognized pain point in current Godot, not
  a one-off mistake on this project's part.
- **[BoneMap class docs](https://docs.godotengine.org/en/stable/classes/class_bonemap.html)**
  — `BoneMap` (the resource produced by the "Rename Bones" + `SkeletonProfileHumanoid` import
  path the user already used for `Male_Ranger.gltf`) exposes exactly the lookup table we need,
  *as data Godot already generated*:
  - `find_profile_bone_name(skeleton_bone_name) -> StringName` — given a *source-rig* name
    (e.g. `"pelvis"`), returns the Humanoid *profile* name (`"Hips"`), or `""` if there's no
    mapping.
  - `get_skeleton_bone_name(profile_bone_name) -> StringName` — the inverse lookup.
  This is **the same table the user already hand-built** (confirmed identical for the 20
  entries given), just sitting inside the asset's own import metadata
  (`<gltf>.gltf.import` → `_subresources/nodes/.../retarget/bone_map`). It's a candidate
  *source of truth* (see §3 open question on whether to use it instead of a hand-rolled dict).
- **[Quaternius Humanoid Ragdoll Setup Walkthrough (Godot Forum)](https://forum.godotengine.org/t/quaternius-humanoid-ragdoll-setup-walkthrough/133301)**
  — directly on-topic forum thread for this exact rig family; covers PhysicalBone setup but
  **does not** cover modular-outfit attachment or bone-name remapping — confirms there's no
  ready-made community solution to crib from for this specific step.
- **["Bind clothing mesh to a parent character skin/rig" gist](https://gist.github.com/gekidoslair/e8512f7a834c8bf46ce5d30c8ddc410e)**
  — closest prior art found, but it's **C# for Unity** (`SkinnedMeshRenderer.bones`), not
  applicable to Godot's `Skin` resource model. Conceptually validates the general strategy
  though: build a `name -> index/transform` lookup from the target rig and rewrite the
  clothing mesh's bone references by *name match* — i.e. the same rename-by-name approach this
  doc recommends, just implemented against a different engine's API.
- **[3D RPG clothing/inventory tutorial (Godot Forum)](https://forum.godotengine.org/t/3d-rpg-clothing-and-inventory-system-using-godot-4-and-blender/114842)**
  — sidesteps the whole problem by requiring all clothing to be authored against the *same*
  rig in Blender before export, so bone names always match. Good practice for new asset
  pipelines, useless for retrofitting purchased Quaternius assets that ship with Mixamo rigs.

**Bottom line from research:** there is no out-of-the-box Godot feature or community script
that remaps a `Skin`'s bind names at runtime/import for mismatched-skeleton mesh attachment.
The mechanism (`set_bind_name` + automatic re-resolution via the `"changed"` signal) is fully
exposed and works, but using it this way is undocumented and apparently uncommon — we'd be
writing the first clean implementation of a known-but-unsolved pattern for this asset family.

---

## 3. Recommended approach

### Import-time vs. runtime: **runtime, in `_ready()` (or an exported tool function), not an import script**

Reasons:
- An `EditorScenePostImport` script runs *once*, at import, and rewrites the *cached* imported
  scene. That means: (a) it would need to run on **all 8** outfit `.gltf` files (or be made
  generic enough to detect "this is a Quaternius modular outfit" automatically), (b) any
  re-import (asset update, Godot version bump, accidental "Reimport") silently re-applies or
  loses the rewrite depending on how it's wired, and (c) it permanently mutates the imported
  resource on disk in `.godot/imported/`, making the fix invisible from the scene tree —
  harder to debug, harder to reason about, and the kind of "magic" CLAUDE.md explicitly asks
  to avoid ("Prefer the simpler Godot-native solution over a clever custom one").
- A runtime remap is **localized, visible, debuggable, idempotent, and reversible**: it's a
  small function that runs against the live `Skin` instances already sitting on the
  `MeshInstance3D` overrides we just wrote into `quaternius_ragdoll.tscn`. Toggle it off, and
  you're back to the unmodified asset — nothing on disk changes. Given that `set_bind_name`
  triggers automatic re-resolution (see §1 live-update note), this is also *cheap*: rename in
  `_ready()`, Godot does the rest on the next skeleton update pass.
- It also generalizes trivially: the same function, parameterized by the outfit's root node,
  can run for all 8 pieces (and any future Quaternius outfit) without touching import settings
  per-asset.

### Drop vs. keep unmapped binds (root, fingers, toes): **keep — remap to nearest mapped ancestor, never delete**

As established in §1, **the bind array's length and order is physically encoded in the mesh's
vertex buffers** (`ARRAY_BONES` indices are positional bind-slot indices). Dropping binds is
not a "smaller" version of the fix — it's a *different and much more dangerous* operation that
would require rebuilding the mesh's vertex arrays in lockstep, which is an entirely different
(and far more invasive) project than a name remap. **Binds must stay exactly where they are.**

So "drop or keep" really resolves to: *what name do we give a bind that has no Humanoid
counterpart?* Three options, evaluated:

1. **Leave it as the original Mixamo name (do nothing).** Keeps producing the
   `ERR_PRINT` spam every frame skeleton_version changes, and — per the resolution algorithm —
   silently snaps that bind to skeleton bone index 0 (`Hips`, to be verified). Functionally
   "works" (no crash) but noisy and visually wrong for any vertex weighted to fingers/toes/root
   (they'd render rigidly glued to the pelvis).
2. **Remap to the nearest mapped ancestor in the source skeleton's bone hierarchy.** E.g.
   `index_01_l` / `thumb_0x_l` / etc. → walk up the hierarchy (`index_01_l` → `hand_l` →
   *mapped* → `LeftHand`); `ball_l` / `ball_leaf_l` → `foot_l` → `LeftFoot`; `root` → walk up
   to `pelvis` → `Hips` (or to `GeneralSkeleton`'s actual root bone — verify name). This is
   the standard humanoid-retargeting convention (it's literally what Unity/VRM/Mixamo do for
   "extra" bones with no Humanoid slot — they get folded into their nearest mapped parent) and
   produces *plausible* deformation: fingers move with the hand, toes move with the foot,
   pelvis-region extras move with the hips. **Recommended.**
3. **Remap everything unmapped to a single fallback (e.g. all → `Hips`).** Simpler to write,
   but produces worse results than (2) for no implementation savings — walking the parent
   chain is a ~10-line loop we need for correctness anyway (see pseudocode).

**Recommendation: option 2.** It eliminates the console spam, avoids the silent-bone-0 fallback
entirely (every bind resolves successfully), and gives the most visually correct result without
materially increasing implementation complexity over option 3.

### Bind mode and `bind_bone`/`bind_name` interplay — direct answers to the questions posed

- **Which mode are these binds in?** Named (`bind_name` is set, non-empty) — proven by the
  exact error string format, which only the named-bind branch can emit. `bind_bone` is very
  likely also populated (Godot's glTF importer typically fills both — `bind_bone` as the
  original mesh-author's index, `bind_name` as the portable identifier) but it is **completely
  ignored by the resolver whenever `bind_name != ""`**.
- **Does Godot resolve via name when assigned to a different skeleton?** Yes — and *only* via
  name, with no index fallback, whenever a name is present (see algorithm in §1). This is
  actually good news for us: it means **renaming `bind_name` in place is the complete fix** —
  we don't need to touch `bind_bone` at all. (We could optionally also call
  `set_bind_bone(i, new_skeleton.find_bone(new_name))` to keep the two fields consistent for
  hygiene/future-proofing, but it's provably inert as long as `bind_name` stays non-empty.)

---

## 4. Pseudocode for the core remap logic

```
# Conceptual outline — NOT final code. To be reviewed before implementation.

const MIXAMO_TO_HUMANOID := {
    "pelvis": "Hips", "spine_01": "Spine", "spine_02": "Chest", "spine_03": "UpperChest",
    "neck_01": "Neck", "Head": "Head",
    "clavicle_l": "LeftShoulder", "upperarm_l": "LeftUpperArm", "lowerarm_l": "LeftLowerArm", "hand_l": "LeftHand",
    "clavicle_r": "RightShoulder", "upperarm_r": "RightUpperArm", "lowerarm_r": "RightLowerArm", "hand_r": "RightHand",
    "thigh_l": "LeftUpperLeg", "calf_l": "LeftLowerLeg", "foot_l": "LeftFoot",
    "thigh_r": "RightUpperLeg", "calf_r": "RightLowerLeg", "foot_r": "RightFoot",
}
# NOT in the table: "root", and all finger_*/thumb_*/index_*/middle_*/ring_*/pinky_*_{l,r}
# and ball_{l,r} / ball_leaf_{l,r} — these need ancestor fallback.

func remap_skin_to_humanoid(mesh_instance: MeshInstance3D, source_parent_map: Dictionary) -> void:
    # source_parent_map: { mixamo_bone_name: parent_mixamo_bone_name, ... }
    # Built once from the SOURCE skeleton (Male_Ranger's own Skeleton3D, still reachable via
    # the editable instance before/while we rewrite names — see Open Questions, this is the
    # part that needs validating hands-on) so we can walk "up" from an unmapped bone to find
    # the nearest ancestor that *is* in MIXAMO_TO_HUMANOID.

    var skin := mesh_instance.skin
    assert(skin != null)

    var resolved_cache := {}   # memoize ancestor walks; multiple fingers share `hand_l`, etc.

    for i in skin.get_bind_count():
        var original_name := String(skin.get_bind_name(i))
        if original_name == "":
            continue   # indexed bind, or empty — leave untouched (shouldn't occur per the errors seen)

        var target_name : String = MIXAMO_TO_HUMANOID.get(original_name, "")

        if target_name == "":
            # Unmapped — walk parent chain until we hit a mapped name.
            if resolved_cache.has(original_name):
                target_name = resolved_cache[original_name]
            else:
                var walk := original_name
                var guard := 0
                while target_name == "" and source_parent_map.has(walk) and guard < 64:
                    walk = source_parent_map[walk]
                    target_name = MIXAMO_TO_HUMANOID.get(walk, "")
                    guard += 1
                # If we somehow walk off the top without a match (shouldn't happen — "root"
                # walks straight to "pelvis" -> "Hips"), leave target_name == "" and skip,
                # logging a warning rather than writing an empty bind name (which would
                # silently degrade to the index-bind branch with bind_bone likely == -1,
                # i.e. the "does not contain a name nor a bone index" error).
                resolved_cache[original_name] = target_name

        if target_name != "":
            skin.set_bind_name(i, target_name)
        else:
            push_warning("No mapped ancestor found for bind '%s' (#%d) on %s — leaving as-is"
                         % [original_name, i, mesh_instance.name])

    # No need to re-assign mesh_instance.skin or touch .skeleton — `set_bind_name` fires
    # `Skin.changed`, `SkinReference._skin_changed()` resets `skeleton_version`, and the
    # *existing* binding is re-resolved automatically on the Skeleton3D's next update pass.
```

Key properties of this approach worth calling out:
- **Bind count and order are never touched** — only `bind_name` strings change, in place.
- **Idempotent** — running it twice is harmless: on the second pass, `original_name` is
  already a Humanoid name, `MIXAMO_TO_HUMANOID.get(...)` returns `""` (Humanoid names aren't
  keys), it'd fall into ancestor-walk... which is why the *real* implementation should
  probably guard with `if skeleton.find_bone(original_name) != -1: continue` first (i.e. "if
  this name already resolves against the target skeleton, don't touch it"). That single check
  also sidesteps needing `source_parent_map` correctness for the 20 already-mapped bones —
  only the ~9 unmapped categories ever need the ancestor walk. **This refinement should be
  folded into the real implementation.**
- **`source_parent_map` is the one new thing we need to build** that the user's hand-written
  table doesn't give us — it requires walking `Male_Ranger`'s *own* (post-import,
  Humanoid-renamed-but-still-separate) `Skeleton3D` via `get_bone_parent(idx)` /
  `get_bone_name(idx)` — or, more robustly, reading it straight from the source `.gltf` JSON
  the way this conversation already did for the bind-name list (the glTF `nodes[].children`
  hierarchy under `Armature` gives us the canonical Mixamo parent-child chain directly, with
  zero ambiguity about what Godot's importer may have renamed).

---

## 5. Open questions / risks

1. **Where does `source_parent_map` actually come from, concretely?** Two candidates:
   - (a) Parse it from `Male_Ranger.gltf`'s `nodes[]` array (as already done in this
     conversation to enumerate the 65 joints) — fully static, no editor/runtime dependency,
     trivially testable in isolation, but means embedding a second hand-derived table
     (bone → parent) alongside the existing bone → Humanoid table.
   - (b) Read it from the *live* `Skeleton3D` inside the instanced `Male_Ranger` node at
     runtime via `get_bone_parent()`/`get_bone_name()` — zero extra static data, always in
     sync with whatever the importer actually produced, but only works if that skeleton's
     bones *still carry the original Mixamo names* at the point we read them (the import used
     `Rename Bones=On`, so they may already be Humanoid-renamed *on that skeleton* too — in
     which case its parent-chain names won't match `MIXAMO_TO_HUMANOID`'s keys at all, and
     this whole approach (b) collapses).
   - **This is the single biggest unresolved question and should be the first thing checked
     hands-on** (see Test Plan step 1) — it determines whether we need a second static table
     or can derive everything from the live scene. Given the ambiguity, I'd lean toward (a) —
     it's slower to write but has zero runtime surprises, and the parent-chain for ~9 bone
     *families* (not 65 individual bones — siblings like all 4 finger chains collapse to the
     same `hand_l` ancestor) is a small, stable, one-time addition.

2. **Is skeleton bone index 0 really `Hips`?** The "silent fallback to index 0" behavior
   matters for understanding *why* the mesh currently looks the way it does, and for judging
   how bad option-1 ("do nothing about unmapped binds") would look in practice. Cheap to check
   in the Remote/Debugger inspector or via `general_skeleton.get_bone_name(0)`.

3. **Does `Male_Ranger`'s *own* `Skeleton3D` (the one inside the instanced sub-scene, before
   our override re-points `skeleton` at `GeneralSkeleton`) still exist and remain queryable
   after the override is active?** The `[editable path="...Male_Ranger"]` line exposes it in
   the editor; at runtime the node should still be present in the tree (we only changed where
   the *mesh* looks for its skeleton, not the scene structure) — but this needs confirming,
   because if it's been pruned/hidden, candidate (a)/(b) above both need adjusting (fall back
   to parsing the `.gltf` resource directly, which we can always do).

4. **`SkeletonProfileHumanoid` may already define canonical finger-bone slots** (Unity/VRM
   Humanoid avatars include `LeftThumbProximal`, `LeftIndexProximal`, etc.). The user's
   statement that "finger and toe bones have no equivalents" should be re-verified against
   `GeneralSkeleton` directly — if `GeneralSkeleton` *does* contain finger bones (just not
   referenced by any `PhysicalBone3D`, which is all we inspected so far), a richer mapping
   becomes possible and preferable to the ancestor-fallback for those bones specifically. This
   doesn't change the recommended *mechanism* (still rename-in-place via `set_bind_name`), only
   the completeness of `MIXAMO_TO_HUMANOID`.

5. **`BoneMap` as an alternative source of truth (§2):** `Male_Ranger.gltf.import` likely
   contains a generated `BoneMap` resource (from the `Rename Bones` + `SkeletonProfileHumanoid`
   import path) that already encodes the 20-entry mapping as engine data, queryable via
   `find_profile_bone_name()`/`get_skeleton_bone_name()`. Loading it at runtime would remove
   the need to hand-maintain `MIXAMO_TO_HUMANOID` at all — but it's unclear (without checking)
   whether it's saved as an addressable external resource (`res://...bone_map.tres`) or only as
   inline `.import` metadata invisible to runtime code. **Worth a 5-minute check before
   committing to the hand-written dict** — if it's loadable, it's strictly better (one fewer
   hand-maintained data structure, automatically correct if the import is ever redone).

6. **Performance / timing:** `set_bind_name` is called up to ~65 times per mesh × 9 meshes ≈
   600 calls total, each doing a linear bone-name search inside `Skeleton3D::_update_skins()`
   on the *next* update — utterly negligible, one-time cost at scene `_ready()`. Not a real
   risk, noting only to rule it out explicitly.

7. **Risk of silently "fixing" a different underlying problem:** if it later turns out
   `GeneralSkeleton`'s bone *order* doesn't match what `PhysicalBoneSimulator3D` /
   `PhysicalBone3D.bone_name` expects (a different class of mismatch than the one this doc
   addresses), this remap would make meshes deform correctly while the *physics* skeleton
   remains subtly wrong — two independent bugs that could be mistaken for one. Out of scope
   here, but worth keeping in mind when validating (the Test Plan's step 4 — running the
   ragdoll — exercises exactly this seam).

---

## 6. Test plan — validate on one piece before scaling to all 8

Goal: prove the mechanism on `Male_Ranger_Body` (the override block that already exists, is
already wired to `GeneralSkeleton`, and is the simplest/most-central piece — easiest to eyeball
for correctness) before generalizing to the other 8.

1. **Inspect `GeneralSkeleton` directly in the running scene** (Remote tab in the Scene dock,
   or a throwaway `print` in `_ready()`):
   - `get_bone_count()`, and `get_bone_name(i)` for `i` in range — confirm the full bone list
     (does it include fingers/toes? what's bone 0?).
   - `find_bone("Hips")`, `find_bone("LeftThumbProximal")` etc. — resolves open question 2 & 4
     in one pass.
2. **Inspect `Male_Ranger`'s own `Skeleton3D`** the same way — resolves open question 1: are
   its bone names still Mixamo-style (`pelvis`, …) at runtime, or already Humanoid-renamed?
   This single check decides between approach (a) and (b) for `source_parent_map`.
3. **Dump `Male_Ranger_Body`'s skin before any change:** for `i in skin.get_bind_count()`,
   print `i, skin.get_bind_name(i), skin.get_bind_bone(i)`. Cross-check against the 65-joint
   list already extracted from the `.gltf` (this conversation has it) — confirms bind order ==
   `.gltf` joint order (it should, but "should" isn't "is").
4. **Apply the remap to `Male_Ranger_Body` only**, then visually verify in the running game:
   - Console: the `Skin bind #N contains named bind ... no bone by that name` errors for
     *this* mesh disappear entirely (a clean, objective pass/fail signal).
   - Visual: trigger the ragdoll (`physical_bones_start_simulation()`craft a debug key, or
     just observe normal animation) and confirm the body mesh now deforms/follows the
     skeleton — no longer frozen — and that the deformation looks anatomically correct (no
     limbs stretching to the wrong place, no inside-out geometry).
   - Re-dump the skin (step 3's printout) to confirm bind *count* and *order* are bit-for-bit
     identical, only `bind_name` strings changed — the canary for the §1/§5 "never reorder"
     invariant.
5. **Only after (4) passes cleanly**, run the same function across all 9 mesh overrides
   (`Male_Ranger_Body` + the 8 we just added) in one pass, and repeat the console-error and
   visual checks for each piece — paying particular attention to the pieces most likely to
   carry finger/toe weight painting (`Male_Ranger_Arms_Bracer`, `Male_Ranger_Feet_Boots`,
   `Male_Ranger_Head_Hood` — gloves/boots/hood are exactly where extremity bones matter most).
6. **Regression check:** confirm the *un-modified* parts of the scene still work — specifically
   that `GeneralSkeleton`'s animation playback and `PhysicalBoneSimulator3D` ragdoll behavior
   (per CLAUDE.md's "Known Issues" section, this is an area with pre-existing engine quirks)
   are unaffected. We're only mutating `Skin` resources owned by the outfit meshes; nothing
   here should touch the skeleton or physical bones — but "should" gets verified, not assumed.

**What "done" looks like:** zero `Skin bind ... no bone by that name` console errors at
runtime, all 9 outfit-mesh pieces visibly deforming in sync with `GeneralSkeleton` during both
normal animation and ragdoll simulation, and a before/after bind dump showing identical
count+order with only renamed strings.

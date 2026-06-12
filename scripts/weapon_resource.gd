extends Resource
class_name WeaponResource

@export_group("Identity")
@export var weapon_name: String = ""

@export_group("Mesh")
# Sourced from OBJ imports (assets/weapons/OBJ/*.obj -> Mesh). Assigned in .tres.
@export var mesh: Mesh = null

@export_group("Stats")
# reach feeds the data-driven hitbox size and is the axis WeaponEnchantment.length_multiplier scales.
@export var reach: float = 1.0
@export var damage: float = 10.0
# seconds; tuning/reference value -- not yet driving animation playback rate.
@export var swing_duration: float = 0.5
@export var stamina_cost: float = 10.0
# multiplier on extracted root motion for this weapon's attacks.
@export var root_motion_intensity: float = 1.0

@export_group("Animation Set")
# Ordered combo. Each entry: { "swing": String, "recovery": String }
# Strings are AnimationTree node names (e.g. "Sword_Regular_A" / "Sword_Regular_A_Rec").
# Empty "recovery" means no recovery clip (finisher).
# Held as data this session; not yet driving dynamic AnimationTree construction.
@export var combo_steps: Array[ComboStep] = []

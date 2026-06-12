extends Resource
class_name EnemyArchetype

@export_group("Identity")
@export var display_name: String = ""

@export_group("Stats")
@export var max_health: float = 80.0
@export var move_speed: float = 3.5
@export var attack_damage: float = 12.0

@export_group("Detection")
@export var aggro_range: float = 12.0
@export var attack_range: float = 2.0

@export_group("Attack")
@export var attack_interval: float = 2.0

@export_group("Stagger")
@export var stagger_duration: float = 1.2
@export var stagger_damage_mult: float = 2.0

@export_group("Weapon")
@export var equipped_weapon: WeaponResource = null

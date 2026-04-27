extends Resource
class_name EnemyData

@export var enemy_id: int = 0
@export var name: String = "Противник"
@export var icon: Texture2D = null
@export var icon_text: String = "👾"
@export var health: int = 100
@export var power: int = 15
@export var damage: int = 10
@export var armor: int = 3
@export var attack_speed: float = 1.0
@export var reward_materials: int = 10
@export var reward_food: int = 5
@export var reward_water: int = 5
@export var danger_level: int = 1
@export var description: String = ""
@export var enemy_type: String = "normal"  # normal, elite, boss, general

func get_power() -> int:
	return power

func get_total_health() -> int:
	return health

func duplicate_enemy() -> EnemyData:
	var copy = EnemyData.new()
	copy.enemy_id = enemy_id
	copy.name = name
	copy.icon = icon
	copy.icon_text = icon_text
	copy.health = health
	copy.power = power
	copy.damage = damage
	copy.armor = armor
	copy.attack_speed = attack_speed
	copy.reward_materials = reward_materials
	copy.reward_food = reward_food
	copy.reward_water = reward_water
	copy.danger_level = danger_level
	copy.description = description
	copy.enemy_type = enemy_type
	return copy

extends Resource
class_name EnemyGroupData

@export var group_id: int = 0
@export var group_name: String = "Отряд противников"
@export var group_icon_text: String = "👥"
@export var group_description: String = ""
@export var total_reward_materials: int = 0
@export var total_reward_food: int = 0
@export var total_reward_water: int = 0
@export var danger_level: int = 1

# Генерал отряда (обязательный)
@export var general_name: String = "Генерал"
@export var general_portrait: Texture2D = null
@export var general_icon_text: String = "👑"
@export var general_health: int = 200
@export var general_power: int = 50
@export var general_damage: int = 25
@export var general_armor: int = 10
@export var general_attack_speed: float = 1.2
@export var general_description: String = "Могучий генерал"

# Состав отряда
@export var enemies_in_group: Dictionary = {}

# Удобные поля для редактирования
@export var enemy_type_1: String = ""
@export var number_enemy_type_1: int = 0
@export var enemy_type_2: String = ""
@export var number_enemy_type_2: int = 0
@export var enemy_type_3: String = ""
@export var number_enemy_type_3: int = 0
@export var enemy_type_4: String = ""
@export var number_enemy_type_4: int = 0
@export var enemy_type_5: String = ""
@export var number_enemy_type_5: int = 0

func _init():
	enemies_in_group = {}

func _ready():
	build_enemies_dict()

func build_enemies_dict():
	enemies_in_group.clear()
	
	if enemy_type_1 != "" and number_enemy_type_1 > 0:
		enemies_in_group[enemy_type_1] = number_enemy_type_1
	if enemy_type_2 != "" and number_enemy_type_2 > 0:
		enemies_in_group[enemy_type_2] = number_enemy_type_2
	if enemy_type_3 != "" and number_enemy_type_3 > 0:
		enemies_in_group[enemy_type_3] = number_enemy_type_3
	if enemy_type_4 != "" and number_enemy_type_4 > 0:
		enemies_in_group[enemy_type_4] = number_enemy_type_4
	if enemy_type_5 != "" and number_enemy_type_5 > 0:
		enemies_in_group[enemy_type_5] = number_enemy_type_5

func get_total_enemies_count() -> int:
	var total = 1
	for count in enemies_in_group.values():
		total += count
	return total

func create_general() -> EnemyData:
	var general = EnemyData.new()
	general.enemy_id = -group_id
	general.name = general_name
	general.icon = general_portrait
	general.icon_text = general_icon_text
	general.health = general_health
	general.power = general_power
	general.damage = general_damage
	general.armor = general_armor
	general.attack_speed = general_attack_speed
	general.reward_materials = 0
	general.reward_food = 0
	general.reward_water = 0
	general.danger_level = danger_level
	general.description = general_description
	general.enemy_type = "general"
	return general

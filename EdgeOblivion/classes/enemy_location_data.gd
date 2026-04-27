extends Resource
class_name LocationEnemyData

@export var enemy_id: int = 0
@export var enemy_group: EnemyGroupData = null  # Ссылка на ресурс группы врагов
@export var level: int = 1
@export var respawn_time: float = 300.0  # Время возрождения в секундах
@export var is_defeated: bool = false
@export var reward_multiplier: float = 1.0  # Множитель награды
@export var spawn_chance: float = 1.0  # Шанс появления (0-1)

# Тип врага с выпадающим списком
@export_enum("normal", "elite", "boss", "general") var enemy_rank: String = "normal"

func get_enemy_group() -> EnemyGroupData:
	return enemy_group

func get_group_name() -> String:
	if enemy_group:
		return enemy_group.group_name
	return "Неизвестный враг"

func get_group_description() -> String:
	if enemy_group:
		return enemy_group.group_description
	return ""

func get_group_icon() -> String:
	if enemy_group:
		return enemy_group.group_icon_text
	return "👾"

func get_total_reward() -> Dictionary:
	if enemy_group:
		return {
			"materials": enemy_group.total_reward_materials,
			"food": enemy_group.total_reward_food,
			"water": enemy_group.total_reward_water
		}
	return {"materials": 0, "food": 0, "water": 0}

func is_available() -> bool:
	return not is_defeated and randf() <= spawn_chance
	

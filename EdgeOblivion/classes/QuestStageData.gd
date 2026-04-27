extends Resource
class_name QuestStageData

@export var stage_id: int = 0
@export var stage_name: String = "Этап квеста"
@export var stage_description: String = "Описание этапа"

# Тип этапа с выпадающим списком
@export_enum("collect", "kill", "talk", "survive") var stage_type: String = "collect"
@export var stage_target: int = 1
@export var stage_current: int = 0

# NPC для этого этапа
@export var spawn_npcs: Array[int] = []  # NPC, которые появляются на этом этапе
@export var despawn_npcs: Array[int] = []  # NPC, которые исчезают на этом этапе

# Диалоги для этапа
@export var dialogue_on_start: Dictionary = {}  # {"dialog_resource": "path", "dialog_branch": "BRANCH"}
@export var dialogue_on_complete: Dictionary = {}

# Награды за этап
@export var stage_reward_food: int = 0
@export var stage_reward_water: int = 0
@export var stage_reward_materials: int = 0

func is_complete() -> bool:
	return stage_current >= stage_target

func update_progress(amount: int = 1):
	stage_current += amount
	if stage_current > stage_target:
		stage_current = stage_target

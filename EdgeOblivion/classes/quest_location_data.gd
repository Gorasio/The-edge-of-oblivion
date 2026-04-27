extends Resource
class_name LocationQuestData

@export var quest_id: int = 0
@export var quest_name: String = "Новый квест"
@export var quest_description: String = "Описание квеста"

# Тип квеста с выпадающим списком
@export_enum("collect", "kill", "survive", "upgrade", "talk", "reach_level", "reach_power") var quest_type: String = "collect"

# Награды
@export var reward_food: int = 0
@export var reward_water: int = 0
@export var reward_materials: int = 0
@export var reward_experience: int = 0

# Условия активации
@export var is_available: bool = true
@export var required_quest_id: int = -1
@export var required_level: int = 1
@export var required_reputation: int = 0
@export var auto_activate: bool = true

# Цели квеста
@export var target_value: int = 1
@export_enum("food", "water", "materials", "enemies", "days", "upgrades", "survivors", "locations", "level", "power") var target_type: String = "food"
@export var current_value: int = 0
@export var current_stage: int = 0

# Этапы квеста
@export var stages: Array[QuestStageData] = []

# NPC, связанные с квестом
@export var npc_on_start: Array[int] = []
@export var npc_on_complete: Array[int] = []
@export var npc_on_stage: Dictionary = {}

# Диалоги
@export var dialogue_on_start: Dictionary = {}
@export var dialogue_on_complete: Dictionary = {}
@export var dialogue_on_stage: Dictionary = {}

# Состояние
@export var is_active: bool = false
@export var is_completed: bool = false
@export var next_quest_id: int = -1

func get_progress_percent() -> float:
	if target_value <= 0:
		return 0.0
	return float(current_value) / float(target_value) * 100.0

func get_progress_text() -> String:
	return "%d/%d" % [current_value, target_value]

func check_completion() -> bool:
	if is_completed:
		return false
	
	var completed = current_value >= target_value
	if completed:
		is_completed = true
	return completed

func advance_stage():
	current_stage += 1

func get_current_stage_data() -> QuestStageData:
	if current_stage < stages.size():
		return stages[current_stage]
	return null

func get_npc_ids_for_current_stage() -> Array[int]:
	var npc_ids = []
	if npc_on_stage.has(current_stage):
		npc_ids.append_array(npc_on_stage[current_stage])
	return npc_ids

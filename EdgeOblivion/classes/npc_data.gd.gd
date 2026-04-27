extends Resource
class_name NPCData

# Базовые параметры
@export var npc_id: int = 0
@export var npc_name: String = "NPC"
@export var npc_portrait: Texture2D = null
@export var npc_description: String = ""

# Группа диалогов
@export var dialogues: Dictionary = {}

# Условия появления (выпадающий список)
@export_enum("always", "quest_not_taken", "quest_active", "quest_completed", "quest_stage", "never") var spawn_condition: String = "always"
@export var spawn_quest_id: int = -1
@export var spawn_quest_stage: int = 0

# Условия исчезновения (выпадающий список)
@export_enum("never", "quest_taken", "quest_active", "quest_completed", "quest_stage", "always") var despawn_condition: String = "never"
@export var despawn_quest_id: int = -1
@export var despawn_quest_stage: int = 0

# Квест, который выдает NPC
@export var gives_quest_id: int = -1
@export var gives_quest_on_dialogue: bool = true

# Награда после диалога
@export var reward_on_dialogue: Dictionary = {}

# Тип NPC (выпадающий список)
@export_enum("friendly", "neutral", "hostile", "merchant", "quest_giver") var npc_type: String = "friendly"

func should_spawn(quest_system) -> bool:
	match spawn_condition:
		"always":
			return true
		"never":
			return false
		"quest_not_taken":
			return not quest_system.is_quest_active(spawn_quest_id)
		"quest_active":
			return quest_system.is_quest_active(spawn_quest_id)
		"quest_completed":
			return quest_system.is_quest_completed(spawn_quest_id)
		"quest_stage":
			return quest_system.get_quest_stage(spawn_quest_id) == spawn_quest_stage
	return true

func should_despawn(quest_system) -> bool:
	match despawn_condition:
		"never":
			return false
		"always":
			return true
		"quest_taken":
			return quest_system.is_quest_active(despawn_quest_id)
		"quest_active":
			return quest_system.is_quest_active(despawn_quest_id)
		"quest_completed":
			return quest_system.is_quest_completed(despawn_quest_id)
		"quest_stage":
			return quest_system.get_quest_stage(despawn_quest_id) == despawn_quest_stage
	return false

func get_dialog_for_condition(quest_system) -> Dictionary:
	for condition in dialogues.keys():
		var dialog_info = dialogues[condition]
		if check_condition(condition, quest_system):
			return dialog_info
	return {}

func check_condition(condition: String, quest_system) -> bool:
	var parts = condition.split("|")
	var cond_type = parts[0]
	
	match cond_type:
		"always":
			return true
		"quest_not_taken":
			var quest_id = int(parts[1])
			return not quest_system.is_quest_active(quest_id)
		"quest_active":
			var quest_id = int(parts[1])
			return quest_system.is_quest_active(quest_id)
		"quest_completed":
			var quest_id = int(parts[1])
			return quest_system.is_quest_completed(quest_id)
		"quest_stage":
			var quest_id = int(parts[1])
			var stage = int(parts[2])
			return quest_system.get_quest_stage(quest_id) == stage
	return false

func get_active_quest_id(quest_system) -> int:
	if gives_quest_id != -1 and gives_quest_on_dialogue:
		return gives_quest_id
	return -1

extends Resource
class_name DialogueData

@export var dialogue_id: int = 0
@export var npc_name: String = "NPC"
@export var npc_portrait: Texture2D = null
@export var dialogue_lines: Array[String] = []
@export var quest_on_complete: int = -1  # ID квеста, который выдается после диалога
@export var reward_on_complete: Dictionary = {}  # Награда после диалога

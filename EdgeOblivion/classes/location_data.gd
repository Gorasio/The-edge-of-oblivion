extends Resource
class_name LocationData

@export var location_id: int = 0
@export var location_name: String = "Новая локация"
@export var location_description: String = "Описание локации"
@export var icon_text: String = "🏔️"
@export var icon: Texture2D = null
@export var background_color: Color = Color(0.2, 0.3, 0.2, 1)
@export var is_unlocked: bool = true
@export var required_level: int = 1
@export var required_quest_id: int = -1

# Тип локации (выпадающий список)
@export_enum("forest", "water", "mountain", "desert", "city", "dungeon") var location_type: String = "forest"

# Сложность локации (выпадающий список)
@export_enum("easy", "normal", "hard", "expert", "nightmare") var difficulty: String = "normal"

# Квесты в локации
@export var quests_at_location: Array[LocationQuestData] = []

# Враги в локации
@export var enemies_at_location: Array[LocationEnemyData] = []

# NPC в локации
@export var npc_at_location: Array[NPCData] = []

func get_available_quests() -> Array[LocationQuestData]:
	var available: Array[LocationQuestData] = []
	for quest in quests_at_location:
		if quest.is_available:
			available.append(quest)
	return available

func get_active_enemies() -> Array[LocationEnemyData]:
	var active: Array[LocationEnemyData] = []
	for enemy in enemies_at_location:
		if not enemy.is_defeated:
			active.append(enemy)
	return active

func get_npc_by_id(npc_id: int) -> NPCData:
	for npc in npc_at_location:
		if npc.npc_id == npc_id:
			return npc
	return null

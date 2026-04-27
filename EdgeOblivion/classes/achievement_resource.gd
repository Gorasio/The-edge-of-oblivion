extends Resource
class_name AchievementResource

@export var achievement_id: int = 0
@export var title: String = "Название достижения"
@export var description: String = "Описание достижения"
@export var icon_left: Texture2D = null  # Левая иконка (большая)
@export var icon_right: Texture2D = null  # Правая иконка (маленькая)
@export var icon_text_left: String = "🏆"  # Текстовая иконка слева
@export var icon_text_right: String = ""   # Текстовая иконка справа
@export var achievement_type: String = "food_reached"  # food_reached, water_reached, days_survived, materials_reached, upgrades_bought, survivors_found
@export var goal: float = 10.0
@export var reward_multiplier: float = 1.1
@export var is_achieved: bool = false

# Визуальные эффекты
@export var effect_color: Color = Color.ORANGE
@export var rarity: String = "common"  # common, rare, epic, legendary

# Скрытые модификаторы
@export var hidden_bonus: float = 0.0
@export var unlocks_upgrade_id: int = -1
@export var secret_achievement: bool = false
@export var secret_reveal_text: String = "???"

func get_progress_text(current_value: float) -> String:
	match achievement_type:
		"food_reached":
			return "🍖 %.0f/%.0f" % [current_value, goal]
		"water_reached":
			return "💧 %.0f/%.0f" % [current_value, goal]
		"days_survived":
			return "📅 %.0f/%.0f" % [current_value, goal]
		"materials_reached":
			return "🔧 %.0f/%.0f" % [current_value, goal]
		"upgrades_bought":
			return "⚒️ %.0f/%.0f" % [current_value, goal]
		"survivors_found":
			return "👥 %.0f/%.0f" % [current_value, goal]
	return ""

func get_rarity_color() -> Color:
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7)
		"rare":
			return Color(0.2, 0.6, 1.0)
		"epic":
			return Color(0.8, 0.2, 0.8)
		"legendary":
			return Color(1.0, 0.8, 0.2)
	return Color.WHITE

func check_completion(current_value: float) -> bool:
	if is_achieved:
		return false
	
	match achievement_type:
		"food_reached", "water_reached", "materials_reached", "days_survived", "upgrades_bought", "survivors_found":
			return current_value >= goal
	
	return false

func get_display_title() -> String:
	if secret_achievement and not is_achieved:
		return secret_reveal_text
	return title

func get_display_description() -> String:
	if secret_achievement and not is_achieved:
		return "???"
	return description

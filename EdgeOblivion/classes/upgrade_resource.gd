extends Resource
class_name UpgradeResource

@export var upgrade_id: int = 0
@export var title: String = "Название улучшения"
@export var description: String = "Описание улучшения"
@export var icon_left: Texture2D = null  # Левая иконка (большая)
@export var icon_right: Texture2D = null  # Правая иконка (маленькая)
@export var icon_text_left: String = "🛒"  # Текстовая иконка слева
@export var icon_text_right: String = ""   # Текстовая иконка справа
@export var cost: int = 10
@export var upgrade_type: String = "food_gain"  # food_gain, water_gain, materials_gain, health_restore, shelter_upgrade, survivor_find
@export var value: float = 1.0
@export var is_bought: bool = false
@export var required_upgrade_id: int = -1
@export var required_materials: int = 0
@export var required_days: int = 0
@export var visible_from_start: bool = true

# Визуальные эффекты
@export var effect_color: Color = Color.YELLOW
@export var rarity: String = "common"  # common, rare, epic, legendary

# Скрытые модификаторы
@export var hidden_multiplier: float = 1.0
@export var hidden_effect: String = ""

func get_effect_text() -> String:
	match upgrade_type:
		"food_gain":
			return "+%.1f к множителю еды" % value
		"water_gain":
			return "+%.1f к множителю воды" % value
		"materials_gain":
			return "+%.1f к множителю материалов" % value
		"health_restore":
			return "Восстанавливает %.0f здоровья" % value
		"shelter_upgrade":
			return "Увеличивает уровень укрытия на %.0f" % value
		"survivor_find":
			return "Находит %.0f новых выживших" % value
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

func can_buy(current_materials: int, current_day: int, purchased_upgrades: Array) -> bool:
	if is_bought:
		return false
	
	if current_materials < cost:
		return false
	
	if current_day < required_days:
		return false
	
	if required_upgrade_id != -1:
		if not required_upgrade_id in purchased_upgrades:
			return false
	
	return true

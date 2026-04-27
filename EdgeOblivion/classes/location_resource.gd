extends Resource
class_name LocationResource

@export var location_id: int = 0
@export var location_name: String = "Название локации"
@export var description: String = "Описание локации"
@export var icon_text: String = "🏞️"
@export var icon: Texture2D = null

# Базовые ресурсы
@export var base_food_yield: int = 1
@export var base_water_yield: int = 1
@export var base_materials_yield: int = 1

# Множители
@export var food_multiplier: float = 1.0
@export var water_multiplier: float = 1.0
@export var materials_multiplier: float = 1.0

# Требования для открытия
@export var required_days: int = 0
@export var required_upgrade_id: int = -1
@export var required_materials: int = 0

# Опасность
@export var danger_level: int = 0  # 0-10, влияет на потерю здоровья
@export var health_cost: int = 0  # Потеря здоровья при сборе

# Визуальные эффекты
@export var background_color: Color = Color(0.2, 0.3, 0.2, 1)
@export var text_color: Color = Color.WHITE

func get_resource_yield(resource_type: String, base_multiplier: float = 1.0) -> int:
	match resource_type:
		"food":
			return int(base_food_yield * food_multiplier * base_multiplier)
		"water":
			return int(base_water_yield * water_multiplier * base_multiplier)
		"materials":
			return int(base_materials_yield * materials_multiplier * base_multiplier)
	return 0

func can_access(current_day: int, purchased_upgrades: Array, current_materials: int) -> bool:
	if current_day < required_days:
		return false
	if required_upgrade_id != -1 and not required_upgrade_id in purchased_upgrades:
		return false
	if current_materials < required_materials:
		return false
	return true

func get_danger_text() -> String:
	if danger_level <= 2:
		return "Безопасно"
	elif danger_level <= 5:
		return "Опасно"
	elif danger_level <= 8:
		return "Очень опасно"
	else:
		return "Смертельно опасно"

func get_danger_color() -> Color:
	if danger_level <= 2:
		return Color.GREEN
	elif danger_level <= 5:
		return Color.YELLOW
	elif danger_level <= 8:
		return Color.ORANGE
	else:
		return Color.RED

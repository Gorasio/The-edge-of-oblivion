extends Resource
class_name SurvivorData

@export var survivor_id: int = 0
@export var survivor_type: String = "scout"
@export var character_name: String = "Выживший"
@export var specialization: String = "Разведчик"
@export var icon: Texture2D = null
@export var icon_text: String = "🔍"
@export var description: String = "Опытный разведчик, знающий местность"

# Характеристики
@export var health: int = 100
@export var max_health: int = 100
@export var power: int = 15
@export var damage: int = 12
@export var armor: int = 5
@export var attack_speed: float = 1.2

# Система уровней
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next: int = 100

# Работа
@export var job: String = "idle"  # idle, food, water, guard
@export var is_alive: bool = true

# Бонусы специализации
@export var food_bonus: float = 1.0
@export var water_bonus: float = 1.0
@export var guard_bonus: float = 1.0

func get_power() -> int:
	return power

func take_damage(amount: int):
	if not is_alive:
		return
	health -= amount
	if health <= 0:
		health = 0
		is_alive = false
		print(character_name, " погиб!")

func heal(amount: int):
	if not is_alive:
		return
	health += amount
	if health > max_health:
		health = max_health

func get_work_bonus() -> float:
	if not is_alive:
		return 0.0
	match job:
		"food":
			return food_bonus
		"water":
			return water_bonus
		"guard":
			return guard_bonus
	return 1.0

func get_job_text() -> String:
	if not is_alive:
		return "💀 Погиб"
	match job:
		"food":
			return "🍖 Добыча еды"
		"water":
			return "💧 Добыча воды"
		"guard":
			return "🛡️ Охрана"
	return "😴 Отдых"

func get_specialization_icon() -> String:
	match survivor_type:
		"scout":
			return "🔍"
		"gatherer":
			return "🫙"
		"observer":
			return "👁️"
		"medic":
			return "💊"
		"warrior":
			return "⚔️"
		"commander":
			return "⭐"
	return icon_text

func is_available_for_battle() -> bool:
	return is_alive and job == "guard"

# Система опыта и уровней
func add_experience(amount: int):
	if not is_alive:
		return
	
	experience += amount
	
	while experience >= experience_to_next:
		level_up()

func level_up():
	level += 1
	experience -= experience_to_next
	experience_to_next = int(experience_to_next * 1.2)
	
	# Увеличиваем характеристики при повышении уровня
	max_health += 10
	health = max_health
	power += 5
	damage += 3
	armor += 1
	
	print(character_name, " повысил уровень до ", level, "!")

func get_level() -> int:
	return level

func get_experience_percent() -> float:
	return float(experience) / float(experience_to_next) * 100.0

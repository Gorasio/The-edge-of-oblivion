extends Panel

signal cheat_applied(cheat_type, value)

@onready var scroll_container = $ScrollContainer
@onready var vbox = $ScrollContainer/VBoxContainer

# Кнопки ресурсов
@onready var food_cheat = $ScrollContainer/VBoxContainer/FoodCheat
@onready var water_cheat = $ScrollContainer/VBoxContainer/WaterCheat
@onready var materials_cheat = $ScrollContainer/VBoxContainer/MaterialsCheat
@onready var health_cheat = $ScrollContainer/VBoxContainer/HealthCheat
@onready var day_cheat = $ScrollContainer/VBoxContainer/DayCheat
@onready var all_resources_cheat = $ScrollContainer/VBoxContainer/AllResourcesCheat

# Кнопки выживших
@onready var add_survivor_cheat = $ScrollContainer/VBoxContainer/AddSurvivorCheat
@onready var add_random_survivor_cheat = $ScrollContainer/VBoxContainer/AddRandomSurvivorCheat
@onready var heal_all_survivors_cheat = $ScrollContainer/VBoxContainer/HealAllSurvivorsCheat

# Кнопки врагов
@onready var add_enemy_cheat = $ScrollContainer/VBoxContainer/AddEnemyCheat
@onready var add_rat_pack_cheat = $ScrollContainer/VBoxContainer/AddRatPackCheat
@onready var add_bandits_cheat = $ScrollContainer/VBoxContainer/AddBanditsCheat
@onready var add_zombies_cheat = $ScrollContainer/VBoxContainer/AddZombiesCheat
@onready var add_mutant_cheat = $ScrollContainer/VBoxContainer/AddMutantCheat

# Кнопки игры
@onready var god_mode_cheat = $ScrollContainer/VBoxContainer/GodModeCheat
@onready var kill_all_cheat = $ScrollContainer/VBoxContainer/KillAllCheat
@onready var close_button = $ScrollContainer/VBoxContainer/CloseButton

var god_mode_active = false

func _ready():
	# Подключаем сигналы ресурсов
	food_cheat.pressed.connect(func(): _on_cheat_pressed("food", 100))
	water_cheat.pressed.connect(func(): _on_cheat_pressed("water", 100))
	materials_cheat.pressed.connect(func(): _on_cheat_pressed("materials", 100))
	health_cheat.pressed.connect(func(): _on_cheat_pressed("health", 50))
	day_cheat.pressed.connect(func(): _on_cheat_pressed("day", 10))
	all_resources_cheat.pressed.connect(_on_all_resources_cheat)
	
	# Подключаем сигналы выживших
	add_survivor_cheat.pressed.connect(_on_add_survivor_cheat)
	add_random_survivor_cheat.pressed.connect(_on_add_random_survivor_cheat)
	heal_all_survivors_cheat.pressed.connect(_on_heal_all_survivors_cheat)
	
	# Подключаем сигналы врагов
	add_enemy_cheat.pressed.connect(_on_add_enemy_cheat)
	add_rat_pack_cheat.pressed.connect(func(): _on_add_specific_enemy_cheat("rat_pack"))
	add_bandits_cheat.pressed.connect(func(): _on_add_specific_enemy_cheat("bandits"))
	add_zombies_cheat.pressed.connect(func(): _on_add_specific_enemy_cheat("zombies"))
	add_mutant_cheat.pressed.connect(func(): _on_add_specific_enemy_cheat("mutant"))
	
	# Подключаем сигналы игры
	god_mode_cheat.pressed.connect(_on_god_mode_cheat)
	kill_all_cheat.pressed.connect(_on_kill_all_cheat)
	close_button.pressed.connect(_on_close_pressed)

func _on_cheat_pressed(cheat_type: String, value: int):
	cheat_applied.emit(cheat_type, value)

func _on_all_resources_cheat():
	cheat_applied.emit("all_resources", 1000)

# --- Выжившие ---
func _on_add_survivor_cheat():
	cheat_applied.emit("add_survivor", "scout")

func _on_add_random_survivor_cheat():
	var survivor_types = ["scout", "gatherer", "observer", "medic", "warrior"]
	var random_type = survivor_types[randi() % survivor_types.size()]
	cheat_applied.emit("add_survivor", random_type)

func _on_heal_all_survivors_cheat():
	cheat_applied.emit("heal_all_survivors", 0)

# --- Враги ---
func _on_add_enemy_cheat():
	var enemy_types = ["rat_pack", "bandits", "zombies", "mutant"]
	var random_type = enemy_types[randi() % enemy_types.size()]
	cheat_applied.emit("add_enemy", random_type)

func _on_add_specific_enemy_cheat(enemy_type: String):
	cheat_applied.emit("add_enemy", enemy_type)

# --- Игра ---
func _on_god_mode_cheat():
	god_mode_active = !god_mode_active
	cheat_applied.emit("god_mode", god_mode_active)
	update_god_mode_button()

func _on_kill_all_cheat():
	cheat_applied.emit("kill_all", 0)

func update_god_mode_button():
	if god_mode_active:
		god_mode_cheat.text = "🛡️ Режим Бога (АКТИВЕН)"
		god_mode_cheat.add_theme_color_override("font_color", Color.GREEN)
	else:
		god_mode_cheat.text = "🛡️ Режим Бога"
		god_mode_cheat.add_theme_color_override("font_color", Color.WHITE)

func _on_close_pressed():
	hide()

extends Control

signal survivors_updated
signal closed

var survivors: Array[SurvivorData] = []
var main_character: SurvivorData = null

# Путь к папке с иконками выживших
const SURVIVOR_ICONS_FOLDER = "res://assets/icons/survivors/"

@onready var survivors_scroll: ScrollContainer = $SurvivorsScrollContainer
@onready var survivors_grid: GridContainer = $SurvivorsScrollContainer/SurvivorsGrid
@onready var close_button = $CloseButton
@onready var back_button = $BackButton
@onready var general_portrait = $GeneralPanel/GeneralPortrait
@onready var general_icon = $GeneralPanel/GeneralIcon
@onready var general_name = $GeneralPanel/GeneralName
@onready var general_specialization = $GeneralPanel/GeneralSpecialization
@onready var general_health = $GeneralPanel/GeneralHealth
@onready var general_power = $GeneralPanel/GeneralPower
@onready var general_bonus = $GeneralPanel/GeneralBonus
@onready var total_power_label = $StatsPanel/TotalPower
@onready var food_gatherers_label = $StatsPanel/FoodGatherers
@onready var water_gatherers_label = $StatsPanel/WaterGatherers
@onready var guards_label = $StatsPanel/Guards
@onready var idle_label = $StatsPanel/Idle

func _ready():
	# Настройка сетки
	if survivors_grid:
		survivors_grid.columns = 2
		survivors_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		survivors_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	update_general_display()
	update_survivors_grid()
	update_stats()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func update_general_display():
	if main_character:
		if general_portrait:
			general_portrait.texture = main_character.icon if main_character.icon else null
		
		if general_icon:
			general_icon.text = main_character.get_specialization_icon()
		
		if general_name:
			general_name.text = main_character.character_name
		
		if general_specialization:
			general_specialization.text = main_character.specialization
		
		if general_health:
			general_health.text = "❤️ Здоровье: %d/%d" % [main_character.health, main_character.max_health]
		
		if general_power:
			general_power.text = "⚔️ Сила: %d  🛡️ Броня: %d" % [main_character.power, main_character.armor]
		
		if general_bonus:
			var bonus_text = ""
			if main_character.food_bonus > 1.0:
				bonus_text += "🍖 +%.0f%% " % ((main_character.food_bonus - 1) * 100)
			if main_character.water_bonus > 1.0:
				bonus_text += "💧 +%.0f%% " % ((main_character.water_bonus - 1) * 100)
			if main_character.guard_bonus > 1.0:
				bonus_text += "🛡️ +%.0f%%" % ((main_character.guard_bonus - 1) * 100)
			general_bonus.text = "✨ Бонусы: " + bonus_text

func update_survivors_grid():
	if not survivors_grid:
		return
	
	# Очищаем сетку
	for child in survivors_grid.get_children():
		child.queue_free()
	
	print("=== Обновление сетки выживших ===")
	
	# Показываем только живых выживших
	var alive_survivors = survivors.filter(func(s): return s.is_alive)
	print("Всего выживших: ", survivors.size(), " | Живых: ", alive_survivors.size())
	
	# Создаем карточки выживших из скрипта
	for i in range(alive_survivors.size()):
		var survivor = alive_survivors[i]
		print(i, ". ", survivor.character_name, " (", survivor.survivor_type, ") - Здоровье: ", survivor.health)
		
		# Загружаем иконку если нужно
		if survivor.icon == null:
			var icon_path = get_icon_path_for_type(survivor.survivor_type)
			if ResourceLoader.exists(icon_path):
				var texture = load(icon_path)
				if texture:
					survivor.icon = texture
					print("   - Загружена иконка для ", survivor.survivor_type)
		
		# Создаем карточку через скрипт (не через сцену)
		var card = preload("res://scripts/survivor_card.gd").new()
		card.setup(survivor)
		card.job_changed.connect(_on_survivor_job_changed)
		survivors_grid.add_child(card)
	
	# Обновляем размеры сетки
	await get_tree().process_frame
	update_grid_size()
	
	update_stats()

func update_grid_size():
	if not survivors_grid or not survivors_scroll:
		return
	
	var card_height = 140
	var rows = ceil(float(survivors_grid.get_child_count()) / survivors_grid.columns)
	var total_height = rows * card_height + 30
	
	survivors_grid.custom_minimum_size = Vector2(0, total_height)
	survivors_scroll.get_v_scroll_bar().value = 0

func get_icon_path_for_type(survivor_type: String) -> String:
	match survivor_type:
		"scout":
			return SURVIVOR_ICONS_FOLDER + "scout.png"
		"gatherer":
			return SURVIVOR_ICONS_FOLDER + "gatherer.png"
		"observer":
			return SURVIVOR_ICONS_FOLDER + "observer.png"
		"medic":
			return SURVIVOR_ICONS_FOLDER + "medic.png"
		"warrior":
			return SURVIVOR_ICONS_FOLDER + "warrior.png"
		"commander":
			return SURVIVOR_ICONS_FOLDER + "commander.png"
	return ""

func update_stats():
	var total_power = main_character.power if main_character and main_character.is_alive else 0
	var food_count = 0
	var water_count = 0
	var guard_count = 0
	var idle_count = 0
	
	for survivor in survivors:
		if not survivor.is_alive:
			continue
		total_power += survivor.power
		match survivor.job:
			"food":
				food_count += 1
			"water":
				water_count += 1
			"guard":
				guard_count += 1
			_:
				idle_count += 1
	
	total_power_label.text = "⚔️ Общая сила: %d" % total_power
	food_gatherers_label.text = "🍖 Добытчики еды: %d" % food_count
	water_gatherers_label.text = "💧 Добытчики воды: %d" % water_count
	guards_label.text = "🛡️ Охранники: %d" % guard_count
	idle_label.text = "😴 Отдыхающие: %d" % idle_count

func _on_survivor_job_changed():
	update_stats()
	survivors_updated.emit()

func _on_close_pressed():
	closed.emit()
	queue_free()

func _on_back_pressed():
	closed.emit()
	queue_free()

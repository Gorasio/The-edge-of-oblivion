extends Node2D

# --- Переменные ---
var food: int = 0: set = set_food
var water: int = 0: set = set_water
var materials: int = 0: set = set_materials
var health: float = 100.0: set = set_health
var day: int = 1
var multiplier: float = 1.0
var total_scavenged: int = 0
var total_days_survived: int = 0
var shelter_level: int = 1
var god_mode: bool = false

# Локации (для сбора ресурсов)
var current_location: LocationData = null
var locations_list: Array[LocationData] = []
var unlocked_locations: Array[int] = []

# Ресурсы
var upgrades_list: Array[UpgradeResource] = []
var purchased_upgrades: Array[int] = []
var achievements_list: Array[AchievementResource] = []
var unlocked_achievements: Array[int] = []

# Выжившие
var survivor_list: Array[SurvivorData] = []
var main_character: SurvivorData = null
var survivor_bonus_food: float = 0.0
var survivor_bonus_water: float = 0.0
var survivor_bonus_guard: float = 0.0

# Противники (для WorldMap)
var enemies_list: Array[EnemyGroupData] = []
var enemy_types: Dictionary = {}

# Пути к ресурсам
const UPGRADES_FOLDER = "res://Resources/upgrades/"
const ACHIEVEMENTS_FOLDER = "res://Resources/achievements/"
const LOCATIONS_FOLDER = "res://Resources/locations/"
const SURVIVORS_FOLDER = "res://Resources/survivors/"
const ENEMIES_FOLDER = "res://Resources/enemies/"
const ENEMIES_GROUPS_FOLDER = "res://Resources/enemies_groups/"

# --- Переменные для паузы ---
var is_paused: bool = false

# --- Переменные для загрузки из слота ---
var loading_from_slot = false
var slot_data_to_load: Dictionary = {}

# --- UI Основное ---
@onready var food_label: Label = $MarginContainer/VBoxContainer/FoodLabel
@onready var water_label: Label = $MarginContainer/VBoxContainer/WaterLabel
@onready var materials_label: Label = $MarginContainer/VBoxContainer/MaterialsLabel
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var day_label: Label = $MarginContainer/VBoxContainer/DayLabel
@onready var action_button: Button = $MarginContainer/VBoxContainer/ActionButton
@onready var bg_sprite: TextureRect = $BackgroundSprite
@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var top_panel: Panel = $TopPanel
@onready var time_label: Label = $TopPanel/TimeLabel
@onready var pause_button: Button = $TopPanel/PauseButton
@onready var menu_button: Button = $TopPanel/MenuButton

# --- Панели (скрытые) ---
@onready var shop_panel = $ShopPanel
@onready var achievements_panel = $AchievementsPanel
@onready var pause_menu = $PauseMenu
@onready var cheat_panel = $CheatPanel
@onready var character_panel = $CharacterPanel

# --- Кнопки для открытия панелей ---
@onready var shop_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ShopButton
@onready var achievements_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/AchievementsButton
@onready var survivors_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/SurvivorsButton
@onready var map_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/MapButton

# --- Таймеры ---
@onready var game_timer: Timer = $Timer

# --- Фоны ---
var backgrounds = []

func _ready():
	load_all_upgrades()
	load_all_achievements()
	load_all_locations()
	load_all_enemies()
	load_backgrounds()
	
	load_character()
	load_survivors()
	
	if locations_list.size() > 0:
		current_location = locations_list[0]
		unlocked_locations.append(current_location.location_id)
	
	if loading_from_slot and slot_data_to_load:
		load_from_data(slot_data_to_load)
		loading_from_slot = false
		slot_data_to_load.clear()
		var dialog_data = load("res://dialogues/update_message.tres")
		if dialog_data:
			SproutyDialogs.start_dialog(dialog_data, "FIRST")
	else:
		load_game()
		var dialog_data = load("res://dialogues/intro.tres")
		if dialog_data:
			SproutyDialogs.start_dialog(dialog_data, "FIRST")
	
	update_ui()
	setup_timer()
	setup_autosave()
	
	# Настройка панелей
	setup_panels()
	
	# Сигналы
	action_button.pressed.connect(_on_action_button_pressed)
	shop_button.pressed.connect(_open_shop_panel)
	achievements_button.pressed.connect(_open_achievements_panel)
	survivors_button.pressed.connect(_open_survivors_panel)
	map_button.pressed.connect(_open_world_map)
	pause_button.pressed.connect(toggle_pause)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Скрываем панели
	shop_panel.hide()
	achievements_panel.hide()
	pause_menu.hide()
	cheat_panel.hide()
	
	update_survivor_bonuses()

func setup_panels():
	# Настройка панели персонажа
	character_panel.setup(main_character)
	
	# Настройка панели магазина
	shop_panel.setup(upgrades_list, purchased_upgrades, materials)
	shop_panel.closed.connect(_close_shop_panel)
	
	# Настройка панели достижений
	achievements_panel.setup(achievements_list, unlocked_achievements)
	achievements_panel.closed.connect(_close_achievements_panel)
	
	# Настройка меню паузы
	pause_menu.resume_game.connect(_close_pause_menu)
	pause_menu.save_game.connect(_on_save_button_pressed)
	pause_menu.quit_to_menu.connect(_return_to_menu)
	pause_menu.quit_game.connect(_quit_game)

# --- Загрузка персонажа ---
func load_character():
	var save_path = "user://character.save"
	if FileAccess.file_exists(save_path):
		load_character_from_file(save_path)
	else:
		print("Ошибка: Персонаж не найден! Возврат в главное меню.")
		get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func load_character_from_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data_json = file.get_as_text()
		var data = JSON.parse_string(data_json)
		file.close()
		
		if data:
			main_character = SurvivorData.new()
			main_character.character_name = data.get("name", "Командир")
			main_character.survivor_type = data.get("type", "commander")
			main_character.specialization = data.get("specialization", "Командир")
			main_character.icon_text = get_icon_for_type(main_character.survivor_type)
			main_character.max_health = data.get("max_health", 150)
			main_character.health = data.get("health", main_character.max_health)
			main_character.power = data.get("power", 50)
			main_character.damage = data.get("damage", 30)
			main_character.armor = data.get("armor", 10)
			main_character.food_bonus = data.get("food_bonus", 1.0)
			main_character.water_bonus = data.get("water_bonus", 1.0)
			main_character.guard_bonus = data.get("guard_bonus", 1.5)
			main_character.is_alive = true
			
			var portrait_path = "user://character_portrait.png"
			if FileAccess.file_exists(portrait_path):
				var image = Image.load_from_file(portrait_path)
				if image:
					main_character.icon = ImageTexture.create_from_image(image)

func get_icon_for_type(type: String) -> String:
	match type:
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
	return "⭐"

# --- Загрузка выживших ---
func load_survivors():
	survivor_list.clear()
	
	var save_path = "user://survivors.save"
	if FileAccess.file_exists(save_path):
		load_survivors_from_file(save_path)
	else:
		load_default_survivors()

func load_default_survivors():
	var scout_path = SURVIVORS_FOLDER + "scout.tres"
	var gatherer_path = SURVIVORS_FOLDER + "gatherer.tres"
	var observer_path = SURVIVORS_FOLDER + "observer.tres"
	var medic_path = SURVIVORS_FOLDER + "medic.tres"
	
	if ResourceLoader.exists(scout_path):
		var scout = load(scout_path)
		if scout is SurvivorData:
			survivor_list.append(scout)
	if ResourceLoader.exists(gatherer_path):
		var gatherer = load(gatherer_path)
		if gatherer is SurvivorData:
			survivor_list.append(gatherer)
	if ResourceLoader.exists(observer_path):
		var observer = load(observer_path)
		if observer is SurvivorData:
			survivor_list.append(observer)
	if ResourceLoader.exists(medic_path):
		var medic = load(medic_path)
		if medic is SurvivorData:
			survivor_list.append(medic)
	
	if survivor_list.size() == 0:
		create_test_survivors()
	
	save_survivors()

func create_test_survivors():
	var scout = SurvivorData.new()
	scout.survivor_id = 1
	scout.survivor_type = "scout"
	scout.specialization = "Разведчик"
	scout.icon_text = "🔍"
	scout.icon = load_icon_or_null("res://assets/icons/survivors/scout.png")
	scout.health = 80
	scout.max_health = 80
	scout.power = 20
	scout.damage = 15
	scout.armor = 4
	scout.food_bonus = 1.2
	scout.water_bonus = 1.2
	scout.guard_bonus = 1.0
	scout.is_alive = true
	survivor_list.append(scout)
	
	var gatherer = SurvivorData.new()
	gatherer.survivor_id = 2
	gatherer.survivor_type = "gatherer"
	gatherer.specialization = "Собиратель"
	gatherer.icon_text = "🫙"
	gatherer.icon = load_icon_or_null("res://assets/icons/survivors/gatherer.png")
	gatherer.health = 90
	gatherer.max_health = 90
	gatherer.power = 12
	gatherer.damage = 10
	gatherer.armor = 6
	gatherer.food_bonus = 1.5
	gatherer.water_bonus = 1.5
	gatherer.guard_bonus = 0.8
	gatherer.is_alive = true
	survivor_list.append(gatherer)
	
	var observer = SurvivorData.new()
	observer.survivor_id = 3
	observer.survivor_type = "observer"
	observer.specialization = "Наблюдатель"
	observer.icon_text = "👁️"
	observer.icon = load_icon_or_null("res://assets/icons/survivors/observer.png")
	observer.health = 70
	observer.max_health = 70
	observer.power = 10
	observer.damage = 8
	observer.armor = 3
	observer.food_bonus = 1.0
	observer.water_bonus = 1.0
	observer.guard_bonus = 1.5
	observer.is_alive = true
	survivor_list.append(observer)
	
	var medic = SurvivorData.new()
	medic.survivor_id = 4
	medic.survivor_type = "medic"
	medic.specialization = "Медик"
	medic.icon_text = "💊"
	medic.icon = load_icon_or_null("res://assets/icons/survivors/medic.png")
	medic.health = 100
	medic.max_health = 100
	medic.power = 8
	medic.damage = 5
	medic.armor = 4
	medic.food_bonus = 0.8
	medic.water_bonus = 0.8
	medic.guard_bonus = 1.2
	medic.is_alive = true
	survivor_list.append(medic)

func save_survivors():
	var save_path = "user://survivors.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var save_data = []
		for survivor in survivor_list:
			save_data.append({
				"id": survivor.survivor_id,
				"type": survivor.survivor_type,
				"specialization": survivor.specialization,
				"health": survivor.health,
				"max_health": survivor.max_health,
				"power": survivor.power,
				"damage": survivor.damage,
				"armor": survivor.armor,
				"attack_speed": survivor.attack_speed,
				"job": survivor.job,
				"food_bonus": survivor.food_bonus,
				"water_bonus": survivor.water_bonus,
				"guard_bonus": survivor.guard_bonus,
				"name": survivor.character_name,
				"is_alive": survivor.is_alive
			})
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_survivors_from_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data_json = file.get_as_text()
		var data = JSON.parse_string(data_json)
		file.close()
		
		if data:
			for survivor_data in data:
				var survivor = SurvivorData.new()
				survivor.survivor_id = survivor_data.get("id", 0)
				survivor.survivor_type = survivor_data.get("type", "scout")
				survivor.specialization = survivor_data.get("specialization", "Разведчик")
				survivor.icon_text = get_icon_for_type(survivor.survivor_type)
				survivor.icon = load_icon_or_null(get_icon_path_for_type(survivor.survivor_type))
				survivor.max_health = survivor_data.get("max_health", 100)
				survivor.health = survivor_data.get("health", survivor.max_health)
				survivor.power = survivor_data.get("power", 15)
				survivor.damage = survivor_data.get("damage", 12)
				survivor.armor = survivor_data.get("armor", 5)
				survivor.attack_speed = survivor_data.get("attack_speed", 1.0)
				survivor.job = survivor_data.get("job", "idle")
				survivor.food_bonus = survivor_data.get("food_bonus", 1.0)
				survivor.water_bonus = survivor_data.get("water_bonus", 1.0)
				survivor.guard_bonus = survivor_data.get("guard_bonus", 1.0)
				survivor.character_name = survivor_data.get("name", "Выживший")
				survivor.is_alive = survivor_data.get("is_alive", true)
				survivor_list.append(survivor)

func get_icon_path_for_type(survivor_type: String) -> String:
	match survivor_type:
		"scout":
			return "res://assets/icons/survivors/scout.png"
		"gatherer":
			return "res://assets/icons/survivors/gatherer.png"
		"observer":
			return "res://assets/icons/survivors/observer.png"
		"medic":
			return "res://assets/icons/survivors/medic.png"
		"warrior":
			return "res://assets/icons/survivors/warrior.png"
		"commander":
			return "res://assets/icons/survivors/commander.png"
	return ""

func load_icon_or_null(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture:
			return texture
	return null

func update_survivor_bonuses():
	var food_bonus = 0.0
	var water_bonus = 0.0
	var guard_bonus = 0.0
	
	for survivor in survivor_list:
		if not survivor.is_alive:
			continue
		match survivor.job:
			"food":
				food_bonus += survivor.get_work_bonus()
			"water":
				water_bonus += survivor.get_work_bonus()
			"guard":
				guard_bonus += survivor.get_work_bonus()
	
	survivor_bonus_food = food_bonus
	survivor_bonus_water = water_bonus
	survivor_bonus_guard = guard_bonus
	
	if main_character:
		multiplier = 1.0 + (guard_bonus * 0.05) * main_character.guard_bonus
	else:
		multiplier = 1.0 + (guard_bonus * 0.05)

# --- Загрузка локаций ---
func load_all_locations():
	locations_list.clear()
	
	if not DirAccess.dir_exists_absolute(LOCATIONS_FOLDER):
		create_test_locations()
		return
	
	var dir = DirAccess.open(LOCATIONS_FOLDER)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var file_path = LOCATIONS_FOLDER + file_name
				var location = load(file_path)
				if location is LocationData:
					locations_list.append(location)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if locations_list.size() == 0:
		create_test_locations()
	
	if locations_list.size() > 0:
		locations_list.sort_custom(func(a, b): return a.location_id < b.location_id)

func create_test_locations():
	var forest = LocationData.new()
	forest.location_id = 1
	forest.location_name = "🌲 Лес"
	forest.location_description = "Густой лес с ягодами и дикими животными"
	forest.icon_text = "🌲"
	forest.base_food_yield = 3
	forest.base_water_yield = 1
	forest.base_materials_yield = 2
	forest.danger_level = 2
	locations_list.append(forest)
	
	var river = LocationData.new()
	river.location_id = 2
	river.location_name = "🌊 Река"
	river.location_description = "Чистая река с рыбой и пресной водой"
	river.icon_text = "🌊"
	river.base_food_yield = 2
	river.base_water_yield = 5
	river.base_materials_yield = 1
	river.danger_level = 1
	locations_list.append(river)

# --- Загрузка противников ---
func load_all_enemies():
	enemies_list.clear()
	enemy_types.clear()
	
	print("Загрузка типов врагов из папки: ", ENEMIES_FOLDER)
	
	if DirAccess.dir_exists_absolute(ENEMIES_FOLDER):
		var dir = DirAccess.open(ENEMIES_FOLDER)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var file_path = ENEMIES_FOLDER + file_name
					var resource = load(file_path)
					if resource is EnemyData:
						enemy_types[resource.name] = resource
						print("✓ Загружен тип врага: ", resource.name)
				file_name = dir.get_next()
			dir.list_dir_end()
	else:
		print("Папка с типами врагов не найдена: ", ENEMIES_FOLDER)
	
	print("Загрузка групп врагов из папки: ", ENEMIES_GROUPS_FOLDER)
	
	if DirAccess.dir_exists_absolute(ENEMIES_GROUPS_FOLDER):
		var dir = DirAccess.open(ENEMIES_GROUPS_FOLDER)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var file_path = ENEMIES_GROUPS_FOLDER + file_name
					var resource = load(file_path)
					if resource is EnemyGroupData:
						enemies_list.append(resource)
						print("✓ Загружена группа: ", resource.group_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	else:
		print("Папка с группами врагов не найдена: ", ENEMIES_GROUPS_FOLDER)
	
	print("Загружено типов врагов: ", enemy_types.size())
	print("Загружено групп: ", enemies_list.size())

func get_enemy_types() -> Dictionary:
	return enemy_types

# --- Загрузка улучшений и достижений ---
func load_all_upgrades():
	upgrades_list.clear()
	
	if not DirAccess.dir_exists_absolute(UPGRADES_FOLDER):
		create_test_upgrades()
		return
	
	var dir = DirAccess.open(UPGRADES_FOLDER)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var file_path = UPGRADES_FOLDER + file_name
				var upgrade = load(file_path)
				if upgrade is UpgradeResource:
					upgrades_list.append(upgrade)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if upgrades_list.size() == 0:
		create_test_upgrades()
	
	if upgrades_list.size() > 0:
		upgrades_list.sort_custom(func(a, b): return a.upgrade_id < b.upgrade_id)

func create_test_upgrades():
	var test_upgrade1 = UpgradeResource.new()
	test_upgrade1.upgrade_id = 1
	test_upgrade1.title = "Острые ножи"
	test_upgrade1.description = "Позволяют эффективнее собирать еду"
	test_upgrade1.icon_text_left = "🔪"
	test_upgrade1.cost = 15
	test_upgrade1.upgrade_type = "food_gain"
	test_upgrade1.value = 0.2
	upgrades_list.append(test_upgrade1)
	
	var test_upgrade2 = UpgradeResource.new()
	test_upgrade2.upgrade_id = 2
	test_upgrade2.title = "Фильтры для воды"
	test_upgrade2.description = "Позволяют собирать больше воды"
	test_upgrade2.icon_text_left = "💧"
	test_upgrade2.cost = 20
	test_upgrade2.upgrade_type = "water_gain"
	test_upgrade2.value = 0.2
	upgrades_list.append(test_upgrade2)

func load_all_achievements():
	achievements_list.clear()
	
	if not DirAccess.dir_exists_absolute(ACHIEVEMENTS_FOLDER):
		create_test_achievements()
		return
	
	var dir = DirAccess.open(ACHIEVEMENTS_FOLDER)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var file_path = ACHIEVEMENTS_FOLDER + file_name
				var achievement = load(file_path)
				if achievement is AchievementResource:
					achievements_list.append(achievement)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if achievements_list.size() == 0:
		create_test_achievements()

func create_test_achievements():
	var test_achievement1 = AchievementResource.new()
	test_achievement1.achievement_id = 1
	test_achievement1.title = "Первый ужин"
	test_achievement1.description = "Соберите 10 единиц еды"
	test_achievement1.icon_text_left = "🍖"
	test_achievement1.achievement_type = "food_reached"
	test_achievement1.goal = 10.0
	test_achievement1.reward_multiplier = 1.1
	achievements_list.append(test_achievement1)

func load_backgrounds():
	backgrounds = [
		load("res://assets/bg_day.png"),
		load("res://assets/bg_night.png"),
		load("res://assets/bg_ruins.png"),
		load("res://assets/bg_shelter.png"),
	]

# --- Открытие/закрытие панелей ---
func _open_shop_panel():
	if is_paused:
		return
	shop_panel.update_panel()
	shop_panel.show()
	pause_game()

func _close_shop_panel():
	shop_panel.hide()
	resume_game()

func _open_achievements_panel():
	if is_paused:
		return
	achievements_panel.update_panel()
	achievements_panel.show()
	pause_game()

func _close_achievements_panel():
	achievements_panel.hide()
	resume_game()

func _open_survivors_panel():
	if is_paused:
		return
	
	save_game()
	save_survivors()
	
	var survivor_scene = preload("res://scenes/SurvivorManagement.tscn").instantiate()
	survivor_scene.survivors = survivor_list
	survivor_scene.main_character = main_character
	survivor_scene.survivors_updated.connect(_on_survivors_updated)
	survivor_scene.closed.connect(_on_survivors_closed)
	
	get_tree().root.add_child(survivor_scene)
	get_tree().current_scene = survivor_scene
	hide()

func _open_world_map():
	if is_paused:
		return
	save_game()
	var map_scene = preload("res://scenes/map/WorldMap.tscn").instantiate()
	get_tree().root.add_child(map_scene)
	get_tree().current_scene = map_scene
	hide()

func _on_survivors_updated():
	update_survivor_bonuses()
	save_survivors()
	update_ui()

func _on_survivors_closed():
	show()
	update_ui()
	save_survivors()

func pause_game():
	is_paused = true
	game_timer.paused = true
	time_label.text = "⏸️ Пауза"
	action_button.disabled = true
	shop_button.disabled = true
	achievements_button.disabled = true
	survivors_button.disabled = true
	map_button.disabled = true

func resume_game():
	is_paused = false
	game_timer.paused = false
	time_label.text = "▶️ Игра"
	action_button.disabled = false
	shop_button.disabled = false
	achievements_button.disabled = false
	survivors_button.disabled = false
	map_button.disabled = false

func toggle_pause():
	if is_paused:
		if shop_panel.visible:
			_close_shop_panel()
		if achievements_panel.visible:
			_close_achievements_panel()
		if cheat_panel.visible:
			_close_cheat_panel()
		resume_game()
		pause_menu.hide()
	else:
		pause_game()
		pause_menu.show()

func _close_pause_menu():
	resume_game()
	pause_menu.hide()

# --- Таймеры ---
func setup_timer():
	game_timer.timeout.connect(_on_new_day_timeout)
	game_timer.start(10.0)

func setup_autosave():
	var save_timer = Timer.new()
	add_child(save_timer)
	save_timer.timeout.connect(save_game)
	save_timer.start(30.0)
	save_timer.name = "AutosaveTimer"

# --- Основная механика ---
func _on_action_button_pressed():
	if is_paused:
		return
	
	if current_location == null:
		return
	
	var base_multiplier = multiplier * (1 + shelter_level * 0.1) * (1 + survivor_bonus_guard * 0.05)
	if main_character:
		base_multiplier *= main_character.guard_bonus
	
	var food_gain = current_location.get_resource_yield("food", base_multiplier) + int(survivor_bonus_food)
	var water_gain = current_location.get_resource_yield("water", base_multiplier) + int(survivor_bonus_water)
	var materials_gain = current_location.get_resource_yield("materials", base_multiplier)
	
	var health_loss = current_location.health_cost
	if current_location.danger_level > 0:
		health_loss += current_location.danger_level
	
	if health_loss > 0 and not god_mode:
		health -= health_loss
	
	food += food_gain
	water += water_gain
	materials += materials_gain
	total_scavenged += food_gain + water_gain + materials_gain
	
	check_all_achievements()
	update_ui()
	
	var dialog_data = load("res://dialogues/forage_food.tres")
	if dialog_data:
		SproutyDialogs.start_dialog(dialog_data, "FIRST")
	
	if health <= 0 and not god_mode:
		game_over()

func _on_new_day_timeout():
	if is_paused:
		return
	
	day += 1
	total_days_survived += 1
	
	var food_consumed = survivor_list.size() + 1
	var water_consumed = survivor_list.size() + 1
	
	food -= food_consumed
	water -= water_consumed
	
	if food < 0:
		health += food * 2
		food = 0
	
	if water < 0:
		health += water * 2
		water = 0
	
	if food >= food_consumed and water >= water_consumed:
		health = min(100, health + 5)
	
	if health <= 0 and not god_mode:
		game_over()
		return
	
	check_all_achievements()
	update_ui()
	change_background()
	
	var dialog_data = load("res://dialogues/survive_day.tres")
	if dialog_data:
		SproutyDialogs.start_dialog(dialog_data, "FIRST")

func get_achievement_current_value(achievement: AchievementResource) -> float:
	match achievement.achievement_type:
		"food_reached":
			return food
		"water_reached":
			return water
		"days_survived":
			return total_days_survived
		"materials_reached":
			return materials
		"upgrades_bought":
			return purchased_upgrades.size()
		"survivors_found":
			return survivor_list.size()
		"level_reached":
			return main_character.level if main_character else 1
		"power_reached":
			return main_character.power if main_character else 0
	return 0.0

func game_over():
	var dialog_data = load("res://dialogues/game_over.tres")
	if dialog_data:
		SproutyDialogs.start_dialog(dialog_data, "FIRST")
	
	await get_tree().create_timer(3.0).timeout
	
	if FileAccess.file_exists("user://savegame.save"):
		DirAccess.remove_absolute("user://savegame.save")
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "Игра окончена"
	dialog.dialog_text = "Вы погибли... Игра окончена."
	dialog.ok_button_text = "В меню"
	dialog.cancel_button_text = "Выйти"
	dialog.confirmed.connect(_return_to_menu)
	dialog.canceled.connect(_quit_game)
	add_child(dialog)
	dialog.popup_centered()

# --- Сеттеры ---
func set_food(value: int):
	food = max(0, value)
	check_all_achievements()
	update_ui()

func set_water(value: int):
	water = max(0, value)
	update_ui()

func set_materials(value: int):
	materials = max(0, value)
	update_ui()

func set_health(value: float):
	if god_mode and value < health:
		return
	health = clamp(value, 0, 100)
	update_ui()

# --- UI обновление ---
func update_ui():
	food_label.text = "🍖 Еда: %d" % food
	water_label.text = "💧 Вода: %d" % water
	materials_label.text = "🔧 Материалы: %d" % materials
	health_label.text = "❤️ Здоровье: %d" % int(health)
	day_label.text = "📅 День: %d | 👥 Выживших: %d" % [day, survivor_list.size() + 1]
	if survivor_bonus_guard > 0:
		day_label.text += "\n✨ Бонус охраны: +%.0f%%" % (survivor_bonus_guard * 5)
	progress_bar.value = health
	
	character_panel.update_display()
	shop_panel.materials = materials
	if shop_panel.visible:
		shop_panel.update_panel()
	# Обновляем квесты на достижение силы
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system and main_character:
		quest_system.update_power_progress(main_character.power)

func change_background():
	if backgrounds.is_empty():
		return
	var bg_index = min(floor(day / 3), backgrounds.size() - 1)
	bg_sprite.texture = backgrounds[bg_index]

func check_all_achievements():
	for achievement in achievements_list:
		if achievement.achievement_id in unlocked_achievements:
			continue
		
		var current_value = get_achievement_current_value(achievement)
		if achievement.check_completion(current_value):
			unlock_achievement(achievement)

func unlock_achievement(achievement: AchievementResource):
	achievement.is_achieved = true
	unlocked_achievements.append(achievement.achievement_id)
	multiplier *= achievement.reward_multiplier
	
	var dialog_data = load("res://dialogues/achievement_unlock.tres")
	if dialog_data:
		SproutyDialogs.start_dialog(dialog_data, "FIRST")
	
	if achievements_panel.visible:
		achievements_panel.update_panel()

# --- Улучшения ---
func buy_upgrade(upgrade: UpgradeResource) -> bool:
	if not upgrade.can_buy(materials, day, purchased_upgrades):
		return false
	
	materials -= upgrade.cost
	upgrade.is_bought = true
	purchased_upgrades.append(upgrade.upgrade_id)
	apply_upgrade_effect(upgrade)
	
	check_all_achievements()
	update_ui()
	
	# Обновляем панель квестов
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system.update_upgrade_progress()
	
	return true

func apply_upgrade_effect(upgrade: UpgradeResource):
	match upgrade.upgrade_type:
		"food_gain":
			multiplier += upgrade.value
		"water_gain":
			multiplier += upgrade.value
		"materials_gain":
			multiplier += upgrade.value
		"health_restore":
			health = min(100, health + upgrade.value)
		"shelter_upgrade":
			shelter_level += int(upgrade.value)
		"survivor_find":
			add_new_survivor("gatherer")

# --- Добавление ресурсов ---
func add_materials(amount: int):
	materials += amount
	update_ui()

func add_food(amount: int):
	food += amount
	update_ui()

func add_water(amount: int):
	water += amount
	update_ui()

# --- Функции для выживших ---
func get_survivors() -> Array[SurvivorData]:
	var alive_survivors: Array[SurvivorData] = []
	for survivor in survivor_list:
		if survivor.is_alive:
			alive_survivors.append(survivor)
	return alive_survivors

func get_battle_ready_survivors() -> Array[SurvivorData]:
	var battle_ready: Array[SurvivorData] = []
	for survivor in survivor_list:
		if survivor.is_alive and survivor.job == "guard":
			battle_ready.append(survivor)
	return battle_ready

func get_main_character() -> SurvivorData:
	return main_character

func add_new_survivor(survivor_type: String):
	var new_survivor = SurvivorData.new()
	
	match survivor_type:
		"scout":
			new_survivor.survivor_id = survivor_list.size() + 1
			new_survivor.survivor_type = "scout"
			new_survivor.specialization = "Разведчик"
			new_survivor.icon_text = "🔍"
			new_survivor.icon = load_icon_or_null(get_icon_path_for_type("scout"))
			new_survivor.health = 80
			new_survivor.max_health = 80
			new_survivor.power = 20
			new_survivor.damage = 15
			new_survivor.armor = 4
			new_survivor.food_bonus = 1.2
			new_survivor.water_bonus = 1.2
			new_survivor.guard_bonus = 1.0
		"gatherer":
			new_survivor.survivor_id = survivor_list.size() + 1
			new_survivor.survivor_type = "gatherer"
			new_survivor.specialization = "Собиратель"
			new_survivor.icon_text = "🫙"
			new_survivor.icon = load_icon_or_null(get_icon_path_for_type("gatherer"))
			new_survivor.health = 90
			new_survivor.max_health = 90
			new_survivor.power = 12
			new_survivor.damage = 10
			new_survivor.armor = 6
			new_survivor.food_bonus = 1.5
			new_survivor.water_bonus = 1.5
			new_survivor.guard_bonus = 0.8
		"observer":
			new_survivor.survivor_id = survivor_list.size() + 1
			new_survivor.survivor_type = "observer"
			new_survivor.specialization = "Наблюдатель"
			new_survivor.icon_text = "👁️"
			new_survivor.icon = load_icon_or_null(get_icon_path_for_type("observer"))
			new_survivor.health = 70
			new_survivor.max_health = 70
			new_survivor.power = 10
			new_survivor.damage = 8
			new_survivor.armor = 3
			new_survivor.food_bonus = 1.0
			new_survivor.water_bonus = 1.0
			new_survivor.guard_bonus = 1.5
		"medic":
			new_survivor.survivor_id = survivor_list.size() + 1
			new_survivor.survivor_type = "medic"
			new_survivor.specialization = "Медик"
			new_survivor.icon_text = "💊"
			new_survivor.icon = load_icon_or_null(get_icon_path_for_type("medic"))
			new_survivor.health = 100
			new_survivor.max_health = 100
			new_survivor.power = 8
			new_survivor.damage = 5
			new_survivor.armor = 4
			new_survivor.food_bonus = 0.8
			new_survivor.water_bonus = 0.8
			new_survivor.guard_bonus = 1.2
		"warrior":
			new_survivor.survivor_id = survivor_list.size() + 1
			new_survivor.survivor_type = "warrior"
			new_survivor.specialization = "Воин"
			new_survivor.icon_text = "⚔️"
			new_survivor.icon = load_icon_or_null(get_icon_path_for_type("warrior"))
			new_survivor.health = 120
			new_survivor.max_health = 120
			new_survivor.power = 25
			new_survivor.damage = 20
			new_survivor.armor = 8
			new_survivor.food_bonus = 1.0
			new_survivor.water_bonus = 1.0
			new_survivor.guard_bonus = 1.3
	
	new_survivor.job = "idle"
	new_survivor.is_alive = true
	new_survivor.character_name = get_random_survivor_name()
	survivor_list.append(new_survivor)
	save_survivors()
	update_survivor_bonuses()
	update_ui()
	
	var current = get_tree().current_scene
	if current and current.has_method("update_survivors_grid"):
		current.update_survivors_grid()
	
	# Обновляем панель квестов
	var quest_system = get_node_or_null("/root/QuestSystem")
	if quest_system:
		quest_system.update_survivor_found_progress()
	
	show_notification("👥 Новый выживший присоединился: " + new_survivor.specialization)

func get_random_survivor_name() -> String:
	var names = [
		"Алексей", "Мария", "Дмитрий", "Елена", "Сергей",
		"Анна", "Владимир", "Ольга", "Николай", "Татьяна",
		"Павел", "Наталья", "Игорь", "Светлана", "Михаил",
		"Екатерина", "Андрей", "Юлия", "Александр", "Виктория"
	]
	return names[randi() % names.size()]

# --- Чит-коды ---
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if shop_panel.visible:
			_close_shop_panel()
		elif achievements_panel.visible:
			_close_achievements_panel()
		elif cheat_panel.visible:
			_close_cheat_panel()
		else:
			toggle_pause()
	elif event.is_action_pressed("ui_save"):
		save_game()
		var dialog_data = load("res://dialogues/update_message.tres")
		if dialog_data:
			SproutyDialogs.start_dialog(dialog_data, "FIRST")
	
	if event is InputEventKey:
		if event.keycode == KEY_Q and event.shift_pressed and event.pressed:
			toggle_cheat_panel()

func toggle_cheat_panel():
	if cheat_panel:
		if cheat_panel.visible:
			_close_cheat_panel()
		else:
			_open_cheat_panel()

func _open_cheat_panel():
	var was_paused = is_paused
	if was_paused:
		resume_game()
	cheat_panel.show()
	pause_game()

func _close_cheat_panel():
	cheat_panel.hide()
	resume_game()

func _on_cheat_applied(cheat_type: String, value):
	match cheat_type:
		"food":
			food += value
			show_notification("🍖 +%d еды" % value)
		"water":
			water += value
			show_notification("💧 +%d воды" % value)
		"materials":
			materials += value
			show_notification("🔧 +%d материалов" % value)
		"health":
			health = min(100, health + value)
			show_notification("❤️ +%d здоровья" % value)
		"day":
			for i in range(value):
				_on_new_day_timeout()
			show_notification("📅 +%d дней прошло" % value)
		"all_resources":
			food += value
			water += value
			materials += value
			show_notification("⭐ +%d всех ресурсов" % value)
		"add_survivor":
			add_new_survivor(value)
		"heal_all_survivors":
			heal_all_survivors()
		"add_enemy":
			add_new_enemy(value)
		"god_mode":
			god_mode = value
			if god_mode:
				show_notification("🛡️ Режим Бога АКТИВИРОВАН")
				health = 100
			else:
				show_notification("🛡️ Режим Бога ДЕАКТИВИРОВАН")
		"kill_all":
			enemies_list.clear()
			show_notification("💀 Все враги уничтожены!")
		"update_icons":
			update_all_survivor_icons()
	
	update_ui()
	save_game()

func update_all_survivor_icons():
	print("=== Обновление иконок всех выживших ===")
	var updated = false
	
	for survivor in survivor_list:
		if survivor.icon == null:
			var icon_path = get_icon_path_for_type(survivor.survivor_type)
			if icon_path != "" and ResourceLoader.exists(icon_path):
				var texture = load(icon_path)
				if texture:
					survivor.icon = texture
					updated = true
					print("✓ Загружена иконка для ", survivor.survivor_type, " (", survivor.character_name, ")")
	
	if updated:
		save_survivors()
		var current = get_tree().current_scene
		if current and current.has_method("update_survivors_grid"):
			current.update_survivors_grid()
		update_ui()
		show_notification("🔄 Иконки выживших обновлены")

func heal_all_survivors():
	for survivor in survivor_list:
		if survivor.is_alive:
			survivor.heal(survivor.max_health)
	if main_character:
		main_character.heal(main_character.max_health)
	save_survivors()
	update_ui()
	show_notification("💊 Все выжившие вылечены!")

func add_new_enemy(enemy_type: String):
	var new_group = EnemyGroupData.new()
	new_group.group_id = enemies_list.size() + 1
	new_group.group_name = "👾 Новый отряд"
	new_group.group_icon_text = "👾"
	new_group.group_description = "Неизвестный отряд противников"
	new_group.total_reward_materials = 50
	new_group.total_reward_food = 25
	new_group.total_reward_water = 25
	new_group.danger_level = 3
	new_group.general_name = "👑 Неизвестный генерал"
	new_group.general_icon_text = "👑"
	new_group.general_health = 150
	new_group.general_power = 40
	new_group.general_damage = 20
	new_group.general_armor = 7
	new_group.general_attack_speed = 1.1
	new_group.general_description = "Таинственный предводитель"
	
	enemies_list.append(new_group)
	show_notification("👾 Появился новый отряд противников!")

func show_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.add_theme_color_override("font_color", Color.GREEN)
	notification.add_theme_font_size_override("font_size", 20)
	notification.position = Vector2(500, 300)
	notification.z_index = 100
	add_child(notification)
	
	await get_tree().create_timer(2.0).timeout
	notification.queue_free()

# --- Сохранение и загрузка ---
const SAVE_FILE_PATH = "user://savegame.save"

func get_save_data() -> Dictionary:
	return {
		"food": food,
		"water": water,
		"materials": materials,
		"health": health,
		"day": day,
		"multiplier": multiplier,
		"total_scavenged": total_scavenged,
		"total_days_survived": total_days_survived,
		"shelter_level": shelter_level,
		"survivors": survivor_list.size(),
		"purchased_upgrades": purchased_upgrades.duplicate(),
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"current_location_id": current_location.location_id if current_location else 1,
		"unlocked_locations": unlocked_locations.duplicate(),
		"version": "1.0"
	}

func save_game():
	var save_data = get_save_data()
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Игра сохранена")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("Нет сохранения. Новая игра.")
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var data_json = file.get_as_text()
		var data = JSON.parse_string(data_json)
		file.close()

		if data == null:
			print("Файл сохранения поврежден")
			return

		load_from_data(data)

func load_from_data(data: Dictionary):
	food = data.get("food", 0)
	water = data.get("water", 0)
	materials = data.get("materials", 0)
	health = data.get("health", 100.0)
	day = data.get("day", 1)
	multiplier = data.get("multiplier", 1.0)
	total_scavenged = data.get("total_scavenged", 0)
	total_days_survived = data.get("total_days_survived", 0)
	shelter_level = data.get("shelter_level", 1)
	
	var purchased = data.get("purchased_upgrades", [])
	purchased_upgrades.clear()
	for id in purchased:
		purchased_upgrades.append(int(id))
	
	for id in purchased_upgrades:
		for upgrade in upgrades_list:
			if upgrade.upgrade_id == id:
				upgrade.is_bought = true
				apply_upgrade_effect(upgrade)
	
	var unlocked = data.get("unlocked_achievements", [])
	unlocked_achievements.clear()
	for id in unlocked:
		unlocked_achievements.append(int(id))
	
	for id in unlocked_achievements:
		for achievement in achievements_list:
			if achievement.achievement_id == id:
				achievement.is_achieved = true
				multiplier *= achievement.reward_multiplier
	
	var current_loc_id = data.get("current_location_id", 1)
	for location in locations_list:
		if location.location_id == current_loc_id:
			current_location = location
			break
	
	var unlocked_locs = data.get("unlocked_locations", [1])
	unlocked_locations.clear()
	for loc_id in unlocked_locs:
		unlocked_locations.append(int(loc_id))
	
	update_ui()
	change_background()
	print("Игра загружена. День: %d" % day)

# --- Выход ---
func _on_menu_button_pressed():
	save_game()
	var dialog = ConfirmationDialog.new()
	dialog.title = "Подтверждение"
	dialog.dialog_text = "Выйти в главное меню? Текущий прогресс будет сохранен."
	dialog.ok_button_text = "Да"
	dialog.cancel_button_text = "Нет"
	dialog.confirmed.connect(_return_to_menu)
	add_child(dialog)
	dialog.popup_centered()

func _return_to_menu():
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _on_save_button_pressed():
	save_game()
	var dialog_data = load("res://dialogues/update_message.tres")
	if dialog_data:
		SproutyDialogs.start_dialog(dialog_data, "FIRST")

func add_experience_to_character(amount: int):
	if main_character:
		main_character.add_experience(amount)
		# Обновляем квесты на достижение уровня
		var quest_system = get_node_or_null("/root/QuestSystem")
		if quest_system:
			quest_system.update_level_progress(main_character.level)
		update_ui()

func _quit_game():
	save_game()
	get_tree().quit()

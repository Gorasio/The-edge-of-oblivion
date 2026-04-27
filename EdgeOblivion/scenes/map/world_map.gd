extends Control

var locations_list: Array[LocationData] = []
var current_location: LocationData = null
var quest_system = null

const LOCATIONS_FOLDER = "res://Resources/locations/"

@onready var back_button = $BackButton
@onready var tab_container = $TabContainer
@onready var location_data_panel = $LocationDataPanel
@onready var close_button = $LocationDataPanel/CloseButton
@onready var dialogue_content = $LocationDataPanel/DialoguePanel/DialogueContent
@onready var location_quests_vbox = $LocationDataPanel/LocationQuestsPanel/LocationQuestsScroll/LocationQuestsVBox
@onready var location_enemies_vbox = $LocationDataPanel/LocationEnemiesPanel/LocationEnemiesScroll/LocationEnemiesVBox

@onready var forest_grid = $TabContainer/ForestRegion/LocationsGrid
@onready var water_grid = $TabContainer/WaterRegion/LocationsGrid
@onready var mountain_grid = $TabContainer/MountainRegion/LocationsGrid
@onready var desert_grid = $TabContainer/DesertRegion/LocationsGrid

var region_mapping = {
	"forest": "forest_grid",
	"water": "water_grid",
	"mountain": "mountain_grid",
	"desert": "mountain_grid",
	"city": "mountain_grid",
	"dungeon": "mountain_grid"
}

func _ready():
	# Получаем систему квестов
	quest_system = get_node_or_null("/root/QuestSystem")
	if not quest_system:
		print("QuestSystem не найден, создаем временный")
		quest_system = load("res://scripts/quest_system.gd").new()
		add_child(quest_system)
	
	load_locations()
	setup_location_buttons()
	
	back_button.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_close_location_data_panel)
	location_data_panel.visible = false

func load_locations():
	locations_list.clear()
	
	if not DirAccess.dir_exists_absolute(LOCATIONS_FOLDER):
		print("Папка с локациями не найдена: ", LOCATIONS_FOLDER)
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
					print("Загружена локация: ", location.location_name)
					print("  - Тип: ", location.location_type)
					print("  - Сложность: ", location.difficulty)
					print("  - NPC: ", location.npc_at_location.size())
					print("  - Квестов: ", location.quests_at_location.size())
					print("  - Врагов: ", location.enemies_at_location.size())
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if locations_list.size() == 0:
		create_test_locations()

func create_test_locations():
	print("Создание тестовой локации")
	var test_location = LocationData.new()
	test_location.location_id = 1
	test_location.location_name = "🌲 Тестовый лес"
	test_location.location_description = "Тестовая локация для разработки"
	test_location.icon_text = "🌲"
	test_location.location_type = "forest"
	test_location.difficulty = "normal"
	
	# Создаем тестового NPC
	var test_npc = NPCData.new()
	test_npc.npc_id = 1
	test_npc.npc_name = "🧙 Тестовый NPC"
	test_npc.npc_description = "Тестовый персонаж"
	test_npc.npc_type = "friendly"
	test_npc.dialogues = {
		"always": {
			"dialog_resource": "res://dialogues/test_dialogue.tres",
			"dialog_branch": "FIRST"
		}
	}
	test_location.npc_at_location.append(test_npc)
	
	# Создаем тестового врага
	var test_enemy = LocationEnemyData.new()
	test_enemy.enemy_id = 1
	test_enemy.level = 1
	test_enemy.enemy_rank = "normal"
	test_location.enemies_at_location.append(test_enemy)
	
	# Создаем тестовый квест
	var test_quest = LocationQuestData.new()
	test_quest.quest_id = 1
	test_quest.quest_name = "Тестовый квест"
	test_quest.quest_description = "Проверка системы квестов"
	test_quest.quest_type = "collect"
	test_quest.is_available = true
	test_quest.target_value = 5
	test_quest.target_type = "food"
	test_location.quests_at_location.append(test_quest)
	
	locations_list.append(test_location)

func setup_location_buttons():
	for child in forest_grid.get_children():
		child.queue_free()
	for child in water_grid.get_children():
		child.queue_free()
	for child in mountain_grid.get_children():
		child.queue_free()
	for child in desert_grid.get_children():
		child.queue_free()  # Добавить
	
	for location in locations_list:
		var button = create_location_button(location)
		
		match location.location_type:
			"forest":
				forest_grid.add_child(button)
			"water":
				water_grid.add_child(button)
			"mountain":
				mountain_grid.add_child(button)
			"desert":
				desert_grid.add_child(button)  # Добавить
			_:
				forest_grid.add_child(button)

func create_location_button(location: LocationData) -> Button:
	var button = Button.new()
	var difficulty_color = get_difficulty_color(location.difficulty)
	button.text = location.location_name + "\n" + location.location_description
	button.custom_minimum_size = Vector2(260, 80)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", difficulty_color)
	button.pressed.connect(func(): _on_location_selected(location))
	return button

func get_difficulty_color(difficulty: String) -> Color:
	match difficulty:
		"easy":
			return Color.GREEN
		"normal":
			return Color.YELLOW
		"hard":
			return Color.ORANGE
		"expert":
			return Color(1.0, 0.5, 0.0, 1.0)
		"nightmare":
			return Color.RED
	return Color.WHITE

func _on_location_selected(location: LocationData):
	current_location = location
	open_location_data_panel(location)

func open_location_data_panel(location: LocationData):
	location_data_panel.visible = true
	
	for child in dialogue_content.get_children():
		child.queue_free()
	for child in location_quests_vbox.get_children():
		child.queue_free()
	for child in location_enemies_vbox.get_children():
		child.queue_free()
	
	open_dialogue_panel(location)
	open_quests_panel(location)
	open_enemies_panel(location)

# ========== ДИАЛОГИ ==========
func open_dialogue_panel(location: LocationData):
	var active_npcs = get_active_npcs_for_location(location)
	
	if active_npcs.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Нет доступных диалогов"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		dialogue_content.add_child(empty_label)
		return
	
	for npc in active_npcs:
		var dialogue_widget = create_dialogue_widget(npc)
		dialogue_content.add_child(dialogue_widget)

func get_active_npcs_for_location(location: LocationData) -> Array[NPCData]:
	var active: Array[NPCData] = []
	for npc in location.npc_at_location:
		if check_npc_spawn_conditions(npc):
			active.append(npc)
	return active

func check_npc_spawn_conditions(npc: NPCData) -> bool:
	if not quest_system:
		return true
	
	if not npc.should_spawn(quest_system):
		return false
	
	if npc.should_despawn(quest_system):
		return false
	
	return true

func create_dialogue_widget(npc: NPCData) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(380, 140)
	
	var npc_color = get_npc_color(npc.npc_type)
	var style = StyleBoxFlat.new()
	style.bg_color = npc_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)
	
	if npc.npc_portrait:
		var portrait = TextureRect.new()
		portrait.texture = npc.npc_portrait
		portrait.custom_minimum_size = Vector2(64, 64)
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(portrait)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = npc.npc_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(name_label)
	
	var type_label = Label.new()
	type_label.text = "[" + npc.npc_type.capitalize() + "]"
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", get_npc_type_color(npc.npc_type))
	vbox.add_child(type_label)
	
	var desc_label = Label.new()
	desc_label.text = npc.npc_description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(desc_label)
	
	var talk_button = Button.new()
	talk_button.text = "💬 Поговорить"
	talk_button.pressed.connect(func(): _start_dialogue(npc))
	vbox.add_child(talk_button)
	
	return panel

func get_npc_color(npc_type: String) -> Color:
	match npc_type:
		"friendly":
			return Color(0.1, 0.3, 0.1, 1)
		"neutral":
			return Color(0.2, 0.2, 0.2, 1)
		"hostile":
			return Color(0.4, 0.1, 0.1, 1)
		"merchant":
			return Color(0.3, 0.3, 0.1, 1)
		"quest_giver":
			return Color(0.2, 0.2, 0.4, 1)
	return Color(0.15, 0.15, 0.2, 1)

func get_npc_type_color(npc_type: String) -> Color:
	match npc_type:
		"friendly":
			return Color.GREEN
		"neutral":
			return Color.GRAY
		"hostile":
			return Color.RED
		"merchant":
			return Color.GOLD
		"quest_giver":
			return Color.CYAN
	return Color.WHITE

func _start_dialogue(npc: NPCData):
	if not quest_system:
		return
	
	var dialogue_info = npc.get_dialog_for_condition(quest_system)
	
	if dialogue_info.is_empty():
		show_notification("Нет диалога для этого NPC")
		return
	
	var dialog_resource_path = dialogue_info.get("dialog_resource", "")
	var dialog_branch = dialogue_info.get("dialog_branch", "FIRST")
	
	if dialog_resource_path != "":
		var dialog_data = load(dialog_resource_path)
		if dialog_data:
			SproutyDialogs.start_dialog(dialog_data, dialog_branch)
			
			if not npc.reward_on_dialogue.is_empty():
				var main = get_tree().root.get_node_or_null("Main")
				if main:
					if npc.reward_on_dialogue.has("food"):
						main.add_food(npc.reward_on_dialogue["food"])
					if npc.reward_on_dialogue.has("water"):
						main.add_water(npc.reward_on_dialogue["water"])
					if npc.reward_on_dialogue.has("materials"):
						main.add_materials(npc.reward_on_dialogue["materials"])
			
			var quest_id = npc.get_active_quest_id(quest_system)
			if quest_id != -1:
				await get_tree().create_timer(0.5).timeout
				_take_quest_by_id(quest_id)
			
			await get_tree().create_timer(0.5).timeout
			open_dialogue_panel(current_location)

# ========== КВЕСТЫ ==========
func open_quests_panel(location: LocationData):
	if location.quests_at_location.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Нет доступных квестов"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		location_quests_vbox.add_child(empty_label)
		return
	
	for quest_data in location.quests_at_location:
		if should_show_quest(quest_data):
			var quest_widget = create_quest_widget(quest_data)
			location_quests_vbox.add_child(quest_widget)

func should_show_quest(quest_data: LocationQuestData) -> bool:
	if quest_data.is_completed:
		return false
	
	if quest_data.is_active:
		return true
	
	if not quest_data.is_available:
		return false
	
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.main_character:
		if main.main_character.level < quest_data.required_level:
			return false
	
	if quest_data.required_quest_id != -1 and quest_system:
		if not quest_system.is_quest_completed(quest_data.required_quest_id):
			return false
	
	return true

func create_quest_widget(quest_data: LocationQuestData) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(380, 100)
	
	var style = StyleBoxFlat.new()
	if quest_data.is_active:
		style.bg_color = Color(0.2, 0.4, 0.2, 1)
		style.border_color = Color(0.3, 0.8, 0.3, 1)
	elif quest_data.is_available:
		style.bg_color = Color(0.2, 0.3, 0.2, 1)
		style.border_color = Color(0.3, 0.5, 0.3, 1)
	else:
		style.bg_color = Color(0.15, 0.15, 0.2, 1)
		style.border_color = Color(0.3, 0.3, 0.4, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = quest_data.quest_name
	title_label.add_theme_font_size_override("font_size", 15)
	if quest_data.is_active:
		title_label.add_theme_color_override("font_color", Color.YELLOW)
	elif quest_data.is_available:
		title_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		title_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = quest_data.quest_description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color.GRAY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	var type_label = Label.new()
	type_label.text = "Тип: " + quest_data.quest_type.capitalize() + " | Цель: " + quest_data.target_type.capitalize()
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(type_label)
	
	if quest_data.is_active and not quest_data.is_completed:
		var progress_label = Label.new()
		progress_label.text = "Прогресс: " + quest_data.get_progress_text()
		progress_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(progress_label)
		
		var progress_bar = ProgressBar.new()
		progress_bar.value = quest_data.get_progress_percent()
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(progress_bar)
		
		if quest_data.current_stage > 0 and quest_data.current_stage <= quest_data.stages.size():
			var stage = quest_data.get_current_stage_data()
			if stage:
				var stage_label = Label.new()
				stage_label.text = "📌 Этап " + str(quest_data.current_stage) + ": " + stage.stage_name
				stage_label.add_theme_font_size_override("font_size", 10)
				stage_label.add_theme_color_override("font_color", Color.ORANGE)
				vbox.add_child(stage_label)
	
	elif quest_data.is_available and not quest_data.is_active:
		var take_button = Button.new()
		take_button.text = "📋 Взять квест"
		take_button.pressed.connect(func(): _take_quest(quest_data))
		vbox.add_child(take_button)
	
	elif quest_data.is_completed:
		var completed_label = Label.new()
		completed_label.text = "✓ ЗАВЕРШЕН"
		completed_label.add_theme_color_override("font_color", Color.GREEN)
		completed_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(completed_label)
	
	return panel

func _take_quest(quest_data: LocationQuestData):
	if not quest_system:
		return
	
	quest_system.activate_quest(quest_data)
	
	for npc_id in quest_data.npc_on_start:
		spawn_npc_by_id(npc_id)
	
	if not quest_data.dialogue_on_start.is_empty():
		start_dialogue(quest_data.dialogue_on_start)
	
	show_notification("Квест '" + quest_data.quest_name + "' взят!")
	_close_location_data_panel()

func _take_quest_by_id(quest_id: int):
	for location in locations_list:
		for quest_data in location.quests_at_location:
			if quest_data.quest_id == quest_id:
				_take_quest(quest_data)
				return

func start_dialogue(dialogue_info: Dictionary):
	var dialog_resource_path = dialogue_info.get("dialog_resource", "")
	var dialog_branch = dialogue_info.get("dialog_branch", "FIRST")
	
	if dialog_resource_path != "":
		var dialog_data = load(dialog_resource_path)
		if dialog_data:
			SproutyDialogs.start_dialog(dialog_data, dialog_branch)

func spawn_npc_by_id(npc_id: int):
	for location in locations_list:
		for npc in location.npc_at_location:
			if npc.npc_id == npc_id:
				npc.spawn_condition = "always"
				break
	
	if current_location:
		open_dialogue_panel(current_location)

func despawn_npc_by_id(npc_id: int):
	for location in locations_list:
		for i in range(location.npc_at_location.size()):
			if location.npc_at_location[i].npc_id == npc_id:
				location.npc_at_location.remove_at(i)
				break
	
	if current_location:
		open_dialogue_panel(current_location)

# ========== ВРАГИ ==========
func open_enemies_panel(location: LocationData):
	if location.enemies_at_location.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Нет врагов в этой локации"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		location_enemies_vbox.add_child(empty_label)
		return
	
	for enemy_data in location.enemies_at_location:
		var enemy_widget = create_enemy_widget(enemy_data)
		location_enemies_vbox.add_child(enemy_widget)

func create_enemy_widget(enemy_data: LocationEnemyData) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(380, 140)
	
	var enemy_color = get_enemy_color(enemy_data.enemy_rank)
	var style = StyleBoxFlat.new()
	style.bg_color = enemy_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var group_name = enemy_data.get_group_name() if enemy_data.has_method("get_group_name") else "Неизвестный враг"
	var group_icon = enemy_data.get_group_icon() if enemy_data.has_method("get_group_icon") else "👾"
	var rank_text = enemy_data.enemy_rank.capitalize()
	
	var name_label = Label.new()
	name_label.text = group_icon + " " + group_name + " [" + rank_text + "] (Уровень: " + str(enemy_data.level) + ")"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", get_enemy_text_color(enemy_data.enemy_rank))
	vbox.add_child(name_label)
	
	if enemy_data.enemy_group:
		var group_info = Label.new()
		var total_enemies = enemy_data.enemy_group.get_total_enemies_count()
		group_info.text = "📊 Состав: " + str(total_enemies) + " врагов | Опасность: " + str(enemy_data.enemy_group.danger_level)
		group_info.add_theme_font_size_override("font_size", 10)
		group_info.add_theme_color_override("font_color", Color.CYAN)
		vbox.add_child(group_info)
		
		var general_info = Label.new()
		general_info.text = "👑 Генерал: " + enemy_data.enemy_group.general_name + " (❤️ " + str(enemy_data.enemy_group.general_health) + ")"
		general_info.add_theme_font_size_override("font_size", 10)
		general_info.add_theme_color_override("font_color", Color.ORANGE)
		vbox.add_child(general_info)
	
	if enemy_data.is_defeated:
		var defeated_label = Label.new()
		defeated_label.text = "💀 Повержен (возрождение через " + str(enemy_data.respawn_time) + " сек)"
		defeated_label.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(defeated_label)
		
		var disabled_button = Button.new()
		disabled_button.text = "⏳ Ожидание возрождения"
		disabled_button.disabled = true
		vbox.add_child(disabled_button)
	else:
		var is_available = enemy_data.is_available() if enemy_data.has_method("is_available") else true
		var availability_text = "⚠️ Активен" if is_available else "❌ Не появился (шанс: " + str(enemy_data.spawn_chance * 100) + "%)"
		var info_label = Label.new()
		info_label.text = availability_text
		info_label.add_theme_color_override("font_color", Color.RED if is_available else Color.ORANGE)
		vbox.add_child(info_label)
		
		if is_available:
			var rewards = enemy_data.get_total_reward() if enemy_data.has_method("get_total_reward") else {"materials": 0, "food": 0, "water": 0}
			var reward_label = Label.new()
			reward_label.text = "🏆 Награда: 🔧" + str(rewards["materials"]) + " 🍖" + str(rewards["food"]) + " 💧" + str(rewards["water"])
			reward_label.add_theme_font_size_override("font_size", 11)
			reward_label.add_theme_color_override("font_color", Color.GREEN)
			vbox.add_child(reward_label)
			
			var attack_button = Button.new()
			attack_button.text = "⚔️ АТАКОВАТЬ ОТРЯД!"
			attack_button.add_theme_font_size_override("font_size", 14)
			attack_button.custom_minimum_size = Vector2(150, 35)
			attack_button.pressed.connect(func(): _attack_enemy_group(enemy_data))
			vbox.add_child(attack_button)
		else:
			var disabled_button = Button.new()
			disabled_button.text = "❌ Недоступен"
			disabled_button.disabled = true
			vbox.add_child(disabled_button)
	
	return panel

func get_enemy_color(rank: String) -> Color:
	match rank:
		"normal":
			return Color(0.3, 0.2, 0.2, 1)
		"elite":
			return Color(0.4, 0.2, 0.1, 1)
		"boss":
			return Color(0.5, 0.1, 0.1, 1)
		"general":
			return Color(0.6, 0.1, 0.1, 1)
	return Color(0.3, 0.2, 0.2, 1)

func get_enemy_text_color(rank: String) -> Color:
	match rank:
		"normal":
			return Color.RED
		"elite":
			return Color.ORANGE
		"boss":
			return Color(1.0, 0.5, 0.0, 1.0)
		"general":
			return Color(1.0, 0.8, 0.2, 1.0)
	return Color.RED

func _attack_enemy_group(enemy_data: LocationEnemyData):
	if not enemy_data:
		show_notification("Ошибка: данные врага не найдены")
		return
	
	var enemy_group = enemy_data.get_enemy_group() if enemy_data.has_method("get_enemy_group") else null
	if not enemy_group:
		show_notification("Ошибка: группа врагов не найдена")
		return
	
	var main = get_tree().root.get_node_or_null("Main")
	if not main:
		show_notification("Ошибка: главная сцена не найдена")
		return
	
	if not main.has_method("get_enemy_types"):
		show_notification("Ошибка: система врагов не инициализирована")
		return
	
	var enemy_types_dict = main.get_enemy_types()
	var battle_group = enemy_group.expand_group(enemy_types_dict)
	
	if battle_group.is_empty():
		show_notification("Ошибка: не удалось создать отряд противников")
		return
	
	_close_location_data_panel()
	
	var battle_ready_survivors = main.get_battle_ready_survivors() if main.has_method("get_battle_ready_survivors") else []
	var player_general = main.get_main_character() if main.has_method("get_main_character") else null
	
	var battle_scene = preload("res://scenes/BattleScene.tscn").instantiate()
	battle_scene.player_survivors = battle_ready_survivors
	battle_scene.player_general = player_general
	battle_scene.enemy_group = battle_group
	battle_scene.location_enemy_data = enemy_data
	battle_scene.battle_ended.connect(func(victory): _on_battle_ended(victory, enemy_data))
	
	get_tree().root.add_child(battle_scene)
	get_tree().current_scene = battle_scene
	hide()

func _on_battle_ended(victory: bool, enemy_data: LocationEnemyData):
	show()
	
	if victory:
		enemy_data.is_defeated = true
		var group_name = enemy_data.get_group_name() if enemy_data.has_method("get_group_name") else "Враг"
		show_notification("Победа! Враг " + group_name + " повержен!")
		
		if enemy_data.respawn_time > 0:
			await get_tree().create_timer(enemy_data.respawn_time).timeout
			enemy_data.is_defeated = false
			show_notification("Враг " + group_name + " возродился!")
			
			if current_location and location_data_panel.visible:
				open_enemies_panel(current_location)
	else:
		var group_name = enemy_data.get_group_name() if enemy_data.has_method("get_group_name") else "Враг"
		show_notification("Поражение... Враг " + group_name + " остался непобежденным!")
	
	if current_location and location_data_panel.visible:
		open_enemies_panel(current_location)

func _close_location_data_panel():
	location_data_panel.visible = false

func show_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.add_theme_color_override("font_color", Color.GREEN)
	notification.add_theme_font_size_override("font_size", 16)
	notification.position = Vector2(500, 300)
	add_child(notification)
	
	await get_tree().create_timer(2.0).timeout
	notification.queue_free()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

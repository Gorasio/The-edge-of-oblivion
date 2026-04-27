extends Control

signal character_created(character_data)

var selected_portrait: Texture2D = null
var selected_specialization: String = "commander"
var selected_specialization_name: String = "Командир"
var portrait_display_size = 160

# Бонусы для выбранной специализации
var selected_food_bonus: float = 1.0
var selected_water_bonus: float = 1.0
var selected_guard_bonus: float = 1.0

@onready var portrait_texture = $PortraitPanel/Portrait
@onready var portrait_button = $PortraitPanel/PortraitButton
@onready var name_input = $NamePanel/NameInput
@onready var create_button = $CreateButton
@onready var back_button = $BackButton

@onready var scout_button = $SpecializationPanel/SpecializationGrid/ScoutButton
@onready var gatherer_button = $SpecializationPanel/SpecializationGrid/GathererButton
@onready var observer_button = $SpecializationPanel/SpecializationGrid/ObserverButton
@onready var medic_button = $SpecializationPanel/SpecializationGrid/MedicButton
@onready var commander_button = $SpecializationPanel/SpecializationGrid/CommanderButton
@onready var warrior_button = $SpecializationPanel/SpecializationGrid/WarriorButton

func _ready():
	set_default_portrait()
	setup_specialization_buttons()
	
	# Подключаем сигналы
	portrait_button.pressed.connect(_on_portrait_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	scout_button.pressed.connect(func(): select_specialization("scout", "Разведчик", 1.2, 1.2, 1.0))
	gatherer_button.pressed.connect(func(): select_specialization("gatherer", "Собиратель", 1.5, 1.5, 0.8))
	observer_button.pressed.connect(func(): select_specialization("observer", "Наблюдатель", 1.0, 1.0, 1.5))
	medic_button.pressed.connect(func(): select_specialization("medic", "Медик", 0.8, 0.8, 1.2))
	commander_button.pressed.connect(func(): select_specialization("commander", "Командир", 1.0, 1.0, 1.5))
	warrior_button.pressed.connect(func(): select_specialization("warrior", "Воин", 1.0, 1.0, 1.3))

func setup_specialization_buttons():
	if scout_button:
		scout_button.text = "🔍 Разведчик\n+20% к добыче"
	if gatherer_button:
		gatherer_button.text = "🫙 Собиратель\n+50% к сбору ресурсов"
	if observer_button:
		observer_button.text = "👁️ Наблюдатель\n+50% к охране"
	if medic_button:
		medic_button.text = "💊 Медик\n+20% к лечению"
	if commander_button:
		commander_button.text = "⭐ Командир\n+50% к силе отряда"
	if warrior_button:
		warrior_button.text = "⚔️ Воин\n+30% к атаке"
	
	select_specialization("commander", "Командир", 1.0, 1.0, 1.5)
	highlight_button(commander_button)

func set_default_portrait():
	selected_portrait = create_placeholder_portrait()
	update_portrait_display()

func create_placeholder_portrait() -> Texture2D:
	var size = portrait_display_size
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.3, 0.4, 1))
	
	var face_size = size * 0.5
	var face_x = (size - face_size) / 2
	var face_y = (size - face_size) / 3
	
	image.fill_rect(Rect2i(face_x, face_y, face_size, face_size), Color(0.9, 0.7, 0.5, 1))
	
	var eye_size = size * 0.08
	var eye_y = face_y + face_size * 0.4
	var eye1_x = face_x + face_size * 0.25
	var eye2_x = face_x + face_size * 0.65
	
	image.fill_rect(Rect2i(eye1_x, eye_y, eye_size, eye_size), Color(0.1, 0.1, 0.1, 1))
	image.fill_rect(Rect2i(eye2_x, eye_y, eye_size, eye_size), Color(0.1, 0.1, 0.1, 1))
	
	var mouth_y = face_y + face_size * 0.7
	var mouth_width = face_size * 0.35
	var mouth_x = face_x + (face_size - mouth_width) / 2
	image.fill_rect(Rect2i(mouth_x, mouth_y, mouth_width, eye_size), Color(0.5, 0.3, 0.2, 1))
	
	return ImageTexture.create_from_image(image)

func update_portrait_display():
	if portrait_texture and selected_portrait:
		var preview = create_preview_texture(selected_portrait, portrait_display_size)
		portrait_texture.texture = preview

func create_preview_texture(original_texture: Texture2D, target_size: int) -> Texture2D:
	var original_size = original_texture.get_size()
	var image = Image.create(target_size, target_size, false, Image.FORMAT_RGBA8)
	var original_image = original_texture.get_image()
	
	var scale = min(float(target_size) / original_size.x, float(target_size) / original_size.y)
	var new_width = int(original_size.x * scale)
	var new_height = int(original_size.y * scale)
	
	original_image.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
	
	var offset_x = (target_size - new_width) / 2
	var offset_y = (target_size - new_height) / 2
	
	image.blit_rect(original_image, Rect2i(0, 0, new_width, new_height), Vector2i(offset_x, offset_y))
	
	return ImageTexture.create_from_image(image)

func _on_portrait_button_pressed():
	var picker_scene = preload("res://scenes/PortraitPicker.tscn").instantiate()
	picker_scene.portrait_selected.connect(_on_portrait_selected)
	picker_scene.closed.connect(func(): picker_scene.queue_free())
	add_child(picker_scene)

func _on_portrait_selected(portrait: Texture2D):
	selected_portrait = portrait
	update_portrait_display()

func select_specialization(type: String, name: String, food_bonus: float, water_bonus: float, guard_bonus: float):
	selected_specialization = type
	selected_specialization_name = name
	selected_food_bonus = food_bonus
	selected_water_bonus = water_bonus
	selected_guard_bonus = guard_bonus
	
	reset_button_highlight()
	
	match type:
		"scout":
			highlight_button(scout_button)
		"gatherer":
			highlight_button(gatherer_button)
		"observer":
			highlight_button(observer_button)
		"medic":
			highlight_button(medic_button)
		"commander":
			highlight_button(commander_button)
		"warrior":
			highlight_button(warrior_button)

func highlight_button(button: Button):
	if not button:
		return
	button.add_theme_color_override("font_color", Color.GREEN)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 0.2, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GREEN
	button.add_theme_stylebox_override("normal", style)

func reset_button_highlight():
	var buttons = [scout_button, gatherer_button, observer_button, medic_button, commander_button, warrior_button]
	for button in buttons:
		if button:
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_stylebox_override("normal", null)

func _on_create_button_pressed():
	var character_name = name_input.text.strip_edges()
	if character_name == "":
		character_name = "Выживший"
	
	var character = SurvivorData.new()
	character.survivor_id = 0
	character.survivor_type = selected_specialization
	character.character_name = character_name
	character.specialization = selected_specialization_name
	character.icon = selected_portrait
	character.icon_text = get_icon_for_specialization(selected_specialization)
	character.description = get_description_for_specialization(selected_specialization)
	character.max_health = 150
	character.health = 150
	character.power = 50
	character.damage = 30
	character.armor = 10
	character.attack_speed = 1.2
	character.job = "guard"
	
	character.food_bonus = selected_food_bonus
	character.water_bonus = selected_water_bonus
	character.guard_bonus = selected_guard_bonus
	
	if selected_specialization == "warrior":
		character.damage = 40
		character.power = 60
	elif selected_specialization == "commander":
		character.power = 60
	
	# Сохраняем персонажа
	save_character(character)
	save_character_portrait(selected_portrait)
	
	# Переходим в главную сцену (создаем новую игру)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func save_character(character: SurvivorData):
	var save_path = "user://character.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"name": character.character_name,
			"type": character.survivor_type,
			"specialization": character.specialization,
			"health": character.health,
			"max_health": character.max_health,
			"power": character.power,
			"damage": character.damage,
			"armor": character.armor,
			"food_bonus": character.food_bonus,
			"water_bonus": character.water_bonus,
			"guard_bonus": character.guard_bonus
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Персонаж сохранен")

func save_character_portrait(portrait: Texture2D):
	if not portrait:
		return
	
	var save_path = "user://character_portrait.png"
	var image = portrait.get_image()
	if image:
		image.save_png(save_path)
		print("Портрет сохранен")

func _on_back_button_pressed():
	# Возвращаемся в главное меню
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func get_icon_for_specialization(type: String) -> String:
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

func get_description_for_specialization(type: String) -> String:
	match type:
		"scout":
			return "Опытный разведчик, знающий местность"
		"gatherer":
			return "Умелый собиратель ресурсов"
		"observer":
			return "Внимательный наблюдатель, замечающий опасность"
		"medic":
			return "Опытный медик, лечащий раненых"
		"warrior":
			return "Отважный воин, мастер ближнего боя"
	return "Харизматичный лидер, вдохновляющий отряд"

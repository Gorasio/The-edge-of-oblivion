extends Control

@onready var slot1_container = $SlotsContainer/VBoxContainer/Slot1Container
@onready var slot2_container = $SlotsContainer/VBoxContainer/Slot2Container
@onready var slot3_container = $SlotsContainer/VBoxContainer/Slot3Container
@onready var back_button = $SlotsContainer/VBoxContainer/BackButton

const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

var slots = {
	"slot1": {
		"path": "user://save_slot_1.save",
		"label": null,
		"save_btn": null,
		"load_btn": null
	},
	"slot2": {
		"path": "user://save_slot_2.save",
		"label": null,
		"save_btn": null,
		"load_btn": null
	},
	"slot3": {
		"path": "user://save_slot_3.save",
		"label": null,
		"save_btn": null,
		"load_btn": null
	}
}

func _ready():
	initialize_slots()
	refresh_slot_info()
	back_button.pressed.connect(_on_back_button_pressed)

func initialize_slots():
	# Слот 1
	slots["slot1"]["label"] = $SlotsContainer/VBoxContainer/Slot1Container/Slot1Label
	slots["slot1"]["save_btn"] = $SlotsContainer/VBoxContainer/Slot1Container/SaveToSlot1Button
	slots["slot1"]["load_btn"] = $SlotsContainer/VBoxContainer/Slot1Container/LoadFromSlot1Button
	
	# Слот 2
	slots["slot2"]["label"] = $SlotsContainer/VBoxContainer/Slot2Container/Slot2Label
	slots["slot2"]["save_btn"] = $SlotsContainer/VBoxContainer/Slot2Container/SaveToSlot2Button
	slots["slot2"]["load_btn"] = $SlotsContainer/VBoxContainer/Slot2Container/LoadFromSlot2Button
	
	# Слот 3
	slots["slot3"]["label"] = $SlotsContainer/VBoxContainer/Slot3Container/Slot3Label
	slots["slot3"]["save_btn"] = $SlotsContainer/VBoxContainer/Slot3Container/SaveToSlot3Button
	slots["slot3"]["load_btn"] = $SlotsContainer/VBoxContainer/Slot3Container/LoadFromSlot3Button
	
	# Подключаем сигналы
	for slot_key in slots:
		var slot = slots[slot_key]
		slot["save_btn"].pressed.connect(_on_save_button_pressed.bind(slot_key))
		slot["load_btn"].pressed.connect(_on_load_button_pressed.bind(slot_key))

func refresh_slot_info():
	for slot_key in slots:
		update_slot_info(slot_key)

func update_slot_info(slot_key: String):
	var slot = slots[slot_key]
	var path = slot["path"]
	var label = slot["label"]
	var load_btn = slot["load_btn"]
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data_json = file.get_as_text()
		var data = JSON.parse_string(data_json)
		file.close()
		
		if data and data.has("day"):
			var day = data.get("day", 1)
			var survivors = data.get("survivors", 1)
			var time = FileAccess.get_modified_time(path)
			var date_str = Time.get_datetime_string_from_unix_time(time).substr(0, 10)
			
			label.text = "📁 Слот %s: День %d | 👥 %d | %s" % [
				slot_key.replace("slot", ""),
				day,
				survivors,
				date_str
			]
			load_btn.disabled = false
		else:
			label.text = "⚠️ Слот %s: (ошибка)" % slot_key.replace("slot", "")
			load_btn.disabled = true
	else:
		label.text = "📂 Слот %s: (пусто)" % slot_key.replace("slot", "")
		load_btn.disabled = true

func _on_save_button_pressed(slot_key: String):
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_save_data"):
		var data = main_scene.get_save_data()
		var path = slots[slot_key]["path"]
		
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		
		print("💾 Сохранено в %s" % slot_key)
		refresh_slot_info()
		
		# Показываем уведомление
		show_notification("Игра сохранена в слот %s" % slot_key.replace("slot", ""))

func _on_load_button_pressed(slot_key: String):
	var path = slots[slot_key]["path"]
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data_json = file.get_as_text()
		var data = JSON.parse_string(data_json)
		file.close()
		
		if data:
			# Загружаем сцену и передаем данные
			var main_scene = load(MAIN_SCENE_PATH).instantiate()
			main_scene.loading_from_slot = true
			main_scene.slot_data_to_load = data
			get_tree().root.add_child(main_scene)
			get_tree().current_scene = main_scene
			queue_free()  # Закрываем меню сохранений
		else:
			show_notification("Ошибка загрузки слота", true)

func show_notification(text: String, is_error: bool = false):
	var notification = Label.new()
	notification.text = text
	notification.add_theme_color_override("font_color", Color.RED if is_error else Color.GREEN)
	notification.add_theme_font_size_override("font_size", 20)
	notification.position = Vector2(400, 300)
	add_child(notification)
	
	await get_tree().create_timer(2.0).timeout
	notification.queue_free()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

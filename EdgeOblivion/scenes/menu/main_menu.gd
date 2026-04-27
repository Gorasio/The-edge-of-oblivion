extends Control

@onready var new_game_button: Button = $MenuContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $MenuContainer/VBoxContainer/ContinueButton
@onready var load_button: Button = $MenuContainer/VBoxContainer/LoadButton
@onready var options_button: Button = $MenuContainer/VBoxContainer/OptionsButton
@onready var about_button: Button = $MenuContainer/VBoxContainer/AboutButton
@onready var quit_button: Button = $MenuContainer/VBoxContainer/QuitButton

const SAVE_FILE_PATH = "user://savegame.save"
const CHARACTER_SAVE_PATH = "user://character.save"
const CHARACTER_EDITOR_PATH = "res://scenes/CharacterEditor.tscn"
const MAIN_SCENE_PATH = "res://scenes/Main.tscn"
const SAVE_LOAD_MENU_PATH = "res://scenes/menu/SaveLoadMenu.tscn"
const ABOUT_PAGE_PATH = "res://scenes/menu/AboutPage.tscn"

func _ready():
	update_buttons()
	
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	about_button.pressed.connect(_on_about_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func update_buttons():
	var save_exists = FileAccess.file_exists(SAVE_FILE_PATH)
	var character_exists = FileAccess.file_exists(CHARACTER_SAVE_PATH)
	
	continue_button.disabled = not (save_exists and character_exists)
	
	var any_slot_exists = false
	for i in range(1, 4):
		if FileAccess.file_exists("user://save_slot_%d.save" % i):
			any_slot_exists = true
			break
	
	load_button.disabled = not any_slot_exists

func _on_new_game_button_pressed():
	var dialog = ConfirmationDialog.new()
	dialog.title = "Новая игра"
	dialog.dialog_text = "Начать новую игру? Текущий прогресс будет потерян.\nВам нужно будет создать нового персонажа."
	dialog.ok_button_text = "Да"
	dialog.cancel_button_text = "Нет"
	dialog.confirmed.connect(_start_new_game)
	add_child(dialog)
	dialog.popup_centered()

func _start_new_game():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	
	if FileAccess.file_exists(CHARACTER_SAVE_PATH):
		DirAccess.remove_absolute(CHARACTER_SAVE_PATH)
	
	var portrait_path = "user://character_portrait.png"
	if FileAccess.file_exists(portrait_path):
		DirAccess.remove_absolute(portrait_path)
	
	get_tree().change_scene_to_file(CHARACTER_EDITOR_PATH)

func _on_continue_button_pressed():
	if FileAccess.file_exists(SAVE_FILE_PATH) and FileAccess.file_exists(CHARACTER_SAVE_PATH):
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	else:
		if not FileAccess.file_exists(SAVE_FILE_PATH):
			show_notification("Нет сохраненной игры!")
		elif not FileAccess.file_exists(CHARACTER_SAVE_PATH):
			show_notification("Нет сохраненного персонажа! Начните новую игру.")

func _on_load_button_pressed():
	get_tree().change_scene_to_file(SAVE_LOAD_MENU_PATH)

func _on_options_button_pressed():
	show_notification("Настройки будут доступны в следующем обновлении")

func _on_about_button_pressed():
	get_tree().change_scene_to_file(ABOUT_PAGE_PATH)

func _on_quit_button_pressed():
	var dialog = ConfirmationDialog.new()
	dialog.title = "Выход"
	dialog.dialog_text = "Выйти из игры?"
	dialog.ok_button_text = "Да"
	dialog.cancel_button_text = "Нет"
	dialog.confirmed.connect(_quit_game)
	add_child(dialog)
	dialog.popup_centered()

func _quit_game():
	get_tree().quit()

func show_notification(text: String):
	var notification = Label.new()
	notification.text = text
	notification.add_theme_color_override("font_color", Color.YELLOW)
	notification.add_theme_font_size_override("font_size", 24)
	notification.position = Vector2(400, 400)
	add_child(notification)
	
	await get_tree().create_timer(2.0).timeout
	notification.queue_free()

extends Panel

signal resume_game
signal save_game
signal quit_to_menu
signal quit_game

@onready var resume_button = $ResumeButton
@onready var save_button = $SaveButton
@onready var menu_button = $MenuButtonPause
@onready var quit_button = $QuitButton

func _ready():
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	resume_game.emit()
	hide()

func _on_save_pressed():
	save_game.emit()

func _on_menu_pressed():
	quit_to_menu.emit()

func _on_quit_pressed():
	quit_game.emit()

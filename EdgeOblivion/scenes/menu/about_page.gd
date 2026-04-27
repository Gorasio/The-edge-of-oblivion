extends Control

@onready var back_button = $BackButton
@onready var tab_container = $TabContainer

func _ready():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

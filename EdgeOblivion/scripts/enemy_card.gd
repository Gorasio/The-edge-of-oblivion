extends Button

signal enemy_selected

var enemy_data: EnemyData = null

var icon_label: Label
var name_label: Label
var power_label: Label
var health_label: Label

func _init():
	custom_minimum_size = Vector2(200, 120)
	size = Vector2(200, 120)
	
	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(200, 120)
	bg.color = Color(0.3, 0.2, 0.2, 1)
	add_child(bg)
	
	# Иконка
	icon_label = Label.new()
	icon_label.position = Vector2(10, 20)
	icon_label.size = Vector2(60, 60)
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(icon_label)
	
	# Имя
	name_label = Label.new()
	name_label.position = Vector2(80, 15)
	name_label.size = Vector2(110, 25)
	name_label.add_theme_font_size_override("font_size", 14)
	add_child(name_label)
	
	# Здоровье
	health_label = Label.new()
	health_label.position = Vector2(80, 45)
	health_label.size = Vector2(110, 20)
	health_label.add_theme_font_size_override("font_size", 12)
	add_child(health_label)
	
	# Сила
	power_label = Label.new()
	power_label.position = Vector2(80, 70)
	power_label.size = Vector2(110, 20)
	power_label.add_theme_font_size_override("font_size", 12)
	add_child(power_label)

func setup(data: EnemyData):
	enemy_data = data
	
	icon_label.text = data.icon_text
	name_label.text = data.name
	health_label.text = "❤️ %d" % data.health
	power_label.text = "⚔️ %d" % data.power
	
	pressed.connect(_on_pressed)

func _on_pressed():
	enemy_selected.emit(enemy_data)

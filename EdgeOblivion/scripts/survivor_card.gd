extends Panel

signal job_changed

var survivor_data: SurvivorData = null

var icon_texture: TextureRect
var name_label: Label
var specialization_label: Label
var health_label: Label
var power_label: Label
var job_button: Button
var background: ColorRect
var dead_overlay: ColorRect

func _init():
	custom_minimum_size = Vector2(320, 140)
	size = Vector2(320, 140)
	
	background = ColorRect.new()
	background.size = Vector2(320, 140)
	background.position = Vector2(0, 0)
	background.color = Color(0.2, 0.2, 0.3, 1)
	add_child(background)
	
	# Оверлей для мертвых выживших
	dead_overlay = ColorRect.new()
	dead_overlay.size = Vector2(320, 140)
	dead_overlay.position = Vector2(0, 0)
	dead_overlay.color = Color(0.5, 0.2, 0.2, 0.7)
	dead_overlay.visible = false
	add_child(dead_overlay)
	
	icon_texture = TextureRect.new()
	icon_texture.size = Vector2(100, 100)
	icon_texture.position = Vector2(15, 20)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon_texture)
	
	var info_container = VBoxContainer.new()
	info_container.position = Vector2(130, 20)
	info_container.size = Vector2(175, 100)
	add_child(info_container)
	
	specialization_label = Label.new()
	specialization_label.size = Vector2(175, 24)
	specialization_label.add_theme_font_size_override("font_size", 14)
	specialization_label.add_theme_color_override("font_color", Color.YELLOW)
	info_container.add_child(specialization_label)
	
	name_label = Label.new()
	name_label.size = Vector2(175, 26)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_container.add_child(name_label)
	
	health_label = Label.new()
	health_label.size = Vector2(175, 22)
	health_label.add_theme_font_size_override("font_size", 13)
	info_container.add_child(health_label)
	
	power_label = Label.new()
	power_label.size = Vector2(175, 22)
	power_label.add_theme_font_size_override("font_size", 13)
	info_container.add_child(power_label)
	
	job_button = Button.new()
	job_button.position = Vector2(15, 125)
	job_button.size = Vector2(290, 35)
	job_button.add_theme_font_size_override("font_size", 14)
	job_button.pressed.connect(_on_job_button_pressed)
	add_child(job_button)

func setup(data: SurvivorData):
	survivor_data = data
	
	# Устанавливаем иконку
	if data.icon != null and data.icon is Texture2D:
		icon_texture.texture = data.icon
	else:
		icon_texture.texture = null
	
	# Текстовая информация
	specialization_label.text = data.specialization
	name_label.text = data.character_name
	health_label.text = "❤️ %d/%d" % [data.health, data.max_health]
	power_label.text = "⚔️ %d  🛡️ %d" % [data.power, data.armor]
	
	# Если выживший мертв
	if not data.is_alive:
		dead_overlay.visible = true
		job_button.disabled = true
		job_button.text = "💀 ПОГИБ"
		background.color = Color(0.3, 0.2, 0.2, 1)
	else:
		dead_overlay.visible = false
		job_button.disabled = false
		update_job_button()
		
		# Цвет фона в зависимости от специализации
		match data.survivor_type:
			"scout":
				background.color = Color(0.2, 0.4, 0.3, 1)
			"gatherer":
				background.color = Color(0.3, 0.5, 0.2, 1)
			"observer":
				background.color = Color(0.2, 0.3, 0.5, 1)
			"medic":
				background.color = Color(0.4, 0.2, 0.4, 1)
			"warrior":
				background.color = Color(0.5, 0.3, 0.2, 1)
			_:
				background.color = Color(0.2, 0.2, 0.3, 1)

func update_job_button():
	if survivor_data and survivor_data.is_alive:
		job_button.text = survivor_data.get_job_text()

func _on_job_button_pressed():
	if not survivor_data or not survivor_data.is_alive:
		return
	
	var jobs = ["idle", "food", "water", "guard"]
	var current_index = jobs.find(survivor_data.job)
	var next_index = (current_index + 1) % jobs.size()
	survivor_data.job = jobs[next_index]
	update_job_button()
	job_changed.emit()

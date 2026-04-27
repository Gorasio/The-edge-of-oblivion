extends Button

var unit_data = null
var current_health = 0
var is_player = false
var unit_name: String = ""
var attack_cooldown = 0.0

# Дочерние узлы
var icon_texture: TextureRect
var icon_label: Label
var name_label: Label
var health_bar: ProgressBar
var health_label: Label
var power_label: Label
var armor_label: Label
var background: ColorRect

func _init():
	# Настройка кнопки
	custom_minimum_size = Vector2(120, 140)
	size = Vector2(120, 140)
	
	# Фон
	background = ColorRect.new()
	background.size = Vector2(120, 140)
	background.position = Vector2(0, 0)
	background.color = Color(0.2, 0.2, 0.2, 1)
	add_child(background)
	
	# TextureRect для иконки (для текстур)
	icon_texture = TextureRect.new()
	icon_texture.size = Vector2(64, 64)
	icon_texture.position = Vector2(28, 10)
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.visible = false
	add_child(icon_texture)
	
	# Label для текстовой иконки
	icon_label = Label.new()
	icon_label.position = Vector2(28, 10)
	icon_label.size = Vector2(64, 64)
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.visible = false
	add_child(icon_label)
	
	# Имя
	name_label = Label.new()
	name_label.position = Vector2(0, 85)
	name_label.size = Vector2(120, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	add_child(name_label)
	
	# Сила
	power_label = Label.new()
	power_label.position = Vector2(85, 5)
	power_label.size = Vector2(30, 20)
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	power_label.add_theme_color_override("font_color", Color.YELLOW)
	power_label.add_theme_font_size_override("font_size", 12)
	add_child(power_label)
	
	# Броня
	armor_label = Label.new()
	armor_label.position = Vector2(85, 22)
	armor_label.size = Vector2(30, 18)
	armor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	armor_label.add_theme_color_override("font_color", Color.CYAN)
	armor_label.add_theme_font_size_override("font_size", 10)
	add_child(armor_label)
	
	# Полоска здоровья
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(10, 110)
	health_bar.size = Vector2(100, 12)
	health_bar.show_percentage = false
	add_child(health_bar)
	
	# Метка здоровья
	health_label = Label.new()
	health_label.position = Vector2(10, 110)
	health_label.size = Vector2(100, 12)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 9)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(health_label)

func setup(data, player_side):
	unit_data = data
	current_health = data.health
	is_player = player_side
	
	# Скрываем оба элемента иконки
	icon_texture.visible = false
	icon_label.visible = false
	
	# Устанавливаем иконку и имя
	if data is SurvivorData:
		unit_name = data.character_name  # Исправлено: character_name вместо name
		name_label.text = data.character_name  # Исправлено: character_name вместо name
		if data.icon:
			icon_texture.texture = data.icon
			icon_texture.visible = true
		else:
			icon_label.text = data.get_specialization_icon()
			icon_label.visible = true
		background.color = Color(0.2, 0.4, 0.2, 1) if is_player else Color(0.4, 0.2, 0.2, 1)
	elif data is EnemyData:
		unit_name = data.name
		name_label.text = data.name
		if data.icon:
			icon_texture.texture = data.icon
			icon_texture.visible = true
		else:
			icon_label.text = data.icon_text
			icon_label.visible = true
		background.color = Color(0.4, 0.2, 0.2, 1)  # Красный для врагов
	
	# Характеристики
	power_label.text = "⚔️ " + str(data.power)
	armor_label.text = "🛡️ " + str(data.armor)
	
	# Здоровье
	var max_health = data.max_health if data is SurvivorData else data.health
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = str(current_health)
	
	attack_cooldown = 0.0
	disabled = false

func setup_with_texture(data, player_side, texture: Texture2D):
	setup(data, player_side)
	if texture:
		icon_texture.texture = texture
		icon_texture.visible = true
		icon_label.visible = false

func make_empty():
	unit_data = null
	current_health = 0
	unit_name = ""
	
	icon_texture.visible = false
	icon_label.text = "💀"
	icon_label.visible = true
	name_label.text = "Уничтожен"
	power_label.text = "⚔️ 0"
	armor_label.text = "🛡️ 0"
	health_bar.value = 0
	health_label.text = "0"
	background.color = Color(0.3, 0.3, 0.3, 1)
	disabled = true

func take_damage(amount: int):
	current_health -= amount
	health_bar.value = max(0, current_health)
	health_label.text = str(max(0, current_health))
	
	# Визуальный эффект - красная вспышка
	modulate = Color.RED
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(_reset_color)
	
	return current_health <= 0

func heal(amount: int):
	if unit_data:
		var max_health = unit_data.max_health if unit_data is SurvivorData else unit_data.health
		current_health = min(max_health, current_health + amount)
		health_bar.value = current_health
		health_label.text = str(current_health)
		
		# Визуальный эффект - зеленая вспышка
		modulate = Color.GREEN
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(_reset_color)

func _reset_color():
	modulate = Color.WHITE

func attack(target):
	if not unit_data or current_health <= 0:
		return
	
	var damage = max(1, unit_data.damage - target.unit_data.armor)
	target.take_damage(damage)
	attack_cooldown = 1.0 / unit_data.attack_speed
	
	# Визуальный эффект атаки
	modulate = Color.YELLOW
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(_reset_color)

func get_power():
	return unit_data.power if unit_data != null and current_health > 0 else 0

func get_current_health():
	return current_health

func is_alive() -> bool:
	return current_health > 0

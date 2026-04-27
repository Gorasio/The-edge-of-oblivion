extends Button

var upgrade_data: UpgradeResource = null
var is_bought: bool = false
var current_materials: int = 0

# Дочерние узлы
var icon_left: TextureRect
var icon_right: TextureRect
var icon_left_alt: Label = null  # Альтернативная текстовая иконка слева
var icon_right_alt: Label = null  # Альтернативная текстовая иконка справа
var background: ColorRect
var title_label: Label
var description_label: Label
var effect_label: Label
var cost_label: Label
var buy_button: Button

func _init():
	# Настройка кнопки
	custom_minimum_size = Vector2(280, 120)
	size = Vector2(280, 120)
	
	# Фон (самый нижний слой)
	background = ColorRect.new()
	background.size = Vector2(280, 120)
	background.position = Vector2(0, 0)
	background.color = Color(0.15, 0.15, 0.2, 1)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = 0
	add_child(background)
	
	# Левая иконка (текстура)
	icon_left = TextureRect.new()
	icon_left.size = Vector2(64, 64)
	icon_left.position = Vector2(10, 28)
	icon_left.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_left.z_index = 1
	add_child(icon_left)
	
	# Правая иконка (текстура)
	icon_right = TextureRect.new()
	icon_right.size = Vector2(32, 32)
	icon_right.position = Vector2(238, 10)
	icon_right.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_right.z_index = 1
	add_child(icon_right)
	
	# Название (справа от левой иконки)
	title_label = Label.new()
	title_label.position = Vector2(84, 12)
	title_label.size = Vector2(186, 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.z_index = 2
	add_child(title_label)
	
	# Описание (под названием)
	description_label = Label.new()
	description_label.position = Vector2(84, 38)
	description_label.size = Vector2(186, 32)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.add_theme_color_override("font_color", Color.GRAY)
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.z_index = 2
	add_child(description_label)
	
	# Эффект (под описанием)
	effect_label = Label.new()
	effect_label.position = Vector2(84, 70)
	effect_label.size = Vector2(186, 20)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	effect_label.add_theme_color_override("font_color", Color.YELLOW)
	effect_label.add_theme_font_size_override("font_size", 11)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_label.z_index = 2
	add_child(effect_label)
	
	# Цена (слева внизу)
	cost_label = Label.new()
	cost_label.position = Vector2(12, 92)
	cost_label.size = Vector2(100, 24)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cost_label.add_theme_color_override("font_color", Color.GOLD)
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.z_index = 2
	add_child(cost_label)
	
	# Кнопка покупки (справа внизу)
	buy_button = Button.new()
	buy_button.position = Vector2(180, 86)
	buy_button.size = Vector2(90, 28)
	buy_button.text = "Купить"
	buy_button.add_theme_font_size_override("font_size", 12)
	buy_button.z_index = 3
	add_child(buy_button)

func setup(upgrade: UpgradeResource, materials_amount: int):
	upgrade_data = upgrade
	current_materials = materials_amount
	is_bought = upgrade.is_bought
	
	# Очищаем предыдущие альтернативные иконки
	if icon_left_alt:
		icon_left_alt.queue_free()
		icon_left_alt = null
	if icon_right_alt:
		icon_right_alt.queue_free()
		icon_right_alt = null
	
	# Устанавливаем левую иконку
	if upgrade.icon_left:
		icon_left.texture = upgrade.icon_left
		icon_left.visible = true
	else:
		icon_left.visible = false
		# Создаем текстовую иконку
		icon_left_alt = Label.new()
		icon_left_alt.text = upgrade.icon_text_left
		icon_left_alt.add_theme_font_size_override("font_size", 32)
		icon_left_alt.position = Vector2(10, 28)
		icon_left_alt.size = Vector2(64, 64)
		icon_left_alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_left_alt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_left_alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_left_alt.z_index = 1
		add_child(icon_left_alt)
	
	# Устанавливаем правую иконку
	if upgrade.icon_right:
		icon_right.texture = upgrade.icon_right
		icon_right.visible = true
	elif upgrade.icon_text_right != "":
		icon_right.visible = false
		# Создаем текстовую иконку
		icon_right_alt = Label.new()
		icon_right_alt.text = upgrade.icon_text_right
		icon_right_alt.add_theme_font_size_override("font_size", 24)
		icon_right_alt.position = Vector2(238, 10)
		icon_right_alt.size = Vector2(32, 32)
		icon_right_alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_right_alt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_right_alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_right_alt.z_index = 1
		add_child(icon_right_alt)
	else:
		icon_right.visible = false
	
	# Цвет фона в зависимости от редкости
	var rarity_color = upgrade.get_rarity_color()
	background.color = Color(rarity_color.r * 0.3, rarity_color.g * 0.3, rarity_color.b * 0.3, 1)
	
	# Название с цветом редкости
	title_label.text = upgrade.title
	title_label.add_theme_color_override("font_color", rarity_color)
	
	# Описание
	description_label.text = upgrade.description
	
	# Эффект
	effect_label.text = upgrade.get_effect_text()
	effect_label.add_theme_color_override("font_color", upgrade.effect_color)
	
	# Цена
	cost_label.text = "💰 " + str(upgrade.cost)
	
	# Настройка кнопки покупки
	if upgrade.is_bought:
		buy_button.text = "✅ КУПЛЕНО"
		buy_button.disabled = true
		buy_button.modulate = Color.GRAY
	else:
		var can_afford = upgrade.can_buy(materials_amount, 0, [])
		buy_button.text = "💰 Купить"
		buy_button.disabled = not can_afford
		if can_afford:
			buy_button.modulate = Color.GREEN
		else:
			buy_button.modulate = Color.RED

func update_materials(materials_amount: int):
	current_materials = materials_amount
	if not is_bought and upgrade_data:
		var can_afford = upgrade_data.can_buy(current_materials, 0, [])
		buy_button.disabled = not can_afford
		if can_afford:
			buy_button.modulate = Color.GREEN
		else:
			buy_button.modulate = Color.RED

func mark_as_bought():
	is_bought = true
	buy_button.text = "✅ КУПЛЕНО"
	buy_button.disabled = true
	buy_button.modulate = Color.GRAY

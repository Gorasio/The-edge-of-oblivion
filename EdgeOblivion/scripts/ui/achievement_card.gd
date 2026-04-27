extends Button

var achievement_data: AchievementResource = null
var is_unlocked: bool = false
var current_value: float = 0

# Дочерние узлы
var icon_left: TextureRect
var icon_right: TextureRect
var icon_left_alt: Label = null  # Альтернативная текстовая иконка слева
var icon_right_alt: Label = null  # Альтернативная текстовая иконка справа
var background: ColorRect
var title_label: Label
var description_label: Label
var progress_label: Label
var reward_label: Label
var status_icon: Label

func _init():
	# Настройка кнопки
	custom_minimum_size = Vector2(280, 100)
	size = Vector2(280, 100)
	
	# Фон
	background = ColorRect.new()
	background.size = Vector2(280, 100)
	background.position = Vector2(0, 0)
	background.color = Color(0.15, 0.15, 0.2, 1)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = 0
	add_child(background)
	
	# Левая иконка (текстура)
	icon_left = TextureRect.new()
	icon_left.size = Vector2(64, 64)
	icon_left.position = Vector2(10, 18)
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
	
	# Статус иконка (в правом верхнем углу, поверх правой иконки)
	status_icon = Label.new()
	status_icon.position = Vector2(238, 10)
	status_icon.size = Vector2(32, 32)
	status_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_icon.add_theme_font_size_override("font_size", 24)
	status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_icon.z_index = 2
	add_child(status_icon)
	
	# Название
	title_label = Label.new()
	title_label.position = Vector2(84, 12)
	title_label.size = Vector2(180, 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.z_index = 2
	add_child(title_label)
	
	# Описание
	description_label = Label.new()
	description_label.position = Vector2(84, 36)
	description_label.size = Vector2(180, 32)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.add_theme_color_override("font_color", Color.GRAY)
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.z_index = 2
	add_child(description_label)
	
	# Прогресс
	progress_label = Label.new()
	progress_label.position = Vector2(84, 68)
	progress_label.size = Vector2(180, 20)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	progress_label.add_theme_color_override("font_color", Color.YELLOW)
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label.z_index = 2
	add_child(progress_label)
	
	# Награда (в правом нижнем углу)
	reward_label = Label.new()
	reward_label.position = Vector2(200, 72)
	reward_label.size = Vector2(70, 24)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_label.add_theme_color_override("font_color", Color.ORANGE)
	reward_label.add_theme_font_size_override("font_size", 12)
	reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_label.z_index = 2
	add_child(reward_label)

func setup(achievement: AchievementResource, current_progress: float):
	achievement_data = achievement
	current_value = current_progress
	is_unlocked = achievement.is_achieved
	
	# Очищаем предыдущие альтернативные иконки
	if icon_left_alt:
		icon_left_alt.queue_free()
		icon_left_alt = null
	if icon_right_alt:
		icon_right_alt.queue_free()
		icon_right_alt = null
	
	# Устанавливаем левую иконку
	if achievement.icon_left:
		icon_left.texture = achievement.icon_left
		icon_left.visible = true
	else:
		icon_left.visible = false
		# Создаем текстовую иконку
		icon_left_alt = Label.new()
		icon_left_alt.text = achievement.icon_text_left
		icon_left_alt.add_theme_font_size_override("font_size", 32)
		icon_left_alt.position = Vector2(10, 18)
		icon_left_alt.size = Vector2(64, 64)
		icon_left_alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_left_alt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_left_alt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_left_alt.z_index = 1
		add_child(icon_left_alt)
	
	# Устанавливаем правую иконку
	if achievement.icon_right:
		icon_right.texture = achievement.icon_right
		icon_right.visible = true
	elif achievement.icon_text_right != "":
		icon_right.visible = false
		# Создаем текстовую иконку
		icon_right_alt = Label.new()
		icon_right_alt.text = achievement.icon_text_right
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
	var rarity_color = achievement.get_rarity_color()
	background.color = Color(rarity_color.r * 0.3, rarity_color.g * 0.3, rarity_color.b * 0.3, 1)
	
	# Название с цветом редкости
	title_label.text = achievement.get_display_title()
	title_label.add_theme_color_override("font_color", rarity_color)
	
	# Описание
	description_label.text = achievement.get_display_description()
	
	# Статус иконка
	if is_unlocked:
		status_icon.text = "✓"
		status_icon.add_theme_color_override("font_color", Color.GREEN)
		progress_label.text = achievement.get_progress_text(achievement.goal)
		progress_label.add_theme_color_override("font_color", Color.GREEN)
		background.color = Color(0, 0.5, 0, 0.3)
	else:
		status_icon.text = "⏳"
		status_icon.add_theme_color_override("font_color", Color.YELLOW)
		progress_label.text = achievement.get_progress_text(current_progress)
		progress_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Награда
	reward_label.text = "x%.1f" % achievement.reward_multiplier

func update_progress(new_value: float):
	if is_unlocked:
		return
	
	current_value = new_value
	if not is_unlocked and achievement_data:
		if achievement_data.check_completion(current_value):
			mark_as_unlocked()
		else:
			progress_label.text = achievement_data.get_progress_text(current_value)

func mark_as_unlocked():
	is_unlocked = true
	status_icon.text = "✓"
	status_icon.add_theme_color_override("font_color", Color.GREEN)
	progress_label.text = achievement_data.get_progress_text(achievement_data.goal)
	progress_label.add_theme_color_override("font_color", Color.GREEN)
	background.color = Color(0, 0.5, 0, 0.3)

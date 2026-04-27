extends Control

signal portrait_selected(portrait: Texture2D)
signal closed

var portraits_folder = "res://assets/portraits/"
var portrait_textures: Array[Texture2D] = []
var portrait_paths: Array[String] = []
var preview_size = 180  # Размер превью в пикселях

@onready var grid_container = $PortraitGridContainer
@onready var close_button = $CloseButton

func _ready():
	load_portraits()
	create_portrait_grid()
	close_button.pressed.connect(_on_close_pressed)

func load_portraits():
	portrait_textures.clear()
	portrait_paths.clear()
	
	print("Поиск портретов в папке: ", portraits_folder)
	
	var dir = DirAccess.open(portraits_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg"):
				var full_path = portraits_folder + file_name
				portrait_paths.append(full_path)
				var texture = load(full_path)
				if texture:
					# Создаем масштабированную версию для превью
					var preview_texture = create_preview_texture(texture)
					portrait_textures.append(preview_texture)
					print("Загружен портрет: ", file_name, " (размер: ", texture.get_size(), ")")
				else:
					print("Не удалось загрузить: ", full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Папка не найдена: ", portraits_folder)
	
	print("Всего портретов загружено: ", portrait_textures.size())
	
	# Если портретов нет, создаем тестовые
	if portrait_textures.size() == 0:
		print("Портреты не найдены, создаем тестовые")
		create_test_portraits()

func create_preview_texture(original_texture: Texture2D) -> Texture2D:
	var original_size = original_texture.get_size()
	var target_size = preview_size
	
	# Создаем изображение для превью
	var image = Image.create(target_size, target_size, false, Image.FORMAT_RGBA8)
	
	# Получаем оригинальное изображение
	var original_image = original_texture.get_image()
	
	# Масштабируем с сохранением пропорций
	var scale = min(float(target_size) / original_size.x, float(target_size) / original_size.y)
	var new_width = int(original_size.x * scale)
	var new_height = int(original_size.y * scale)
	
	# Масштабируем изображение
	original_image.resize(new_width, new_height, Image.INTERPOLATE_LANCZOS)
	
	# Вычисляем позицию для центрирования
	var offset_x = (target_size - new_width) / 2
	var offset_y = (target_size - new_height) / 2
	
	# Копируем масштабированное изображение на квадратный холст
	image.blit_rect(original_image, Rect2i(0, 0, new_width, new_height), Vector2i(offset_x, offset_y))
	
	return ImageTexture.create_from_image(image)

func create_test_portraits():
	print("Создание тестовых портретов")
	
	# Создаем 6 тестовых портретов с разными цветами и стилями
	var test_portraits = [
		{"color": Color(0.9, 0.5, 0.3, 1), "name": "Рыжий", "accessory": "none"},
		{"color": Color(0.8, 0.6, 0.4, 1), "name": "Светлый", "accessory": "hat"},
		{"color": Color(0.5, 0.3, 0.2, 1), "name": "Темный", "accessory": "beard"},
		{"color": Color(0.9, 0.7, 0.5, 1), "name": "Светлый 2", "accessory": "glasses"},
		{"color": Color(0.6, 0.4, 0.3, 1), "name": "Коричневый", "accessory": "scar"},
		{"color": Color(0.7, 0.5, 0.4, 1), "name": "Средний", "accessory": "eyepatch"},
	]
	
	for i in range(test_portraits.size()):
		var data = test_portraits[i]
		var portrait = create_test_portrait(data.color, data.accessory)
		portrait_textures.append(portrait)

func create_test_portrait(skin_color: Color, accessory: String) -> Texture2D:
	var size = preview_size
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Фон
	image.fill(skin_color)
	
	# Лицо (овал)
	image.fill_rect(Rect2i(40, 40, 100, 100), Color(0.9, 0.7, 0.5, 1))
	
	# Глаза
	image.fill_rect(Rect2i(65, 75, 12, 12), Color(0.1, 0.1, 0.1, 1))
	image.fill_rect(Rect2i(105, 75, 12, 12), Color(0.1, 0.1, 0.1, 1))
	
	# Зрачки
	image.fill_rect(Rect2i(70, 80, 4, 4), Color.WHITE)
	image.fill_rect(Rect2i(110, 80, 4, 4), Color.WHITE)
	
	# Рот
	image.fill_rect(Rect2i(85, 110, 30, 8), Color(0.5, 0.3, 0.2, 1))
	
	# Аксессуары
	match accessory:
		"hat":
			# Шляпа
			image.fill_rect(Rect2i(55, 20, 90, 25), Color(0.3, 0.2, 0.1, 1))
			image.fill_rect(Rect2i(80, 15, 40, 20), Color(0.4, 0.3, 0.2, 1))
		"beard":
			# Борода
			image.fill_rect(Rect2i(65, 115, 70, 25), Color(0.5, 0.3, 0.2, 1))
		"glasses":
			# Очки
			image.fill_rect(Rect2i(60, 70, 20, 8), Color(0, 0, 0, 1))
			image.fill_rect(Rect2i(102, 70, 20, 8), Color(0, 0, 0, 1))
			image.fill_rect(Rect2i(82, 70, 36, 8), Color(0, 0, 0, 1))
		"scar":
			# Шрам
			image.fill_rect(Rect2i(100, 90, 20, 4), Color(0.8, 0.2, 0.2, 1))
		"eyepatch":
			# Повязка на глаз
			image.fill_rect(Rect2i(55, 65, 30, 30), Color(0.2, 0.2, 0.2, 1))
			image.fill_rect(Rect2i(58, 68, 24, 24), Color(0.1, 0.1, 0.1, 1))
	
	return ImageTexture.create_from_image(image)

func create_portrait_grid():
	# Очищаем сетку
	for child in grid_container.get_children():
		child.queue_free()
	
	if portrait_textures.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Нет доступных портретов\nДобавьте изображения в папку:\n" + portraits_folder
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color.YELLOW)
		grid_container.add_child(empty_label)
		return
	
	# Создаем кнопки с портретами
	for i in range(portrait_textures.size()):
		var texture = portrait_textures[i]
		var button = create_portrait_button(texture, i)
		grid_container.add_child(button)

func create_portrait_button(texture: Texture2D, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(220, 220)
	button.size = Vector2(220, 220)
	
	# Создаем TextureRect для отображения портрета
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.size = Vector2(200, 200)
	texture_rect.position = Vector2(10, 10)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(texture_rect)
	
	# Добавляем номер портрета
	var number_label = Label.new()
	number_label.text = str(index + 1)
	number_label.position = Vector2(10, 10)
	number_label.size = Vector2(30, 20)
	number_label.add_theme_font_size_override("font_size", 12)
	number_label.add_theme_color_override("font_color", Color.WHITE)
	number_label.add_theme_color_override("font_outline_modulate", Color.BLACK)
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(number_label)
	
	button.pressed.connect(func(): _on_portrait_selected(texture))
	
	return button

func _on_portrait_selected(portrait: Texture2D):
	# Возвращаем оригинальный портрет (не превью)
	var original_portrait = get_original_portrait(portrait)
	portrait_selected.emit(original_portrait)
	queue_free()

func get_original_portrait(preview_texture: Texture2D) -> Texture2D:
	# Ищем соответствующий оригинальный портрет
	var preview_index = portrait_textures.find(preview_texture)
	if preview_index >= 0 and preview_index < portrait_paths.size():
		var original = load(portrait_paths[preview_index])
		if original:
			return original
	
	# Если не нашли, возвращаем превью
	return preview_texture

func _on_close_pressed():
	closed.emit()
	queue_free()

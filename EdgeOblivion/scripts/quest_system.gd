extends Node

# Сигналы
signal quest_activated(quest_id)
signal quest_completed(quest_id)
signal quest_stage_changed(quest_id, stage_id)
signal quest_progress_updated(quest_id, current_value, target_value)

# Данные
var active_quests: Dictionary = {}  # quest_id -> LocationQuestData
var completed_quests: Dictionary = {}  # quest_id -> LocationQuestData
var quest_stages: Dictionary = {}  # quest_id -> current_stage

# Словари для отслеживания прогресса по типам
var food_collected: int = 0
var water_collected: int = 0
var materials_collected: int = 0
var enemies_killed: int = 0
var days_survived: int = 0
var upgrades_bought: int = 0
var survivors_found: int = 0
var locations_visited: int = 0
var quests_completed_count: int = 0

func _ready():
	print("Система квестов инициализирована")

# Активация квеста
func activate_quest(quest_data: LocationQuestData):
	if quest_data.is_active:
		print("Квест уже активен: ", quest_data.quest_name)
		return
	
	if quest_data.is_completed:
		print("Квест уже завершен: ", quest_data.quest_name)
		return
	
	# Проверяем условия активации
	if not check_quest_requirements(quest_data):
		print("Условия активации квеста не выполнены: ", quest_data.quest_name)
		return
	
	quest_data.is_active = true
	active_quests[quest_data.quest_id] = quest_data
	quest_stages[quest_data.quest_id] = 0
	
	# Обновляем начальные значения для квеста
	update_quest_initial_values(quest_data)
	
	# Если есть этапы, активируем первый
	if quest_data.stages.size() > 0:
		activate_stage(quest_data.quest_id, 0)
	
	quest_activated.emit(quest_data.quest_id)
	print("Квест активирован: ", quest_data.quest_name)

# Обновление начальных значений для квеста
func update_quest_initial_values(quest_data: LocationQuestData):
	match quest_data.quest_type:
		"collect":
			match quest_data.target_type:
				"food":
					quest_data.current_value = food_collected
				"water":
					quest_data.current_value = water_collected
				"materials":
					quest_data.current_value = materials_collected
				"all":
					quest_data.current_value = food_collected + water_collected + materials_collected
		"kill":
			quest_data.current_value = enemies_killed
		"survive":
			quest_data.current_value = days_survived
		"upgrade":
			quest_data.current_value = upgrades_bought
		"find_survivor":
			quest_data.current_value = survivors_found
		"explore":
			quest_data.current_value = locations_visited
		"complete_quests":
			quest_data.current_value = quests_completed_count
		"talk":
			quest_data.current_value = 0  # Диалоги обрабатываются отдельно

# Активация этапа квеста
func activate_stage(quest_id: int, stage_id: int):
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	if stage_id >= quest.stages.size():
		return
	
	quest.current_stage = stage_id
	quest_stages[quest_id] = stage_id
	
	var stage = quest.stages[stage_id]
	stage.stage_current = 0
	
	# Обновляем начальные значения для этапа
	update_stage_initial_values(quest, stage)
	
	# Появляем NPC для этого этапа
	for npc_id in stage.spawn_npcs:
		spawn_npc_by_id(npc_id)
	
	# Исчезают NPC
	for npc_id in stage.despawn_npcs:
		despawn_npc_by_id(npc_id)
	
	# Запускаем диалог начала этапа
	if not stage.dialogue_on_start.is_empty():
		start_dialogue(stage.dialogue_on_start)
	
	quest_stage_changed.emit(quest_id, stage_id)
	print("Активирован этап ", stage_id + 1, " квеста: ", quest.quest_name)

# Обновление начальных значений для этапа
func update_stage_initial_values(quest: LocationQuestData, stage: QuestStageData):
	match stage.stage_type:
		"collect":
			match quest.target_type:
				"food":
					stage.stage_current = food_collected
				"water":
					stage.stage_current = water_collected
				"materials":
					stage.stage_current = materials_collected
				"all":
					stage.stage_current = food_collected + water_collected + materials_collected
		"kill":
			stage.stage_current = enemies_killed
		"survive":
			stage.stage_current = days_survived
		"talk":
			stage.stage_current = 0

# Завершение этапа квеста
func complete_stage(quest_id: int, stage_id: int):
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	if stage_id >= quest.stages.size():
		return
	
	var stage = quest.stages[stage_id]
	
	# Выдаем награду за этап
	give_stage_reward(stage)
	
	# Появляем NPC после завершения этапа
	for npc_id in stage.spawn_npcs_on_complete:
		spawn_npc_by_id(npc_id)
	
	# Исчезают NPC после завершения этапа
	for npc_id in stage.despawn_npcs_on_complete:
		despawn_npc_by_id(npc_id)
	
	# Запускаем диалог завершения этапа
	if not stage.dialogue_on_complete.is_empty():
		start_dialogue(stage.dialogue_on_complete)
	
	# Переходим к следующему этапу
	var next_stage = stage_id + 1
	if next_stage < quest.stages.size():
		activate_stage(quest_id, next_stage)
	else:
		complete_quest(quest_id)

# Завершение квеста
func complete_quest(quest_id: int):
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	quest.is_active = false
	quest.is_completed = true
	completed_quests[quest_id] = quest
	active_quests.erase(quest_id)
	quest_stages.erase(quest_id)
	
	# Увеличиваем счетчик завершенных квестов
	quests_completed_count += 1
	
	# Выдаем награду за квест
	give_quest_reward(quest)
	
	# Появляются NPC после завершения квеста
	for npc_id in quest.npc_on_complete:
		spawn_npc_by_id(npc_id)
	
	# Запускаем диалог завершения квеста
	if not quest.dialogue_on_complete.is_empty():
		start_dialogue(quest.dialogue_on_complete)
	
	# Активируем следующий квест в цепочке
	if quest.next_quest_id != -1:
		var next_quest = find_quest_by_id(quest.next_quest_id)
		if next_quest and next_quest.is_available:
			activate_quest(next_quest)
	
	quest_completed.emit(quest_id)
	print("Квест завершен: ", quest.quest_name)

# Обновление прогресса квеста
# В функции update_quest_progress добавьте обработку новых типов:
func update_quest_progress(quest_type: String, target_type: String, amount: int = 1):
	for quest_id in active_quests.keys():
		var quest = active_quests[quest_id]
		
		# Проверяем тип квеста
		if quest.quest_type != quest_type:
			continue
		
		# Проверяем тип цели
		if quest.target_type != target_type and quest.target_type != "all" and target_type != "all":
			continue
		
		var old_value = quest.current_value
		
		# Обновляем прогресс
		quest.current_value += amount
		
		# Обновляем прогресс текущего этапа
		var current_stage_id = quest_stages.get(quest_id, -1)
		if current_stage_id >= 0 and current_stage_id < quest.stages.size():
			var stage = quest.stages[current_stage_id]
			stage.stage_current += amount
			
			# Проверяем завершение этапа
			if stage.stage_current >= stage.stage_target:
				complete_stage(quest_id, current_stage_id)
		
		quest_progress_updated.emit(quest_id, quest.current_value, quest.target_value)
		
		# Проверяем завершение квеста
		if quest.current_value >= quest.target_value:
			complete_quest(quest_id)

# В функции update_progress_by_type добавьте:
func update_progress_by_type(type: String, amount: int = 1):
	match type:
		"food":
			food_collected += amount
			update_quest_progress("collect", "food", amount)
			update_quest_progress("collect", "all", amount)
		"water":
			water_collected += amount
			update_quest_progress("collect", "water", amount)
			update_quest_progress("collect", "all", amount)
		"materials":
			materials_collected += amount
			update_quest_progress("collect", "materials", amount)
			update_quest_progress("collect", "all", amount)
		"enemies":
			enemies_killed += amount
			update_quest_progress("kill", "enemies", amount)
		"days":
			days_survived += amount
			update_quest_progress("survive", "days", amount)
		"upgrade":
			upgrades_bought += amount
			update_quest_progress("upgrade", "upgrades", amount)
		"survivor":
			survivors_found += amount
			update_quest_progress("find_survivor", "survivors", amount)
		"location":
			locations_visited += amount
			update_quest_progress("explore", "locations", amount)
		"level":
			update_quest_progress("reach_level", "level", amount)
		"power":
			update_quest_progress("reach_power", "power", amount)

# Функция для обновления уровня персонажа
func update_level_progress(level: int):
	update_quest_progress("reach_level", "level", level)

# Функция для обновления силы персонажа
func update_power_progress(power: int):
	update_quest_progress("reach_power", "power", power)

# Обновление прогресса после битвы
func update_battle_progress(victory: bool):
	if victory:
		enemies_killed += 1
		update_quest_progress("kill", "enemies", 1)

# Обновление прогресса после покупки улучшения
func update_upgrade_progress():
	upgrades_bought += 1
	update_quest_progress("upgrade", "upgrades", 1)

# Обновление прогресса после нахождения выжившего
func update_survivor_found_progress():
	survivors_found += 1
	update_quest_progress("find_survivor", "survivors", 1)

# Обновление прогресса после посещения новой локации
func update_location_visited_progress():
	locations_visited += 1
	update_quest_progress("explore", "locations", 1)

# Обновление прогресса диалога (для квестов типа "talk")
func update_talk_progress(quest_id: int):
	if active_quests.has(quest_id):
		var quest = active_quests[quest_id]
		if quest.quest_type == "talk":
			quest.current_value += 1
			quest_progress_updated.emit(quest_id, quest.current_value, quest.target_value)
			
			# Проверяем завершение квеста
			if quest.current_value >= quest.target_value:
				complete_quest(quest_id)
			else:
				# Проверяем завершение текущего этапа
				var current_stage_id = quest_stages.get(quest_id, -1)
				if current_stage_id >= 0 and current_stage_id < quest.stages.size():
					var stage = quest.stages[current_stage_id]
					stage.stage_current += 1
					
					if stage.stage_current >= stage.stage_target:
						complete_stage(quest_id, current_stage_id)

# Проверка условий активации квеста
# В функции check_quest_requirements замените:
func check_quest_requirements(quest_data: LocationQuestData) -> bool:
	# Проверяем требуемый уровень
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("get_main_character"):
		var character = main.get_main_character()
		# Используем метод get_level() вместо прямого доступа к полю level
		if character and character.has_method("get_level"):
			if character.get_level() < quest_data.required_level:
				return false
	
	# Проверяем требуемый квест
	if quest_data.required_quest_id != -1:
		if not is_quest_completed(quest_data.required_quest_id):
			return false
	
	# Проверяем требуемую репутацию
	if quest_data.required_reputation > 0:
		# TODO: добавить систему репутации
		pass
	
	return true

# Выдача награды за этап
func give_stage_reward(stage: QuestStageData):
	var main = get_tree().root.get_node_or_null("Main")
	if not main:
		return
	
	if stage.stage_reward_food > 0:
		main.add_food(stage.stage_reward_food)
		print("Получено еды за этап: ", stage.stage_reward_food)
	if stage.stage_reward_water > 0:
		main.add_water(stage.stage_reward_water)
		print("Получено воды за этап: ", stage.stage_reward_water)
	if stage.stage_reward_materials > 0:
		main.add_materials(stage.stage_reward_materials)
		print("Получено материалов за этап: ", stage.stage_reward_materials)

# Выдача награды за квест
func give_quest_reward(quest_data: LocationQuestData):
	var main = get_tree().root.get_node_or_null("Main")
	if not main:
		return
	
	if quest_data.reward_food > 0:
		main.add_food(quest_data.reward_food)
		print("Получено еды: ", quest_data.reward_food)
	if quest_data.reward_water > 0:
		main.add_water(quest_data.reward_water)
		print("Получено воды: ", quest_data.reward_water)
	if quest_data.reward_materials > 0:
		main.add_materials(quest_data.reward_materials)
		print("Получено материалов: ", quest_data.reward_materials)
	if quest_data.reward_experience > 0:
		# TODO: добавить систему опыта
		print("Добавлено опыта: ", quest_data.reward_experience)

# Запуск диалога
func start_dialogue(dialogue_info: Dictionary):
	var dialog_resource_path = dialogue_info.get("dialog_resource", "")
	var dialog_branch = dialogue_info.get("dialog_branch", "FIRST")
	
	if dialog_resource_path != "":
		var dialog_data = load(dialog_resource_path)
		if dialog_data:
			SproutyDialogs.start_dialog(dialog_data, dialog_branch)

# Появление NPC по ID
func spawn_npc_by_id(npc_id: int):
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("spawn_npc_by_id"):
		main.spawn_npc_by_id(npc_id)

# Исчезновение NPC по ID
func despawn_npc_by_id(npc_id: int):
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("despawn_npc_by_id"):
		main.despawn_npc_by_id(npc_id)

# Вспомогательные функции
func is_quest_active(quest_id: int) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: int) -> bool:
	return completed_quests.has(quest_id)

func get_quest_stage(quest_id: int) -> int:
	return quest_stages.get(quest_id, -1)

func get_quest_by_id(quest_id: int) -> LocationQuestData:
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	if completed_quests.has(quest_id):
		return completed_quests[quest_id]
	return null

func find_quest_by_id(quest_id: int) -> LocationQuestData:
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("get_quest_by_id"):
		return main.get_quest_by_id(quest_id)
	return null

# Получение активных квестов для отображения
func get_active_quests_list() -> Array:
	var result: Array = []
	for quest in active_quests.values():
		result.append(quest)
	return result

# Получение завершенных квестов
func get_completed_quests_list() -> Array:
	var result: Array = []
	for quest in completed_quests.values():
		result.append(quest)
	return result

# Получение прогресса по типам
func get_food_collected() -> int:
	return food_collected

func get_water_collected() -> int:
	return water_collected

func get_materials_collected() -> int:
	return materials_collected

func get_enemies_killed() -> int:
	return enemies_killed

func get_days_survived() -> int:
	return days_survived

# Сброс системы (для новой игры)
func reset_quest_system():
	active_quests.clear()
	completed_quests.clear()
	quest_stages.clear()
	
	food_collected = 0
	water_collected = 0
	materials_collected = 0
	enemies_killed = 0
	days_survived = 0
	upgrades_bought = 0
	survivors_found = 0
	locations_visited = 0
	quests_completed_count = 0
	
	print("Система квестов сброшена")

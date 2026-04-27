extends Node2D

signal battle_ended(victory)

var player_survivors: Array[SurvivorData] = []
var player_general: SurvivorData = null
var enemy_group: Array[EnemyData] = []
var current_battle_active = false
var battle_time = 0.0
var paused = false
var battle_speed: float = 1.0
var battle_log: Array[String] = []

# Таймер для управления скоростью боя
var combat_timer: float = 0.0
var combat_interval: float = 0.5  # Интервал между действиями в секундах

var location_enemy_data = null  # Для обновления статуса врага

@onready var survivors_grid = $UI/LeftPanel/SurvivorsScroll/SurvivorsGrid
@onready var enemies_grid = $UI/RightPanel/EnemiesScroll/EnemiesGrid
@onready var timer_label = $UI/TopPanel/TimerLabel
@onready var pause_button = $UI/TopPanel/PauseButton
@onready var back_button = $UI/TopPanel/BackButton
@onready var speed_slider = $UI/TopPanel/SpeedControl/SpeedSlider
@onready var speed_value = $UI/TopPanel/SpeedControl/SpeedValue
@onready var general_portrait = $UI/LeftPanel/GeneralPanel/GeneralPortrait
@onready var general_name = $UI/LeftPanel/GeneralPanel/GeneralName
@onready var general_health = $UI/LeftPanel/GeneralPanel/GeneralHealth
@onready var general_power = $UI/LeftPanel/GeneralPanel/GeneralPower
@onready var enemy_portrait = $UI/RightPanel/EnemyPanel/EnemyPortrait
@onready var enemy_name = $UI/RightPanel/EnemyPanel/EnemyName
@onready var enemy_health = $UI/RightPanel/EnemyPanel/EnemyHealth
@onready var enemy_power = $UI/RightPanel/EnemyPanel/EnemyPower
@onready var battle_log_label = $UI/BattleLog/BattleLogLabel

func _ready():
	load_resources()
	setup_ui_signals()
	setup_speed_control()
	start_battle()

func load_resources():
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		if main.has_method("get_battle_ready_survivors"):
			player_survivors = main.get_battle_ready_survivors()
			print("Боеспособных выживших (охранников): ", player_survivors.size())
		else:
			player_survivors = main.get_survivors()
		
		if main.has_method("get_main_character"):
			player_general = main.get_main_character()

func setup_ui_signals():
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func setup_speed_control():
	if speed_slider:
		speed_slider.value_changed.connect(_on_speed_changed)

func _on_speed_changed(value: float):
	battle_speed = value
	if speed_value:
		speed_value.text = str(value) + "x"
	
	# Обновляем интервал между действиями
	combat_interval = 0.5 / battle_speed
	print("Скорость боя изменена: ", battle_speed, "x")

func start_battle():
	create_battle_grids()
	update_general_display()
	update_enemy_display()
	current_battle_active = true
	combat_timer = 0.0

func create_battle_grids():
	if survivors_grid:
		for child in survivors_grid.get_children():
			child.queue_free()
	if enemies_grid:
		for child in enemies_grid.get_children():
			child.queue_free()
	
	for survivor in player_survivors:
		if survivor.is_alive and survivor.job == "guard":
			var card = preload("res://scripts/unit_card_battle.gd").new()
			card.setup(survivor, true)
			survivors_grid.add_child(card)
	
	for enemy in enemy_group:
		var card = preload("res://scripts/unit_card_battle.gd").new()
		card.setup(enemy, false)
		enemies_grid.add_child(card)

func update_general_display():
	if player_general:
		if player_general.icon and general_portrait:
			general_portrait.texture = player_general.icon
		if general_name:
			general_name.text = player_general.character_name
		if general_health:
			general_health.text = "❤️ Здоровье: %d/%d" % [player_general.health, player_general.max_health]
		if general_power:
			general_power.text = "⚔️ Сила: %d" % player_general.power

func update_enemy_display():
	if enemy_group.size() > 0:
		var main_enemy = enemy_group[0]
		if main_enemy.icon and enemy_portrait:
			enemy_portrait.texture = main_enemy.icon
		if enemy_name:
			enemy_name.text = main_enemy.name
		if enemy_health:
			enemy_health.text = "❤️ Здоровье: %d" % main_enemy.health
		if enemy_power:
			enemy_power.text = "⚔️ Сила: %d" % main_enemy.power

func _process(delta):
	if current_battle_active and not paused:
		# Обновляем таймер битвы с учетом скорости
		battle_time += delta * battle_speed
		update_timer()
		
		# Обновляем таймер действий
		combat_timer += delta
		while combat_timer >= combat_interval:
			combat_timer -= combat_interval
			process_combat_step()

func update_timer():
	if timer_label:
		var minutes = int(battle_time) / 60
		var seconds = int(battle_time) % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]

func process_combat_step():
	var player_alive = false
	var enemy_alive = false
	
	# Проверяем живых игроков
	if survivors_grid:
		for card in survivors_grid.get_children():
			if card.is_alive():
				player_alive = true
				break
	
	# Проверяем живых врагов
	if enemies_grid:
		for card in enemies_grid.get_children():
			if card.is_alive():
				enemy_alive = true
				break
	
	if not player_alive:
		end_battle(false)
		return
	elif not enemy_alive:
		end_battle(true)
		return
	
	# Чередуем атаки: игроки атакуют, потом враги
	if int(battle_time * 10) % 2 == 0:
		process_player_attack()
	else:
		process_enemy_attack()

func process_player_attack():
	if not survivors_grid:
		return
	for card in survivors_grid.get_children():
		if card.is_alive():
			if enemies_grid:
				for enemy_card in enemies_grid.get_children():
					if enemy_card.is_alive():
						card.attack(enemy_card)
						add_log("%s атакует %s" % [card.unit_name, enemy_card.unit_name])
						update_original_survivor_health(card)
						return
			break

func process_enemy_attack():
	if not enemies_grid:
		return
	for card in enemies_grid.get_children():
		if card.is_alive():
			if survivors_grid:
				for player_card in survivors_grid.get_children():
					if player_card.is_alive():
						card.attack(player_card)
						add_log("%s атакует %s" % [card.unit_name, player_card.unit_name])
						update_original_survivor_health(player_card)
						return
			break

func update_original_survivor_health(card):
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("update_survivor_health"):
		main.update_survivor_health(card.unit_name, card.current_health)

func add_log(text: String):
	battle_log.append(text)
	if battle_log.size() > 10:
		battle_log.pop_front()
	
	if battle_log_label:
		var log_text = "Боевой лог:\n"
		for entry in battle_log:
			log_text += entry + "\n"
		battle_log_label.text = log_text

func end_battle(player_won):
	current_battle_active = false
	if player_won:
		add_log("ПОБЕДА!")
		for enemy in enemy_group:
			var main = get_tree().root.get_node_or_null("Main")
			if main:
				main.add_materials(enemy.reward_materials)
				main.add_food(enemy.reward_food)
				main.add_water(enemy.reward_water)
		
		# Если есть данные о враге в локации, обновляем их статус
		if location_enemy_data:
			location_enemy_data.is_defeated = true
			# Сохраняем изменения
			var main = get_tree().root.get_node_or_null("Main")
			if main and main.has_method("save_location_enemy_status"):
				main.save_location_enemy_status(location_enemy_data)
	else:
		add_log("ПОРАЖЕНИЕ...")
	
	battle_ended.emit(player_won)


func _on_pause_pressed():
	paused = !paused
	if pause_button:
		pause_button.text = "▶️ Продолжить" if paused else "⏸️ Пауза"

func _on_back_pressed():
	queue_free()

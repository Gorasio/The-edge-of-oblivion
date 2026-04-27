extends Panel

signal closed

var achievements_list: Array[AchievementResource] = []
var unlocked_achievements: Array[int] = []

@onready var scroll_container = $AchievementsScrollContainer
@onready var close_button = $CloseButtonAchievements
@onready var stats_label = $StatsLabel

func _ready():
	close_button.pressed.connect(_on_close_pressed)

func setup(achievements: Array[AchievementResource], unlocked: Array[int]):
	achievements_list = achievements
	unlocked_achievements = unlocked
	update_panel()

func update_panel():
	var unlocked_count = unlocked_achievements.size()
	var total_count = achievements_list.size()
	var progress = (float(unlocked_count) / total_count) * 100 if total_count > 0 else 0
	stats_label.text = "📊 Прогресс: %d/%d достижений (%.1f%%)" % [unlocked_count, total_count, progress]
	
	for child in scroll_container.get_children():
		child.queue_free()
	
	if achievements_list.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Нет доступных достижений"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size = Vector2(280, 50)
		scroll_container.add_child(empty_label)
		return
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll_container.add_child(vbox)
	
	for achievement in achievements_list:
		var current_value = get_achievement_current_value(achievement)
		var achievement_card = preload("res://scripts/ui/achievement_card.gd").new()
		achievement_card.setup(achievement, current_value)
		vbox.add_child(achievement_card)

func get_achievement_current_value(achievement: AchievementResource) -> float:
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("get_achievement_current_value"):
		return main.get_achievement_current_value(achievement)
	return 0.0

func _on_close_pressed():
	closed.emit()
	queue_free()

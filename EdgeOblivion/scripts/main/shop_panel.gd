extends Panel

signal closed

var upgrades_list: Array[UpgradeResource] = []
var purchased_upgrades: Array[int] = []
var materials: int = 0

@onready var scroll_container = $ShopScrollContainer
@onready var close_button = $CloseButton
@onready var materials_label = $MaterialsLabelShop

func _ready():
	close_button.pressed.connect(_on_close_pressed)

func setup(upgrades: Array[UpgradeResource], purchased: Array[int], current_materials: int):
	upgrades_list = upgrades
	purchased_upgrades = purchased
	materials = current_materials
	update_panel()

func update_panel():
	materials_label.text = "🔧 Материалы: %d" % materials
	
	for child in scroll_container.get_children():
		child.queue_free()
	
	if upgrades_list.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Нет доступных улучшений"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size = Vector2(280, 50)
		scroll_container.add_child(empty_label)
		return
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll_container.add_child(vbox)
	
	for upgrade in upgrades_list:
		var should_show = upgrade.visible_from_start or upgrade.upgrade_id in purchased_upgrades
		if should_show:
			var upgrade_card = preload("res://scripts/ui/upgrade_card.gd").new()
			upgrade_card.setup(upgrade, materials)
			upgrade_card.buy_button.pressed.connect(func(): _on_upgrade_buy_pressed(upgrade, upgrade_card))
			vbox.add_child(upgrade_card)

func _on_upgrade_buy_pressed(upgrade: UpgradeResource, card):
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("buy_upgrade"):
		if main.buy_upgrade(upgrade):
			card.mark_as_bought()
			materials = main.materials
			materials_label.text = "🔧 Материалы: %d" % materials

func _on_close_pressed():
	closed.emit()
	queue_free()

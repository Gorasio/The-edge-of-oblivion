extends Panel

var main_character: SurvivorData = null

@onready var portrait = $CharacterPortrait
@onready var name_label = $CharacterName
@onready var specialization_label = $CharacterSpecialization
@onready var health_label = $CharacterHealth
@onready var power_label = $CharacterPower

func setup(character: SurvivorData):
	main_character = character
	update_display()

func update_display():
	if main_character:
		if main_character.icon:
			portrait.texture = main_character.icon
		name_label.text = main_character.character_name
		specialization_label.text = main_character.get_specialization_icon() + " " + main_character.specialization
		health_label.text = "❤️ %d/%d" % [main_character.health, main_character.max_health]
		power_label.text = "⚔️ %d" % main_character.power

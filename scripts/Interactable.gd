extends Area2D
class_name Interactable

@export var interaction_text: String = "Interact"
@export var double_press_text: String = ""
@export var long_press_text: String = ""
@export var can_interact: bool = true
@export var interaction_cooldown: float = 0.5

var interaction_prompt: Label
var last_interaction_time: float = 0.0

signal interacted(player: Node2D, interaction_type: InteractionType.Type)

func _ready():
	add_to_group("interactables")
	create_interaction_prompt()
	# Set up collision layer for interaction system
	collision_layer = 0b10  # Layer 2
	collision_mask = 0b1    # Layer 1 (player)

func create_interaction_prompt():
	interaction_prompt = Label.new()
	interaction_prompt.add_theme_font_size_override("font_size", 10)
	interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Style the prompt
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	interaction_prompt.add_theme_stylebox_override("normal", style_box)
	
	interaction_prompt.position = Vector2(-50, -40)
	interaction_prompt.size = Vector2(100, 25)
	interaction_prompt.visible = false
	
	add_child(interaction_prompt)

func show_prompt(text: String):
	if interaction_prompt:
		interaction_prompt.text = text
		interaction_prompt.visible = true

func hide_prompt():
	if interaction_prompt:
		interaction_prompt.visible = false

func interact(player: Node2D, interaction_type: InteractionType.Type):
	var current_time = Time.get_ticks_msec() / 1000.0  # Convert to seconds
	if current_time - last_interaction_time < interaction_cooldown:
		return  # Still in cooldown
	
	last_interaction_time = current_time
	
	match interaction_type:
		InteractionType.Type.STANDARD:
			perform_standard_interaction(player)
		InteractionType.Type.DOUBLE_PRESS:
			perform_double_press_interaction(player)
		InteractionType.Type.LONG_PRESS:
			perform_long_press_interaction(player)
	
	interacted.emit(player, interaction_type)

# Override these in derived classes
func perform_standard_interaction(player: Node2D):
	print("Standard interaction with ", name)

func perform_double_press_interaction(player: Node2D):
	if has_double_press_action():
		print("Double press interaction with ", name)

func perform_long_press_interaction(player: Node2D):
	if has_long_press_action():
		print("Long press interaction with ", name)

func get_interaction_text() -> String:
	return interaction_text

func get_double_press_text() -> String:
	return double_press_text

func get_long_press_text() -> String:
	return long_press_text

func has_double_press_action() -> bool:
	return not double_press_text.is_empty()

func has_long_press_action() -> bool:
	return not long_press_text.is_empty()

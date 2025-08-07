extends Node
class_name InteractionManager

signal interaction_started(interactable)
signal interaction_ended(interactable)

@export var interaction_range: float = 40.0
@export var double_press_time: float = 0.4  # Time window for double press
@export var long_press_time: float = 0.8    # Time for long press

var player: CharacterBody2D
var current_interactables: Array[Interactable] = []
var closest_interactable: Interactable = null

# Input tracking
var press_start_time: float = 0.0
var last_press_time: float = 0.0
var is_pressing: bool = false
var press_count: int = 0

func _ready():
	# Find the player
	call_deferred("find_player")
	set_process(true)

func find_player():
	if get_tree().has_group("player"):
		player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if not player:
		return
	
	update_nearby_interactables()
	handle_interaction_input(delta)

func _input(event):
	if not event is InputEventKey:
		return
		
	if event.keycode == KEY_E:
		if event.pressed and not is_pressing:
			# Start press
			is_pressing = true
			press_start_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60.0
			
			# Check for double press
			var current_time = press_start_time
			if current_time - last_press_time < double_press_time:
				press_count += 1
			else:
				press_count = 1
			
			last_press_time = current_time
			
		elif not event.pressed and is_pressing:
			# End press
			is_pressing = false
			var press_duration = (Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60.0) - press_start_time
			
			# Determine interaction type
			if press_duration >= long_press_time:
				perform_long_press_interaction()
			elif press_count >= 2:
				perform_double_press_interaction()
				press_count = 0  # Reset after double press
			else:
				# Wait a bit to see if it's a double press
				await get_tree().create_timer(double_press_time).timeout
				if press_count == 1:  # Still just one press
					perform_standard_interaction()
				press_count = 0

func handle_interaction_input(delta):
	# Handle continuous long press feedback
	if is_pressing and closest_interactable:
		var press_duration = (Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60.0) - press_start_time
		if press_duration >= long_press_time:
			# Visual feedback for long press
			update_interaction_prompt("Long Press Action!")

func update_nearby_interactables():
	current_interactables.clear()
	
	# Find all interactables in range
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = interaction_range
	query.shape = circle_shape
	query.transform = Transform2D(0, player.global_position)
	query.collision_mask = 0b10  # Assuming interactables are on layer 2
	
	# Alternative approach: check all nodes in group
	var all_interactables = get_tree().get_nodes_in_group("interactables")
	var previous_closest = closest_interactable
	closest_interactable = null
	var closest_distance = interaction_range
	
	for interactable in all_interactables:
		if not is_instance_valid(interactable) or not interactable.can_interact:
			continue
			
		var distance = player.global_position.distance_to(interactable.global_position)
		if distance <= interaction_range:
			current_interactables.append(interactable)
			
			# Find the closest one
			if distance < closest_distance:
				closest_distance = distance
				closest_interactable = interactable
	
	# Update interaction prompts
	if closest_interactable != previous_closest:
		update_interaction_prompt()

func update_interaction_prompt(override_text: String = ""):
	# Clear previous prompts
	for interactable in current_interactables:
		interactable.hide_prompt()
	
	# Show prompt for closest interactable
	if closest_interactable:
		var prompt_text = override_text
		if prompt_text.is_empty():
			prompt_text = get_interaction_prompt_text(closest_interactable)
		closest_interactable.show_prompt(prompt_text)

func get_interaction_prompt_text(interactable: Interactable) -> String:
	var base_text = interactable.get_interaction_text()
	var prompt = "[E] " + base_text
	
	# Add advanced interaction hints if available
	if interactable.has_double_press_action():
		prompt += " • [E][E] " + interactable.get_double_press_text()
	if interactable.has_long_press_action():
		prompt += " • [Hold E] " + interactable.get_long_press_text()
	
	return prompt

func perform_standard_interaction():
	if closest_interactable and closest_interactable.can_interact:
		closest_interactable.interact(player, InteractionType.Type.STANDARD)
		interaction_started.emit(closest_interactable)

func perform_double_press_interaction():
	if closest_interactable and closest_interactable.can_interact:
		closest_interactable.interact(player, InteractionType.Type.DOUBLE_PRESS)
		interaction_started.emit(closest_interactable)

func perform_long_press_interaction():
	if closest_interactable and closest_interactable.can_interact:
		closest_interactable.interact(player, InteractionType.Type.LONG_PRESS)
		interaction_started.emit(closest_interactable)

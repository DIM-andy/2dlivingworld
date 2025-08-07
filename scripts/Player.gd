extends CharacterBody2D

@export var speed: float = 100.0
@export var acceleration: float = 500.0
@export var friction: float = 500.0

var input_vector: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("player")

func _physics_process(delta):
	handle_input()
	apply_movement(delta)

func handle_input():
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	
	input_vector = input_vector.normalized()

func apply_movement(delta):
	if input_vector != Vector2.ZERO:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
	else:
		# Apply friction when not moving
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()

func _process(delta):
	# Debug info on space/enter
	if Input.is_action_just_pressed("ui_accept"):  # Space or Enter
		print_debug_info()

func print_debug_info():
	print("=== DEBUG INFO ===")
	print("Player position: ", position)
	print("Player velocity: ", velocity)
	
	var world_manager = get_tree().get_first_node_in_group("world_manager")
	if world_manager:
		print("Current cell: ", world_manager.world_to_cell(position))
		print("Active NPCs: ", world_manager.npc_manager.active_npcs.size())
		
		# Print NPC states
		for npc in world_manager.npc_manager.active_npcs:
			if is_instance_valid(npc):
				print("  %s: %s (Energy: %.1f)" % [npc.npc_name, npc.get_state_name(), npc.energy])
	
	print("===================")

extends CharacterBody2D

@export var speed: float = 100.0

func _ready():
	add_to_group("player")

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	
	velocity = input_vector.normalized() * speed
	move_and_slide()

func _process(delta):
	# Debug info on space/enter
	if Input.is_action_just_pressed("ui_accept"):  # Space or Enter
		print_debug_info()

func print_debug_info():
	print("=== DEBUG INFO ===")
	print("Player position: ", position)
	
	var world_manager = get_tree().get_first_node_in_group("world_manager")
	if world_manager:
		print("Current cell: ", world_manager.world_to_cell(position))
		print("Active NPCs: ", world_manager.npc_manager.active_npcs.size())
		
		# Print NPC states
		for npc in world_manager.npc_manager.active_npcs:
			if is_instance_valid(npc):
				print("  %s: %s (Energy: %.1f)" % [npc.npc_name, npc.get_state_name(), npc.energy])
	
	print("===================")

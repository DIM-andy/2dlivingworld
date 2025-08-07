extends CharacterBody2D
class_name NPC

enum AIState {
	IDLE,
	WANDERING,
	INTERACTING,
	WORKING,
	SLEEPING
}

@export var npc_name: String = "NPC"
@export var move_speed: float = 50.0
@export var interaction_range: float = 32.0

var current_state: AIState = AIState.IDLE
var current_cell: WorldCell
var target_position: Vector2
var state_timer: float = 0.0

# AI/Behavior variables
var wander_radius: float = 64.0
var home_position: Vector2
var schedule: Dictionary = {}

# Stats/needs (simplified for now)
var energy: float = 100.0
var social: float = 50.0

signal state_changed(new_state: AIState)

func _ready():
	home_position = position
	target_position = position
	add_to_group("npcs")
	
	# Create visual representation
	create_visual()
	create_collision()

func setup_in_cell(cell: WorldCell):
	current_cell = cell
	# Register with the NPC manager after we're in the tree
	call_deferred("register_with_manager")

func create_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.color = Color.BLUE
	sprite.position = Vector2(-8, -8)  # Center the rectangle
	add_child(sprite)

func create_collision():
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)

func update_ai(delta: float):
	state_timer += delta
	
	match current_state:
		AIState.IDLE:
			handle_idle_state(delta)
		AIState.WANDERING:
			handle_wandering_state(delta)
		AIState.INTERACTING:
			handle_interacting_state(delta)
		AIState.WORKING:
			handle_working_state(delta)
		AIState.SLEEPING:
			handle_sleeping_state(delta)
	
	# Update needs over time
	energy -= delta * 2.0  # Lose energy over time
	energy = max(0.0, energy)

func handle_idle_state(delta: float):
	if state_timer > randf_range(2.0, 5.0):  # Wait 2-5 seconds
		if randf() < 0.7:  # 70% chance to wander
			change_state(AIState.WANDERING)
		else:
			change_state(AIState.WORKING)

func handle_wandering_state(delta: float):
	# Move towards target
	var direction = (target_position - position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	# Check if reached target
	if position.distance_to(target_position) < 5.0:
		change_state(AIState.IDLE)
	
	# Change direction occasionally
	if state_timer > randf_range(3.0, 7.0):
		set_new_wander_target()
		state_timer = 0.0

func handle_interacting_state(delta: float):
	# Stop moving
	velocity = Vector2.ZERO
	
	if state_timer > randf_range(2.0, 4.0):
		change_state(AIState.IDLE)

func handle_working_state(delta: float):
	# Simple work simulation - just stand still and "work"
	velocity = Vector2.ZERO
	
	# Gain energy from working (representing satisfaction)
	energy += delta * 5.0
	energy = min(100.0, energy)
	
	if state_timer > randf_range(5.0, 10.0):
		change_state(AIState.IDLE)

func handle_sleeping_state(delta: float):
	velocity = Vector2.ZERO
	
	# Restore energy while sleeping
	energy += delta * 20.0
	energy = min(100.0, energy)
	
	if energy >= 90.0:  # Well rested
		change_state(AIState.IDLE)

func change_state(new_state: AIState):
	if current_state != new_state:
		current_state = new_state
		state_timer = 0.0
		state_changed.emit(new_state)
		
		# State entry logic
		match new_state:
			AIState.WANDERING:
				set_new_wander_target()
			AIState.SLEEPING:
				# Could move to bed location here
				pass

func set_new_wander_target():
	var angle = randf() * TAU
	var distance = randf_range(20.0, wander_radius)
	target_position = home_position + Vector2(cos(angle), sin(angle)) * distance
	
	# Keep within cell bounds if we have a cell reference
	if current_cell:
		var cell_bounds = Rect2(Vector2.ZERO, Vector2(current_cell.cell_size, current_cell.cell_size))
		target_position = Vector2(
			clamp(target_position.x, cell_bounds.position.x + 16, cell_bounds.size.x - 16),
			clamp(target_position.y, cell_bounds.position.y + 16, cell_bounds.size.y - 16)
		)

func interact_with_player(player: Node2D):
	print(npc_name + " says: Hello there!")
	change_state(AIState.INTERACTING)
	social += 10.0
	social = min(100.0, social)

func register_with_manager():
	# This gets called after the node is properly in the scene tree
	if get_tree() and get_tree().has_group("world_manager"):
		var world_manager = get_tree().get_first_node_in_group("world_manager")
		if world_manager and world_manager.npc_manager:
			world_manager.npc_manager.register_npc(self)

func get_state_name() -> String:
	match current_state:
		AIState.IDLE:
			return "Idle"
		AIState.WANDERING:
			return "Wandering"
		AIState.INTERACTING:
			return "Talking"
		AIState.WORKING:
			return "Working"
		AIState.SLEEPING:
			return "Sleeping"
		_:
			return "Unknown"

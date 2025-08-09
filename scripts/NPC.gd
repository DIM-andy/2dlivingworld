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
@export var wander_extension: float = 128.0 # How far an NPC can wander outside its cell
@export var interaction_range: float = 32.0
@export var show_debug_label: bool = true

# Static variables for global label control
static var global_labels_enabled: bool = false
static var labels_force_hidden: bool = false

var current_state: AIState = AIState.IDLE
var current_cell: WorldCell
var target_position: Vector2
var state_timer: float = 0.0

# UI
var debug_label: Label
var held_item_visual: ColorRect
var mouse_detection_area: Area2D
var is_mouse_hovering: bool = false
var is_player_nearby: bool = false
var player_reference: CharacterBody2D

# AI/Behavior variables
var wander_radius: float = 1024.0
var home_position: Vector2
var schedule: Dictionary = {}

# Stats/needs (simplified for now)
var energy: float = 100.0
var social: float = 50.0

# Inventory system
var inventory: NPCInventory

# Item preferences (can be set per NPC)
var preferred_items: Array[String] = []
var disliked_items: Array[String] = []

signal state_changed(new_state: AIState)

func _ready():
	home_position = position
	target_position = position
	add_to_group("npcs")
	
	# Find player reference
	call_deferred("find_player")
	
	# Create inventory system
	setup_inventory()
	
	# Create visual representation
	create_visual()
	create_collision()
	
	# Create debug label
	if show_debug_label:
		create_debug_label()
		create_mouse_detection()

func find_player():
	if get_tree().has_group("player"):
		player_reference = get_tree().get_first_node_in_group("player")

func setup_inventory():
	inventory = NPCInventory.new(self)
	add_child(inventory)
	
	# Connect inventory signals
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory.item_consumed.connect(_on_item_consumed)
	inventory.item_stored.connect(_on_item_stored)
	
	# Set up preferences (can be overridden by specific NPC types)
	setup_default_preferences()

func setup_default_preferences():
	# Default preferences - can be overridden in specific NPC scenes
	preferred_items = ["flower", "apple"]
	disliked_items = []
	
	# Set preferences in inventory
	inventory.set_preferences(preferred_items, disliked_items)
	
	# Default consumable types (NPCs will eat food and spend coins)
	inventory.set_consumable_types([
		InventoryItem.ItemType.FOOD,
		InventoryItem.ItemType.MISC  # Includes coins
	])

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

func create_debug_label():
	debug_label = Label.new()
	debug_label.add_theme_font_size_override("font_size", 8)
	debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.position = Vector2(-35, -45)  # Position above NPC
	debug_label.size = Vector2(70, 35)
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	style_box.corner_radius_bottom_left = 3
	style_box.corner_radius_bottom_right = 3
	style_box.corner_radius_top_left = 3
	style_box.corner_radius_top_right = 3
	debug_label.add_theme_stylebox_override("normal", style_box)
	
	# Start hidden
	debug_label.visible = false
	
	add_child(debug_label)
	update_debug_label()

func create_mouse_detection():
	# Create an area for mouse detection
	mouse_detection_area = Area2D.new()
	mouse_detection_area.name = "MouseDetection"
	
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0  # Slightly larger than visual for easier hovering
	collision_shape.shape = shape
	mouse_detection_area.add_child(collision_shape)
	
	# Set up mouse detection signals
	mouse_detection_area.mouse_entered.connect(_on_mouse_entered)
	mouse_detection_area.mouse_exited.connect(_on_mouse_exited)
	
	add_child(mouse_detection_area)

func update_debug_label():
	if not debug_label:
		return
	
	var state_text = get_state_name()
	var energy_bar = create_energy_bar(energy)
	var item_text = ""
	
	if inventory and inventory.has_item():
		var item = inventory.get_current_item()
		item_text = "📦" + item.item_name.substr(0, 3)  # Show first 3 chars of item name
	else:
		item_text = "📦---"
	
	debug_label.text = "%s\n%s\n%s\n%s" % [npc_name, state_text, energy_bar, item_text]

func create_energy_bar(energy_value: float) -> String:
	var bar_length = 6
	var filled_length = int((energy_value / 100.0) * bar_length)
	var bar = ""
	
	for i in bar_length:
		if i < filled_length:
			bar += "█"
		else:
			bar += "░"
	
	return bar

func update_ai(delta: float):
	state_timer += delta
	
	# Check player proximity for label visibility
	check_player_proximity()
	
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
	
	# Use items when appropriate
	consider_using_items(delta)
	
	# Update debug display
	if show_debug_label:
		update_debug_label()
		update_label_visibility()

func check_player_proximity():
	if not player_reference:
		return
	
	var distance = global_position.distance_to(player_reference.global_position)
	var was_nearby = is_player_nearby
	is_player_nearby = distance <= interaction_range
	
	# Update label visibility if proximity changed
	if was_nearby != is_player_nearby:
		update_label_visibility()

func update_label_visibility():
	if not debug_label:
		return
	
	# Check global toggle states
	if labels_force_hidden:
		debug_label.visible = false
		return
	
	if global_labels_enabled:
		debug_label.visible = true
		return
	
	# Show label if mouse hovering OR player is nearby
	debug_label.visible = is_mouse_hovering or is_player_nearby

func _on_mouse_entered():
	is_mouse_hovering = true
	update_label_visibility()

func _on_mouse_exited():
	is_mouse_hovering = false
	update_label_visibility()

func consider_using_items(delta: float):
	if not inventory or not inventory.has_item():
		return
	
	var item = inventory.get_current_item()
	
	# Use food when energy is low
	if item.item_type == InventoryItem.ItemType.FOOD and energy < 30.0:
		if randf() < 0.1:  # 10% chance per second when low energy
			inventory.consume_item()
			change_state(AIState.WORKING)  # Feel energized and work
	
	# Use tools for work (not implemented yet, but framework is here)
	elif item.item_type == InventoryItem.ItemType.TOOL and current_state == AIState.WORKING:
		# Tools could boost work efficiency in the future
		pass

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
	var work_efficiency = 5.0
	
	# Work better with tools
	if inventory and inventory.has_item():
		var item = inventory.get_current_item()
		if item.item_type == InventoryItem.ItemType.TOOL:
			work_efficiency *= 1.5
	
	energy += delta * work_efficiency
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
		# 1. Define the original cell boundary
		var cell_bounds = Rect2(current_cell.position, Vector2(current_cell.cell_size, current_cell.cell_size))
		
		# 2. Grow the boundary by the extension amount
		var expanded_bounds = cell_bounds.grow(wander_extension)
		
		# 3. Clamp the target position within the new, expanded bounds
		target_position = Vector2(
			clamp(target_position.x, expanded_bounds.position.x + 16, expanded_bounds.end.x - 16),
			clamp(target_position.y, expanded_bounds.position.y + 16, expanded_bounds.end.y - 16)
		)

func interact_with_player(player: Node2D):
	if GlobalMessageSystem:
		GlobalMessageSystem.add_dialogue(npc_name, "Hello there!")
	change_state(AIState.INTERACTING)
	social += 10.0
	social = min(100.0, social)

# New methods for inventory management
func receive_item(item: InventoryItem) -> bool:
	if not inventory:
		return false
	
	return inventory.give_item(item)

func has_item() -> bool:
	return inventory and inventory.has_item()

func get_held_item() -> InventoryItem:
	if inventory:
		return inventory.get_current_item()
	return null

func can_accept_item(item: InventoryItem) -> bool:
	if not inventory:
		return false
	
	return inventory.can_accept_item(item)

# Inventory event handlers
func _on_inventory_changed(old_item: InventoryItem, new_item: InventoryItem):
	update_held_item_visual()
	
	# Update debug label
	if show_debug_label:
		update_debug_label()

func _on_item_consumed(item: InventoryItem, npc: NPC):
	# React to consuming items
	match item.item_type:
		InventoryItem.ItemType.FOOD:
			# Show happiness animation or sound effect
			pass
		InventoryItem.ItemType.MISC:
			if item.item_name.to_lower() == "coin":
				# Maybe show coin sparkle effect
				pass

func _on_item_stored(item: InventoryItem, npc: NPC):
	# React to storing items
	pass

func update_held_item_visual():
	# Remove existing visual
	if held_item_visual:
		held_item_visual.queue_free()
		held_item_visual = null
	
	# Create new visual if NPC has item
	if inventory and inventory.has_item():
		var item = inventory.get_current_item()
		
		held_item_visual = ColorRect.new()
		held_item_visual.size = Vector2(6, 6)
		held_item_visual.color = item.item_color
		held_item_visual.position = Vector2(12, -10)  # Position to the right of NPC
		add_child(held_item_visual)

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

func activate():
	visible = true
	set_physics_process(true)
	# Re-enable collision
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").disabled = false

func deactivate():
	visible = false
	set_physics_process(false)
	# Disable collision to prevent interactions when inactive
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").disabled = true

# Static methods for global label control
static func toggle_all_labels():
	global_labels_enabled = !global_labels_enabled
	labels_force_hidden = false
	
	# Update all NPCs
	if Engine.get_main_loop() and Engine.get_main_loop().has_group("npcs"):
		var all_npcs = Engine.get_main_loop().get_nodes_in_group("npcs")
		for npc in all_npcs:
			if npc.has_method("update_label_visibility"):
				npc.update_label_visibility()
	
	# Send message about current state
	var state_text = "shown" if global_labels_enabled else "hidden"
	if GlobalMessageSystem:
		GlobalMessageSystem.add_system("NPC labels globally " + state_text)

static func hide_all_labels():
	labels_force_hidden = true
	global_labels_enabled = false
	
	# Update all NPCs
	if Engine.get_main_loop() and Engine.get_main_loop().has_group("npcs"):
		var all_npcs = Engine.get_main_loop().get_nodes_in_group("npcs")
		for npc in all_npcs:
			if npc.has_method("update_label_visibility"):
				npc.update_label_visibility()
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_system("All NPC labels force hidden")

static func reset_label_visibility():
	global_labels_enabled = false
	labels_force_hidden = false
	
	# Update all NPCs
	if Engine.get_main_loop() and Engine.get_main_loop().has_group("npcs"):
		var all_npcs = Engine.get_main_loop().get_nodes_in_group("npcs")
		for npc in all_npcs:
			if npc.has_method("update_label_visibility"):
				npc.update_label_visibility()
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_system("NPC label visibility reset to proximity/hover only")

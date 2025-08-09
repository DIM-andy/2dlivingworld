extends Node2D
class_name WorldManager

signal world_ready

@export var cell_size: int = 128  # Each cell is 128x128 pixels
@export var active_radius: int = 2  # How many cells around the player to keep active

var world_cells: Dictionary = {}
var active_cells: Dictionary = {}
var player_reference: Node2D
var current_player_cell: Vector2i = Vector2i(999, 999)  # Initialize to a dummy value

# Systems
var npc_manager: NPCManager
var time_system: TimeSystem
var inventory_system: InventorySystem

func _ready():
	setup_world_systems()
	world_ready.emit()
	var player = get_node("Player")
	set_player(player)

func _process(delta):
	if player_reference:
		_on_player_moved(player_reference.global_position)

func setup_world_systems():
	npc_manager = NPCManager.new()
	add_child(npc_manager)
	
	time_system = TimeSystem.new()
	add_child(time_system)
	
	inventory_system = InventorySystem.new()
	inventory_system.name = "InventorySystem"
	add_child(inventory_system)
	inventory_system.add_to_group("inventory_system")
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_system("Inventory system created and added to scene")
	else:
		print("Inventory system created and added to scene")

func set_player(player: Node2D):
	player_reference = player
	_on_player_moved(player_reference.global_position)

func _on_player_moved(new_pos: Vector2):
	var new_cell_pos = world_to_cell(new_pos)
	if new_cell_pos != current_player_cell:
		current_player_cell = new_cell_pos
		update_active_cells()

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / cell_size), floor(world_pos.y / cell_size))

func update_active_cells():
	var required_cells = get_cells_in_radius(current_player_cell, active_radius)
	var required_cells_set = {}
	for cell_pos in required_cells:
		required_cells_set[cell_pos] = true

	# Unload cells that are no longer in radius
	var cells_to_unload = []
	for cell_pos in active_cells.keys():
		if not required_cells_set.has(cell_pos):
			cells_to_unload.append(cell_pos)
	
	for cell_pos in cells_to_unload:
		if is_instance_valid(active_cells[cell_pos]):
			active_cells[cell_pos].deactivate()
		active_cells.erase(cell_pos)

	# Load new cells
	for cell_pos in required_cells:
		if not active_cells.has(cell_pos):
			var cell
			if world_cells.has(cell_pos):
				cell = world_cells[cell_pos]
				cell.activate()
			else:
				cell = create_world_cell(cell_pos)
				world_cells[cell_pos] = cell
			
			active_cells[cell_pos] = cell

func create_world_cell(cell_pos: Vector2i) -> WorldCell:
	var cell = WorldCell.new()
	add_child(cell)
	cell.setup(cell_pos, cell_size)
	cell.position = Vector2(cell_pos) * cell_size
	return cell

func get_cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			cells.append(Vector2i(x, y))
	return cells

extends Node2D
class_name WorldManager

signal world_ready

@export var world_size: Vector2i = Vector2i(5, 5)  # Start with 5x5 grid
@export var cell_size: int = 128  # Each cell is 128x128 pixels
@export var active_radius: int = 2  # How many cells around player to keep active

var world_cells: Dictionary = {}
var player_reference: Node2D
var current_player_cell: Vector2i

# Systems
var npc_manager: NPCManager
var time_system: TimeSystem

func _ready():
	setup_world_systems()
	generate_initial_world()
	world_ready.emit()
	# Set up player reference
	var player = get_node("Player")
	set_player(player)

func setup_world_systems():
	# Create core systems
	npc_manager = NPCManager.new()
	add_child(npc_manager)
	
	time_system = TimeSystem.new()
	add_child(time_system)

func generate_initial_world():
	for x in world_size.x:
		for y in world_size.y:
			var cell_pos = Vector2i(x, y)
			var cell = create_world_cell(cell_pos)
			world_cells[cell_pos] = cell

func create_world_cell(cell_pos: Vector2i) -> WorldCell:
	var cell = WorldCell.new()
	cell.setup(cell_pos, cell_size)
	add_child(cell)
	
	# Position the cell in world space
	cell.position = Vector2(cell_pos * cell_size)
	
	return cell

func set_player(player: Node2D):
	player_reference = player
	# Connect to player movement if needed
	if player.has_signal("position_changed"):
		player.position_changed.connect(_on_player_moved)

func _on_player_moved(new_pos: Vector2):
	var new_cell = world_to_cell(new_pos)
	if new_cell != current_player_cell:
		current_player_cell = new_cell
		update_active_cells()

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / cell_size)

func update_active_cells():
	# This is where you'd implement loading/unloading for larger worlds
	# For now, all cells stay active since it's small
	pass

func get_cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var cell_pos = Vector2i(x, y)
			if world_cells.has(cell_pos):
				cells.append(cell_pos)
	return cells

extends Node2D
class_name WorldCell

var cell_position: Vector2i
var cell_size: int
var is_active: bool = true

# Cell contents
var npcs_in_cell: Array[NPC] = []
var buildings: Array[Building] = []
var interactables: Array[Interactable] = []

# Spatial organization within cell
var spatial_grid: SpatialGrid

func setup(pos: Vector2i, size: int):
	cell_position = pos
	cell_size = size
	
	# Create spatial grid for this cell (optional optimization)
	spatial_grid = SpatialGrid.new()
	spatial_grid.setup(Rect2(Vector2.ZERO, Vector2(size, size)), 16)  # 16x16 sub-grid
	
	generate_cell_content()

func generate_cell_content():
	# This is where you'd add procedural generation later
	# For now, just add some basic content based on cell position
	
	if cell_position == Vector2i.ZERO:
		# Spawn town center
		spawn_building("TownHall", Vector2(cell_size/2, cell_size/2))
		
		# Spawn some initial NPCs
		for i in 3:
			var npc_pos = Vector2(
				randf_range(20, cell_size - 20),
				randf_range(20, cell_size - 20)
			)
			spawn_npc("Villager", npc_pos)
	
	else:
		# Add some random decorations
		add_decorations()

func spawn_npc(npc_type: String, pos: Vector2) -> NPC:
	var npc = load("res://npcs/" + npc_type + ".tscn").instantiate()
	add_child(npc)
	npc.position = pos
	npc.setup_in_cell(self)
	
	npcs_in_cell.append(npc)
	spatial_grid.add_object(npc, pos)
	
	return npc

func spawn_building(building_type: String, pos: Vector2) -> Building:
	# Placeholder - you'd load actual building scenes
	var building = Building.new()
	building.setup(building_type, pos)
	add_child(building)
	buildings.append(building)
	
	return building

func add_decorations():
	# Add random trees, rocks, etc.
	for i in randi_range(3, 8):
		var decoration = create_decoration()
		add_child(decoration)

func create_decoration() -> Node2D:
	var decoration = Node2D.new()
	var visual = ColorRect.new()
	visual.size = Vector2(8, 8)
	visual.color = Color.GREEN
	visual.position = Vector2(-4, -4)  # Center it
	decoration.add_child(visual)
	decoration.position = Vector2(
		randf_range(8, cell_size - 8),
		randf_range(8, cell_size - 8)
	)
	return decoration

func get_npcs_in_area(area: Rect2) -> Array[NPC]:
	return spatial_grid.get_objects_in_area(area)

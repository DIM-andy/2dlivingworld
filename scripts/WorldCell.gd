extends Node2D
class_name WorldCell

var cell_position: Vector2i
var cell_size: int
var is_active: bool = false

# Cell contents
var npcs_in_cell: Array[NPC] = []
var buildings: Array[Building] = []
var interactables: Array[Interactable] = []

# Spatial organization within cell
var spatial_grid: SpatialGrid

func setup(pos: Vector2i, size: int):
	cell_position = pos
	cell_size = size
	
	spatial_grid = SpatialGrid.new()
	spatial_grid.setup(Rect2(Vector2.ZERO, Vector2(size, size)), 16)
	
	generate_cell_content()
	
	# Start deactivated
	deactivate()
	# Activate right after setup
	activate()


func generate_cell_content():
	if cell_position == Vector2i.ZERO:
		spawn_building("TownHall", Vector2(cell_size/2, cell_size/2))
		for i in 4:
			var npc_pos = Vector2(randf_range(20, cell_size - 20), randf_range(20, cell_size - 20))
			var specialization = VillagerSpecialization.VillagerType.values()[i % VillagerSpecialization.VillagerType.size()]
			spawn_npc("Villager", npc_pos, specialization)
	else:
		add_decorations()

func activate():
	if is_active: return
	is_active = true
	visible = true
	set_process(true)
	
	for child in get_children():
		if child is CanvasItem:
			child.visible = true
		if child.has_method("set_physics_process"):
			child.set_physics_process(true)

func deactivate():
	if not is_active: return
	is_active = false
	visible = false
	set_process(false)
	
	for child in get_children():
		if child is CanvasItem:
			child.visible = false
		if child.has_method("set_physics_process"):
			child.set_physics_process(false)

func spawn_npc(npc_type: String, pos: Vector2, specialization: VillagerSpecialization.VillagerType = VillagerSpecialization.VillagerType.FARMER) -> NPC:
	var npc = load("res://npcs/" + npc_type + ".tscn").instantiate()
	
	# The NPC's position is relative to the cell, so we calculate its global position
	var global_pos = self.position + pos
	npc.global_position = global_pos
	
	npc.setup_in_cell(self)
	
	# Set specialization if the NPC has a specialization component
	var specialization_node = npc.get_node_or_null("VillagerSpecialization")
	if specialization_node:
		specialization_node.villager_type = specialization
	
	# Let the NPCManager handle the NPC from now on
	var world_manager = get_tree().get_first_node_in_group("world_manager")
	if world_manager and world_manager.npc_manager:
		world_manager.npc_manager.add_npc_to_world(npc)

	# Keep a reference for potential future use, but the cell is no longer the parent
	npcs_in_cell.append(npc)
	spatial_grid.add_object(npc, pos)
	
	return npc

func spawn_building(building_type: String, pos: Vector2) -> Building:
	var building = Building.new()
	building.setup(building_type, pos)
	add_child(building)
	buildings.append(building)
	
	return building

func add_decorations():
	for i in randi_range(3, 8):
		var decoration = create_decoration()
		add_child(decoration)

func create_decoration() -> Node2D:
	var decoration = Node2D.new()
	var visual = ColorRect.new()
	visual.size = Vector2(8, 8)
	visual.color = Color.GREEN
	visual.position = Vector2(-4, -4)
	decoration.add_child(visual)
	decoration.position = Vector2(randf_range(8, cell_size - 8), randf_range(8, cell_size - 8))
	return decoration

func get_npcs_in_area(area: Rect2) -> Array[NPC]:
	return spatial_grid.get_objects_in_area(area)

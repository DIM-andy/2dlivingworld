extends RefCounted
class_name SpatialGrid

var grid_size: Vector2i
var cell_size: Vector2
var grid_cells: Dictionary = {}
var bounds: Rect2

func setup(area: Rect2, grid_resolution: int):
	bounds = area
	grid_size = Vector2i(grid_resolution, grid_resolution)
	cell_size = Vector2(area.size.x / grid_resolution, area.size.y / grid_resolution)

func add_object(obj: Node2D, pos: Vector2):
	var grid_pos = world_to_grid(pos)
	if not grid_cells.has(grid_pos):
		grid_cells[grid_pos] = []
	grid_cells[grid_pos].append(obj)

func remove_object(obj: Node2D, pos: Vector2):
	var grid_pos = world_to_grid(pos)
	if grid_cells.has(grid_pos):
		grid_cells[grid_pos].erase(obj)

func world_to_grid(pos: Vector2) -> Vector2i:
	var relative_pos = pos - bounds.position
	return Vector2i(
		int(relative_pos.x / cell_size.x),
		int(relative_pos.y / cell_size.y)
	)

func get_objects_in_area(area: Rect2) -> Array:
	var objects = []
	var start_grid = world_to_grid(area.position)
	var end_grid = world_to_grid(area.position + area.size)
	
	for x in range(start_grid.x, end_grid.x + 1):
		for y in range(start_grid.y, end_grid.y + 1):
			var grid_pos = Vector2i(x, y)
			if grid_cells.has(grid_pos):
				objects.append_array(grid_cells[grid_pos])
	
	return objects

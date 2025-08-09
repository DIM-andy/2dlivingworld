extends Node
class_name NPCManager

var all_npcs: Array[NPC] = []
var active_npcs: Array[NPC] = []

var world_manager: WorldManager

func _ready():
	# Get a reference to the WorldManager to access its active cells
	world_manager = get_tree().get_first_node_in_group("world_manager")
	set_process(true)

func _process(delta):
	if not world_manager:
		return

	# Clear the list of active NPCs for this frame
	active_npcs.clear()
	
	# Check the status of every NPC in the world
	for npc in all_npcs:
		if is_instance_valid(npc):
			var npc_cell = world_manager.world_to_cell(npc.global_position)
			
			# If the NPC is in a currently active cell, activate it
			if world_manager.active_cells.has(npc_cell):
				npc.activate()
				active_npcs.append(npc)
				npc.update_ai(delta) # Update its AI
			# Otherwise, deactivate it
			else:
				npc.deactivate()

func add_npc_to_world(npc: NPC):
	if not all_npcs.has(npc):
		all_npcs.append(npc)
		# Add the NPC as a child of the manager, not the cell
		add_child(npc)

func remove_npc_from_world(npc: NPC):
	if all_npcs.has(npc):
		all_npcs.erase(npc)
		if is_instance_valid(npc):
			npc.queue_free()

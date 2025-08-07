extends CanvasLayer
class_name GameUI

@onready var debug_panel: DebugPanel
@onready var npc_label_container: Control

var world_manager: WorldManager
var time_system: TimeSystem

func _ready():
	# Create debug panel
	debug_panel = DebugPanel.new()
	add_child(debug_panel)
	
	# Create container for NPC labels
	npc_label_container = Control.new()
	npc_label_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	npc_label_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks
	add_child(npc_label_container)
	
	# Find world manager and time system
	call_deferred("setup_connections")

func setup_connections():
	if get_tree().has_group("world_manager"):
		world_manager = get_tree().get_first_node_in_group("world_manager")
		if world_manager:
			time_system = world_manager.time_system
			debug_panel.setup(world_manager, time_system)

func _process(delta):
	if world_manager:
		update_npc_labels()
	
	# Toggle debug panel with F1
	if Input.is_action_just_pressed("ui_select"):  # F1 key
		debug_panel.toggle_visibility()

func update_npc_labels():
	# Clear existing labels
	for child in npc_label_container.get_children():
		child.queue_free()
	
	# Add labels for all active NPCs
	if world_manager.npc_manager:
		for npc in world_manager.npc_manager.active_npcs:
			if is_instance_valid(npc) and npc.is_inside_tree():
				create_npc_label(npc)

func create_npc_label(npc: NPC):
	var label = NPCStateLabel.new()
	label.setup(npc, get_viewport().get_camera_2d())
	npc_label_container.add_child(label)

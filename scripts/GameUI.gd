extends CanvasLayer
class_name GameUI

@onready var debug_panel: DebugPanel

var world_manager: WorldManager
var time_system: TimeSystem

func _ready():
	# Create debug panel
	debug_panel = DebugPanel.new()
	add_child(debug_panel)
	
	# Find world manager and time system
	call_deferred("setup_connections")

func setup_connections():
	if get_tree().has_group("world_manager"):
		world_manager = get_tree().get_first_node_in_group("world_manager")
		if world_manager:
			time_system = world_manager.time_system
			debug_panel.setup(world_manager, time_system)

func _process(delta):
	# Toggle debug panel with F1
	if Input.is_action_just_pressed("ui_select"):  # F1 key
		debug_panel.toggle_visibility()

func update_npc_labels():
	# This is now handled by individual NPCs
	# We'll move the label creation to the NPCs themselves
	pass

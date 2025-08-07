extends Panel
class_name DebugPanel

var world_manager: WorldManager
var time_system: TimeSystem
var is_visible: bool = true

# UI elements
var time_label: Label
var npc_count_label: Label
var player_pos_label: Label
var performance_label: Label

func _init():
	# Panel properties
	size = Vector2(300, 200)
	position = Vector2(10, 10)
	
	# Panel styling
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.WHITE
	add_theme_stylebox_override("panel", style_box)
	
	create_ui_elements()

func create_ui_elements():
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "DEBUG INFO (F1 to toggle)"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title)
	
	# Time info
	time_label = Label.new()
	time_label.text = "Time: --:--"
	vbox.add_child(time_label)
	
	# NPC count
	npc_count_label = Label.new()
	npc_count_label.text = "NPCs: 0"
	vbox.add_child(npc_count_label)
	
	# Player position
	player_pos_label = Label.new()
	player_pos_label.text = "Player: (0, 0)"
	vbox.add_child(player_pos_label)
	
	# Performance info
	performance_label = Label.new()
	performance_label.text = "FPS: 60"
	vbox.add_child(performance_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "\nControls:\nArrows: Move\nSpace: Print debug info"
	instructions.add_theme_font_size_override("font_size", 10)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(instructions)

func setup(wm: WorldManager, ts: TimeSystem):
	world_manager = wm
	time_system = ts
	
	if time_system:
		time_system.time_changed.connect(_on_time_changed)

func _process(delta):
	update_debug_info()

func update_debug_info():
	if not world_manager:
		return
	
	# Update NPC count
	var npc_count = 0
	if world_manager.npc_manager:
		npc_count = world_manager.npc_manager.active_npcs.size()
	npc_count_label.text = "NPCs: %d" % npc_count
	
	# Update player position
	if world_manager.player_reference:
		var pos = world_manager.player_reference.position
		var cell = world_manager.world_to_cell(pos)
		player_pos_label.text = "Player: (%.0f, %.0f) Cell: (%d, %d)" % [pos.x, pos.y, cell.x, cell.y]
	
	# Update FPS
	performance_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _on_time_changed(current_time: float):
	if time_system:
		time_label.text = "Time: %s (Day %d)" % [time_system.get_time_of_day(), time_system.current_day]

func toggle_visibility():
	is_visible = !is_visible
	visible = is_visible

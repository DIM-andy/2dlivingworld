extends Label
class_name NPCStateLabel

var target_npc: NPC
var camera: Camera2D
var offset: Vector2 = Vector2(0, -25)  # Offset above NPC

func setup(npc: NPC, cam: Camera2D):
	target_npc = npc
	camera = cam
	
	# Label styling
	add_theme_font_size_override("font_size", 10)
	add_theme_color_override("font_color", Color.WHITE)
	
	# Add background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.6)
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color.GRAY
	add_theme_stylebox_override("normal", style_box)
	
	# Center the text
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(delta):
	if not is_instance_valid(target_npc) or not target_npc.is_inside_tree():
		queue_free()
		return
	
	update_position()
	update_text()

func update_position():
	if not camera:
		return
	
	# Convert NPC world position to screen position
	var npc_screen_pos = camera.to_local(target_npc.global_position)
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_zoom = camera.zoom
	
	# Calculate screen position accounting for camera zoom and position
	var screen_pos = (npc_screen_pos * camera_zoom) + (viewport_size * 0.5)
	screen_pos += offset * camera_zoom
	
	# Set label position
	position = screen_pos
	# Center the label on the position
	position.x -= size.x * 0.5

func update_text():
	var state_text = target_npc.get_state_name()
	var energy_bar = create_energy_bar(target_npc.energy)
	text = "%s\n%s\nE:%s" % [target_npc.npc_name, state_text, energy_bar]

func create_energy_bar(energy: float) -> String:
	var bar_length = 8
	var filled_length = int((energy / 100.0) * bar_length)
	var bar = ""
	
	for i in bar_length:
		if i < filled_length:
			bar += "█"
		else:
			bar += "░"
	
	return bar

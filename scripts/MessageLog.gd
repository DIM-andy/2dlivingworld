extends Panel
class_name MessageLog

signal message_added(message: String)

@export var max_messages: int = 50
@export var auto_hide_delay: float = 10.0  # Hide after 10 seconds of no new messages
@export var fade_duration: float = 0.3

var time_system: TimeSystem
var messages: Array[Dictionary] = []
var message_container: VBoxContainer
var scroll_container: ScrollContainer
var auto_hide_timer: Timer
var fade_tween: Tween
var is_visible_state: bool = true

# Message colors for different types
var message_colors = {
	"dialogue": Color.CYAN,
	"pickup": Color.YELLOW,
	"system": Color.WHITE,
	"interaction": Color.LIGHT_GREEN,
	"error": Color.RED
}

func _init():
	# Panel properties
	size = Vector2(400, 200)
	
	# Panel styling
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	add_theme_stylebox_override("panel", style_box)
	
	create_ui_elements()
	setup_auto_hide()

func _ready():
	# Set up anchoring for bottom-left positioning
	setup_anchoring()
	
	# Find time system
	call_deferred("find_time_system")

func setup_anchoring():
	# Anchor to bottom-left of the screen
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	
	# Position with margin from edges
	position.x = 10
	position.y = size.y + 235
	
	# Set anchor points for responsive positioning
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0

func find_time_system():
	if get_tree().has_group("world_manager"):
		var world_manager = get_tree().get_first_node_in_group("world_manager")
		if world_manager:
			time_system = world_manager.time_system

func create_ui_elements():
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# Title bar
	var title_bar = HBoxContainer.new()
	vbox.add_child(title_bar)
	
	var title = Label.new()
	title.text = "Game Log"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color.WHITE)
	title_bar.add_child(title)
	
	# Add spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)
	
	# Clear button
	var clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.add_theme_font_size_override("font_size", 10)
	clear_button.custom_minimum_size = Vector2(50, 20)
	clear_button.pressed.connect(clear_messages)
	title_bar.add_child(clear_button)
	
	# Scroll container for messages
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll_container)
	
	# Message container
	message_container = VBoxContainer.new()
	message_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_container.add_theme_constant_override("separation", 1)
	scroll_container.add_child(message_container)

func setup_auto_hide():
	auto_hide_timer = Timer.new()
	auto_hide_timer.wait_time = auto_hide_delay
	auto_hide_timer.one_shot = true
	auto_hide_timer.timeout.connect(_on_auto_hide_timeout)
	add_child(auto_hide_timer)

func add_message(text: String, message_type: String = "system"):
	var timestamp = get_timestamp()
	var message_data = {
		"text": text,
		"type": message_type,
		"timestamp": timestamp,
		"full_message": "[%s] %s" % [timestamp, text]
	}
	
	messages.append(message_data)
	
	# Remove old messages if we exceed max
	while messages.size() > max_messages:
		messages.pop_front()
		if message_container.get_child_count() > 0:
			message_container.get_child(0).queue_free()
	
	create_message_label(message_data)
	
	# Show the panel and reset auto-hide timer
	show_panel()
	auto_hide_timer.start()
	
	message_added.emit(text)

func create_message_label(message_data: Dictionary):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size.y = 20
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Set the message color based on type
	var color = message_colors.get(message_data.type, Color.WHITE)
	var color_hex = color.to_html()
	
	# Format the message with color and timestamp
	var formatted_message = "[color=%s][color=gray][%s][/color] %s[/color]" % [
		color_hex, 
		message_data.timestamp, 
		message_data.text
	]
	label.text = formatted_message
	
	message_container.add_child(label)
	
	# Auto-scroll to bottom - wait longer for layout to update
	call_deferred("_wait_and_scroll")

func _wait_and_scroll():
	# Wait for the layout to update, then scroll
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to be sure
	scroll_to_bottom()

func scroll_to_bottom():
	if scroll_container:
		# Force a layout update first
		scroll_container.queue_redraw()
		# Set to maximum value
		var vscroll = scroll_container.get_v_scroll_bar()
		if vscroll:
			scroll_container.scroll_vertical = int(vscroll.max_value)

func get_timestamp() -> String:
	if time_system:
		return time_system.get_time_of_day()
	else:
		# Fallback to real time if game time isn't available
		var time_dict = Time.get_time_dict_from_system()
		return "%02d:%02d" % [time_dict.hour, time_dict.minute]

func clear_messages():
	messages.clear()
	for child in message_container.get_children():
		child.queue_free()

func show_panel():
	if not is_visible_state:
		is_visible_state = true
		if fade_tween:
			fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func hide_panel():
	if is_visible_state:
		is_visible_state = false
		if fade_tween:
			fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.3, fade_duration)

func _on_auto_hide_timeout():
	hide_panel()

# Convenience methods for different message types
func add_dialogue(speaker: String, text: String):
	add_message("%s: %s" % [speaker, text], "dialogue")

func add_pickup(item_name: String):
	add_message("Picked up %s" % item_name, "pickup")

func add_interaction(text: String):
	add_message(text, "interaction")

func add_system(text: String):
	add_message(text, "system")

func add_error(text: String):
	add_message(text, "error")

# Handle mouse interaction to show/hide
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Toggle visibility when clicked
			if is_visible_state and modulate.a < 0.5:
				show_panel()
			auto_hide_timer.start()  # Reset the auto-hide timer

extends Control
class_name InventoryUI

var inventory_system: InventorySystem
var slot_panels: Array[Panel] = []
var slot_labels: Array[Label] = []
var slot_icons: Array[ColorRect] = []

@export var slot_size: Vector2 = Vector2(60, 60)
@export var slot_spacing: float = 10.0

func _init():
	# Set initial size
	size = Vector2(280, 80)

func _ready():
	# Position at top-center of screen after we're in the tree
	position_at_top_center()
	create_inventory_slots()
	call_deferred("find_inventory_system")

func position_at_top_center():
	# Center horizontally at the top of the screen
	var viewport_size = get_viewport().get_visible_rect().size
	position.x = (viewport_size.x - size.x) / 2
	position.y = 10

func find_inventory_system():
	# Look for inventory system in the scene
	if get_tree().has_group("inventory_system"):
		inventory_system = get_tree().get_first_node_in_group("inventory_system")
	else:
		# Try to find it as a child of world manager
		if get_tree().has_group("world_manager"):
			var world_manager = get_tree().get_first_node_in_group("world_manager")
			if world_manager:
				inventory_system = world_manager.get_node_or_null("InventorySystem")
	
	if inventory_system:
		connect_signals()

func connect_signals():
	if inventory_system:
		inventory_system.inventory_changed.connect(_on_inventory_changed)
		inventory_system.item_equipped.connect(_on_item_equipped)
		inventory_system.item_unequipped.connect(_on_item_unequipped)

func create_inventory_slots():
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", int(slot_spacing))
	add_child(hbox)
	
	for i in 4:  # 4 slots
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = slot_size
		
		# Panel styling
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
		style_box.corner_radius_bottom_left = 5
		style_box.corner_radius_bottom_right = 5
		style_box.corner_radius_top_left = 5
		style_box.corner_radius_top_right = 5
		slot_panel.add_theme_stylebox_override("panel", style_box)
		
		hbox.add_child(slot_panel)
		slot_panels.append(slot_panel)
		
		# Key number label
		var key_label = Label.new()
		key_label.text = str(i + 1)
		key_label.add_theme_font_size_override("font_size", 12)
		key_label.add_theme_color_override("font_color", Color.WHITE)
		key_label.position = Vector2(5, 5)
		slot_panel.add_child(key_label)
		
		# Item icon (ColorRect for now)
		var icon = ColorRect.new()
		icon.size = Vector2(30, 30)
		icon.position = Vector2(15, 15)
		icon.visible = false
		slot_panel.add_child(icon)
		slot_icons.append(icon)
		
		# Item name label
		var item_label = Label.new()
		item_label.add_theme_font_size_override("font_size", 8)
		item_label.add_theme_color_override("font_color", Color.WHITE)
		item_label.position = Vector2(2, 48)
		item_label.size = Vector2(56, 10)
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_label.clip_contents = true
		slot_panel.add_child(item_label)
		slot_labels.append(item_label)

func _on_inventory_changed(slot_index: int, item: InventoryItem):
	if slot_index < 0 or slot_index >= slot_panels.size():
		return
	
	if item == null:
		# Empty slot
		slot_icons[slot_index].visible = false
		slot_labels[slot_index].text = ""
	else:
		# Show item
		slot_icons[slot_index].color = item.item_color
		slot_icons[slot_index].visible = true
		slot_labels[slot_index].text = item.item_name

func _on_item_equipped(slot_index: int, item: InventoryItem):
	# Highlight the equipped slot
	update_slot_highlighting()

func _on_item_unequipped():
	# Remove highlighting from all slots
	update_slot_highlighting()

func update_slot_highlighting():
	for i in slot_panels.size():
		var style_box = slot_panels[i].get_theme_stylebox("panel").duplicate()
		
		if inventory_system and inventory_system.held_item_slot == i:
			# Highlight equipped slot
			style_box.border_color = Color.YELLOW
			style_box.border_width_left = 3
			style_box.border_width_right = 3
			style_box.border_width_top = 3
			style_box.border_width_bottom = 3
		else:
			# Normal slot
			style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
			style_box.border_width_left = 2
			style_box.border_width_right = 2
			style_box.border_width_top = 2
			style_box.border_width_bottom = 2
		
		slot_panels[i].add_theme_stylebox_override("panel", style_box)

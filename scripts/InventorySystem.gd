extends Node
class_name InventorySystem

signal inventory_changed(slot_index: int, item: InventoryItem)
signal item_equipped(slot_index: int, item: InventoryItem)
signal item_unequipped()

@export var max_slots: int = 4

var inventory_slots: Array[InventoryItem] = []
var currently_held_item: InventoryItem = null
var held_item_slot: int = -1
var player_reference: CharacterBody2D

func _ready():
	# Initialize empty inventory
	inventory_slots.resize(max_slots)
	for i in max_slots:
		inventory_slots[i] = null
	
	# Find player reference
	call_deferred("find_player")

func _input(event):
	if event is InputEventKey and event.pressed:
		# Handle number keys 1-4 for inventory slots
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			var slot_index = event.keycode - KEY_1
			if slot_index < max_slots:
				toggle_item_slot(slot_index)

func find_player():
	if get_tree().has_group("player"):
		player_reference = get_tree().get_first_node_in_group("player")

func _process(delta):
	# Remove the input handling from _process since we're using _input now
	pass

func add_item(item: InventoryItem) -> bool:
	# Find first empty slot
	for i in max_slots:
		if inventory_slots[i] == null:
			inventory_slots[i] = item
			inventory_changed.emit(i, item)
			
			if GlobalMessageSystem:
				GlobalMessageSystem.add_system("Added %s to inventory (slot %d)" % [item.item_name, i + 1])
			
			return true
	
	# Inventory full
	if GlobalMessageSystem:
		GlobalMessageSystem.add_system("Inventory is full!")
	return false

func toggle_item_slot(slot_index: int):
	if slot_index < 0 or slot_index >= max_slots:
		return
	
	var item = inventory_slots[slot_index]
	if item == null:
		return  # Empty slot
	
	# If this item is already held, put it away
	if held_item_slot == slot_index:
		unequip_held_item()
	else:
		# Equip this item (unequip previous if any)
		equip_item(slot_index)

func equip_item(slot_index: int):
	if slot_index < 0 or slot_index >= max_slots:
		return
	
	var item = inventory_slots[slot_index]
	if item == null:
		return
	
	# Unequip previous item if any
	if currently_held_item:
		unequip_held_item()
	
	# Equip new item
	currently_held_item = item
	held_item_slot = slot_index
	
	# Create visual representation on player
	create_held_item_visual()
	
	item_equipped.emit(slot_index, item)
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_system("Equipped %s" % item.item_name)

func unequip_held_item():
	if currently_held_item and player_reference:
		# Remove visual representation
		remove_held_item_visual()
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_system("Put away %s" % currently_held_item.item_name)
	
	currently_held_item = null
	held_item_slot = -1
	item_unequipped.emit()

func create_held_item_visual():
	if not player_reference or not currently_held_item:
		return
	
	# Remove any existing held item visual
	remove_held_item_visual()
	
	# Create new visual
	var held_visual = ColorRect.new()
	held_visual.name = "HeldItemVisual"
	held_visual.size = Vector2(8, 8)
	held_visual.color = currently_held_item.item_color
	held_visual.position = Vector2(15, -5)  # Position to the right of player
	player_reference.add_child(held_visual)

func remove_held_item_visual():
	if player_reference:
		var existing_visual = player_reference.get_node_or_null("HeldItemVisual")
		if existing_visual:
			existing_visual.queue_free()

func use_held_item() -> InventoryItem:
	if currently_held_item:
		var item = currently_held_item
		
		# Remove from inventory
		if held_item_slot >= 0:
			inventory_slots[held_item_slot] = null
			inventory_changed.emit(held_item_slot, null)
		
		# Unequip
		unequip_held_item()
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_system("Used %s" % item.item_name)
		
		return item
	
	return null

func remove_item(slot_index: int) -> InventoryItem:
	if slot_index < 0 or slot_index >= max_slots:
		return null
	
	var item = inventory_slots[slot_index]
	if item == null:
		return null
	
	# If this item is currently held, unequip it
	if held_item_slot == slot_index:
		unequip_held_item()
	
	inventory_slots[slot_index] = null
	inventory_changed.emit(slot_index, null)
	
	return item

func get_item_at_slot(slot_index: int) -> InventoryItem:
	if slot_index < 0 or slot_index >= max_slots:
		return null
	return inventory_slots[slot_index]

func has_held_item() -> bool:
	return currently_held_item != null

func get_held_item() -> InventoryItem:
	return currently_held_item

func is_full() -> bool:
	for item in inventory_slots:
		if item == null:
			return false
	return true

func get_empty_slot_count() -> int:
	var count = 0
	for item in inventory_slots:
		if item == null:
			count += 1
	return count

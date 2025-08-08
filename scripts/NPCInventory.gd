extends Node
class_name NPCInventory

signal inventory_changed(old_item: InventoryItem, new_item: InventoryItem)
signal item_consumed(item: InventoryItem, npc: NPC)
signal item_stored(item: InventoryItem, npc: NPC)

var current_item: InventoryItem = null
var owner_npc: NPC

# Consumption preferences - what items this NPC will consume vs keep
var consumable_types: Array[InventoryItem.ItemType] = [
	InventoryItem.ItemType.FOOD
]

var preferred_items: Array[String] = []  # Specific item names this NPC prefers
var disliked_items: Array[String] = []   # Items this NPC doesn't want

func _init(npc: NPC):
	owner_npc = npc

func can_accept_item(item: InventoryItem) -> bool:
	# Check if NPC dislikes this specific item
	if disliked_items.has(item.item_name.to_lower()):
		return false
	
	# Always accept if slot is empty
	if current_item == null:
		return true
	
	# Check if we should replace current item
	return should_replace_current_item(item)

func should_replace_current_item(new_item: InventoryItem) -> bool:
	if current_item == null:
		return true
	
	# Prefer items the NPC specifically likes
	var new_item_preferred = preferred_items.has(new_item.item_name.to_lower())
	var current_item_preferred = preferred_items.has(current_item.item_name.to_lower())
	
	if new_item_preferred and not current_item_preferred:
		return true
	
	# Prefer higher value items
	if new_item.item_value > current_item.item_value:
		return true
	
	# Prefer consumable items if we have a non-consumable
	var new_consumable = is_consumable(new_item)
	var current_consumable = is_consumable(current_item)
	
	if new_consumable and not current_consumable:
		return true
	
	return false

func give_item(item: InventoryItem) -> bool:
	if not can_accept_item(item):
		return false
	
	var old_item = current_item
	
	# If we already have an item and need to replace it
	if current_item != null:
		drop_current_item()
	
	current_item = item
	inventory_changed.emit(old_item, current_item)
	
	# Decide whether to consume or store
	if should_consume_item(item):
		consume_item()
	else:
		store_item()
	
	return true

func should_consume_item(item: InventoryItem) -> bool:
	# Check if item type is consumable
	if consumable_types.has(item.item_type):
		return true
	
	# Check for specific consumable items
	var consumable_names = ["coin", "apple", "flower"]  # Add more as needed
	if consumable_names.has(item.item_name.to_lower()):
		return true
	
	return false

func consume_item():
	if current_item == null:
		return
	
	var consumed_item = current_item
	current_item = null
	
	# Apply item effects to NPC
	apply_item_effects(consumed_item)
	
	item_consumed.emit(consumed_item, owner_npc)
	inventory_changed.emit(consumed_item, null)
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_interaction(
			"%s consumed the %s!" % [owner_npc.npc_name, consumed_item.item_name]
		)

func store_item():
	if current_item == null:
		return
	
	item_stored.emit(current_item, owner_npc)
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_interaction(
			"%s is now holding a %s" % [owner_npc.npc_name, current_item.item_name]
		)

func apply_item_effects(item: InventoryItem):
	if not owner_npc:
		return
	
	match item.item_type:
		InventoryItem.ItemType.FOOD:
			owner_npc.energy += item.item_value * 2.0
			owner_npc.energy = min(100.0, owner_npc.energy)
		InventoryItem.ItemType.GIFT:
			owner_npc.social += item.item_value * 3.0
			owner_npc.social = min(100.0, owner_npc.social)
		InventoryItem.ItemType.MISC:
			if item.item_name.to_lower() == "coin":
				# Coins might make NPCs happier or more social
				owner_npc.social += item.item_value * 1.5
				owner_npc.social = min(100.0, owner_npc.social)

func drop_current_item():
	if current_item == null:
		return
	
	# Create a pickup item in the world at NPC's position
	create_dropped_item(current_item, owner_npc.position)
	
	if GlobalMessageSystem:
		GlobalMessageSystem.add_interaction(
			"%s dropped their %s" % [owner_npc.npc_name, current_item.item_name]
		)
	
	var old_item = current_item
	current_item = null
	inventory_changed.emit(old_item, null)

func create_dropped_item(item: InventoryItem, position: Vector2):
	# Create a new pickup item in the world
	var pickup_scene = preload("res://items/TestItem.tscn")
	var pickup_item = pickup_scene.instantiate()
	
	# Configure the pickup item
	pickup_item.item_name = item.item_name
	pickup_item.item_value = item.item_value
	pickup_item.item_type = get_item_type_string(item.item_type)
	
	# Add to the world
	if owner_npc.get_tree() and owner_npc.get_tree().has_group("world_manager"):
		var world_manager = owner_npc.get_tree().get_first_node_in_group("world_manager")
		if world_manager:
			world_manager.add_child(pickup_item)
			pickup_item.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))

func get_item_type_string(item_type: InventoryItem.ItemType) -> String:
	match item_type:
		InventoryItem.ItemType.FOOD:
			return "apple"  # Default food type
		InventoryItem.ItemType.GIFT:
			return "flower"  # Default gift type
		InventoryItem.ItemType.TOOL:
			return "stick"   # Default tool type
		InventoryItem.ItemType.MISC:
			return "coin"    # Default misc type
		_:
			return "coin"

func has_item() -> bool:
	return current_item != null

func get_current_item() -> InventoryItem:
	return current_item

func is_consumable(item: InventoryItem) -> bool:
	return should_consume_item(item)

func set_preferences(preferred: Array[String] = [], disliked: Array[String] = []):
	preferred_items = preferred
	disliked_items = disliked

func set_consumable_types(types: Array[InventoryItem.ItemType]):
	consumable_types = types

# Helper method to get reaction text based on what happened
func get_last_action_reaction() -> String:
	if current_item == null:
		return owner_npc.npc_name + " has nothing."
	else:
		return owner_npc.npc_name + " is holding a " + current_item.item_name + "."

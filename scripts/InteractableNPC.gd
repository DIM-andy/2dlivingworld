extends Interactable
class_name InteractableNPC

@export var npc_reference: NPC
@export var dialogue_texts: Array[String] = ["Hello!", "How are you?", "Nice weather today!"]
@export var friendship_level: int = 0

var current_dialogue_index: int = 0

func _ready():
	super._ready()
	interaction_text = "Talk"
	double_press_text = "Wave"
	long_press_text = "Hug"
	
	# If no NPC reference, try to find parent NPC
	if not npc_reference:
		var parent = get_parent()
		if parent is NPC:
			npc_reference = parent

func get_interaction_text() -> String:
	# Check if player is holding something
	var inventory_system = get_inventory_system()
	if inventory_system and inventory_system.has_held_item():
		var held_item = inventory_system.get_held_item()
		if held_item.can_be_given:
			return "Give " + held_item.item_name
	
	return interaction_text

func perform_standard_interaction(player: Node2D):
	if npc_reference:
		# Check if player is holding an item to give
		var inventory_system = get_inventory_system()
		if inventory_system and inventory_system.has_held_item():
			var held_item = inventory_system.get_held_item()
			if held_item.can_be_given:
				give_item_to_npc(held_item, inventory_system)
				return
		
		# Normal dialogue
		var dialogue = dialogue_texts[current_dialogue_index % dialogue_texts.size()]
		
		# Use the global message system instead of print
		if GlobalMessageSystem:
			GlobalMessageSystem.add_dialogue(npc_reference.npc_name, dialogue)
		
		current_dialogue_index += 1
		
		# Make NPC look at player and change state
		npc_reference.change_state(NPC.AIState.INTERACTING)
		friendship_level += 1

func give_item_to_npc(item: InventoryItem, inventory_system: InventorySystem):
	# Use the held item (removes it from inventory)
	var given_item = inventory_system.use_held_item()
	
	if given_item:
		# NPC reaction based on item type
		var reaction = get_npc_reaction(given_item)
		var friendship_gain = get_friendship_value(given_item)
		
		friendship_level += friendship_gain
		npc_reference.social += friendship_gain * 2.0
		npc_reference.change_state(NPC.AIState.INTERACTING)
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction("You gave %s to %s. %s" % [
				given_item.item_name, 
				npc_reference.npc_name, 
				reaction
			])

func get_npc_reaction(item: InventoryItem) -> String:
	match item.item_type:
		InventoryItem.ItemType.FOOD:
			return npc_reference.npc_name + " enjoys the " + item.item_name + "!"
		InventoryItem.ItemType.GIFT:
			return npc_reference.npc_name + " loves the " + item.item_name + "!"
		InventoryItem.ItemType.MISC:
			if item.item_name == "Coin":
				return npc_reference.npc_name + " appreciates the coin."
			else:
				return npc_reference.npc_name + " accepts the " + item.item_name + "."
		InventoryItem.ItemType.TOOL:
			return npc_reference.npc_name + " finds the " + item.item_name + " useful."
		_:
			return npc_reference.npc_name + " thanks you for the " + item.item_name + "."

func get_friendship_value(item: InventoryItem) -> int:
	match item.item_type:
		InventoryItem.ItemType.GIFT:
			return 10
		InventoryItem.ItemType.FOOD:
			return 7
		InventoryItem.ItemType.MISC:
			return 3
		InventoryItem.ItemType.TOOL:
			return 5
		_:
			return 2

func perform_double_press_interaction(player: Node2D):
	if npc_reference:
		var message = "%s waves back at you!" % npc_reference.npc_name
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(message)
		
		friendship_level += 2

func perform_long_press_interaction(player: Node2D):
	if npc_reference:
		var message: String
		if friendship_level >= 5:
			message = "You hug %s! They seem happy." % npc_reference.npc_name
			friendship_level += 5
			npc_reference.social += 20.0
		else:
			message = "%s steps back awkwardly. Maybe you should talk more first..." % npc_reference.npc_name
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(message)

func get_inventory_system() -> InventorySystem:
	# Try to find inventory system
	if get_tree().has_group("inventory_system"):
		return get_tree().get_first_node_in_group("inventory_system")
	elif get_tree().has_group("world_manager"):
		var world_manager = get_tree().get_first_node_in_group("world_manager")
		if world_manager:
			return world_manager.get_node_or_null("InventorySystem")
	return null

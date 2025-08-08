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
			# Check if NPC can accept the item
			if npc_reference and npc_reference.can_accept_item(held_item):
				return "Give " + held_item.item_name
			else:
				return "Offer " + held_item.item_name + " (they might refuse)"
	
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
		var dialogue = get_contextual_dialogue()
		
		# Use the global message system
		if GlobalMessageSystem:
			GlobalMessageSystem.add_dialogue(npc_reference.npc_name, dialogue)
		
		current_dialogue_index += 1
		
		# Make NPC look at player and change state
		npc_reference.change_state(NPC.AIState.INTERACTING)
		friendship_level += 1

func get_contextual_dialogue() -> String:
	# Get different dialogue based on NPC state and items
	var base_dialogue = dialogue_texts[current_dialogue_index % dialogue_texts.size()]
	
	# Add context based on what NPC is holding
	if npc_reference.has_item():
		var held_item = npc_reference.get_held_item()
		var item_comments = [
			"I'm quite fond of this " + held_item.item_name + ".",
			"This " + held_item.item_name + " is quite useful!",
			"Thanks again for the " + held_item.item_name + "."
		]
		if randf() < 0.3:  # 30% chance to mention their item
			return item_comments[randi() % item_comments.size()]
	
	# Add context based on NPC energy/needs
	if npc_reference.energy < 30:
		var tired_comments = [
			"I'm feeling quite tired today.",
			"Could use some food or rest...",
			"Been working too hard lately."
		]
		if randf() < 0.4:  # 40% chance when tired
			return tired_comments[randi() % tired_comments.size()]
	
	return base_dialogue

func give_item_to_npc(item: InventoryItem, inventory_system: InventorySystem):
	# Check if NPC can accept the item first
	if not npc_reference.can_accept_item(item):
		var refusal_message = get_refusal_message(item)
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(refusal_message)
		return
	
	# Use the held item (removes it from player inventory)
	var given_item = inventory_system.use_held_item()
	
	if given_item:
		# Give item to NPC
		var accepted = npc_reference.receive_item(given_item)
		
		if accepted:
			# Calculate friendship gain
			var friendship_gain = get_friendship_value(given_item)
			friendship_level += friendship_gain
			npc_reference.social += friendship_gain * 2.0
			npc_reference.change_state(NPC.AIState.INTERACTING)
			
			# Get reaction message
			var reaction = get_acceptance_message(given_item)
			
			if GlobalMessageSystem:
				GlobalMessageSystem.add_interaction(reaction)
		else:
			# This shouldn't happen if can_accept_item worked correctly
			if GlobalMessageSystem:
				GlobalMessageSystem.add_interaction("Something went wrong with the item transfer.")

func get_acceptance_message(item: InventoryItem) -> String:
	var npc_name = npc_reference.npc_name
	
	# Check what the NPC will do with the item
	var will_consume = npc_reference.inventory.should_consume_item(item)
	
	var base_message = ""
	if will_consume:
		match item.item_type:
			InventoryItem.ItemType.FOOD:
				base_message = npc_name + " gratefully eats the " + item.item_name + "!"
			InventoryItem.ItemType.MISC:
				if item.item_name.to_lower() == "coin":
					base_message = npc_name + " pockets the " + item.item_name + " with a smile."
				else:
					base_message = npc_name + " examines and uses the " + item.item_name + "."
			_:
				base_message = npc_name + " accepts and uses the " + item.item_name + "."
	else:
		base_message = npc_name + " carefully takes the " + item.item_name + " and keeps it safe."
	
	# Add friendship level comments
	if friendship_level >= 20:
		base_message += " \"You're such a good friend!\""
	elif friendship_level >= 10:
		base_message += " \"Thank you so much!\""
	else:
		base_message += " \"Thanks!\""
	
	return base_message

func get_refusal_message(item: InventoryItem) -> String:
	var npc_name = npc_reference.npc_name
	
	# Check if it's because they have something better
	if npc_reference.has_item():
		var current_item = npc_reference.get_held_item()
		if current_item.item_value > item.item_value:
			return npc_name + " politely declines. \"I already have something better, but thanks!\""
		else:
			return npc_name + " says \"My hands are full right now, but I appreciate the thought!\""
	
	# Check if it's a disliked item
	if npc_reference.inventory.disliked_items.has(item.item_name.to_lower()):
		return npc_name + " shakes their head. \"No thank you, I don't really like those.\""
	
	# Generic refusal
	return npc_name + " politely declines the " + item.item_name + "."

func get_friendship_value(item: InventoryItem) -> int:
	var base_value = 2
	
	# Check if NPC prefers this item
	if npc_reference.inventory.preferred_items.has(item.item_name.to_lower()):
		base_value += 5
	
	# Add value based on item type
	match item.item_type:
		InventoryItem.ItemType.GIFT:
			base_value += 8
		InventoryItem.ItemType.FOOD:
			base_value += 5
		InventoryItem.ItemType.MISC:
			base_value += 3
		InventoryItem.ItemType.TOOL:
			base_value += 4
		_:
			base_value += 2
	
	# Scale with item value
	base_value += item.item_value / 2
	
	return base_value

func perform_double_press_interaction(player: Node2D):
	if npc_reference:
		var message = "%s waves back at you!" % npc_reference.npc_name
		
		# Add context if NPC is holding something
		if npc_reference.has_item():
			var held_item = npc_reference.get_held_item()
			message += " They show off their " + held_item.item_name + "."
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(message)
		
		friendship_level += 2

func perform_long_press_interaction(player: Node2D):
	if npc_reference:
		var message: String
		if friendship_level >= 15:
			message = "You hug %s warmly! They hug back enthusiastically." % npc_reference.npc_name
			friendship_level += 8
			npc_reference.social += 25.0
			
			# If they're holding something, they might share it
			if npc_reference.has_item() and randf() < 0.2:  # 20% chance
				var held_item = npc_reference.get_held_item()
				if held_item.item_type == InventoryItem.ItemType.FOOD:
					message += " \"Want to share this " + held_item.item_name + "?\""
		elif friendship_level >= 5:
			message = "You hug %s! They seem happy but a bit surprised." % npc_reference.npc_name
			friendship_level += 3
			npc_reference.social += 15.0
		else:
			message = "%s steps back awkwardly. \"We should talk more first...\"" % npc_reference.npc_name
		
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

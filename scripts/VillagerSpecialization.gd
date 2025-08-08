extends Node
class_name VillagerSpecialization

enum VillagerType {
	FARMER,
	TRADER,
	CRAFTSMAN,
	SCHOLAR,
	GUARD
}

@export var villager_type: VillagerType = VillagerType.FARMER

var parent_npc: NPC

func _ready():
	parent_npc = get_parent() as NPC
	if parent_npc:
		call_deferred("setup_specialization")

func setup_specialization():
	if not parent_npc or not parent_npc.inventory:
		return
	
	match villager_type:
		VillagerType.FARMER:
			setup_farmer()
		VillagerType.TRADER:
			setup_trader()
		VillagerType.CRAFTSMAN:
			setup_craftsman()
		VillagerType.SCHOLAR:
			setup_scholar()
		VillagerType.GUARD:
			setup_guard()

func setup_farmer():
	# Farmers love food and tools, dislike fancy gifts
	parent_npc.preferred_items = ["apple", "stick", "seed"]
	parent_npc.disliked_items = ["flower"]
	
	# Farmers consume food but keep tools
	parent_npc.inventory.set_consumable_types([
		InventoryItem.ItemType.FOOD,
		InventoryItem.ItemType.MISC  # Will eat food, spend coins
	])
	
	parent_npc.inventory.set_preferences(parent_npc.preferred_items, parent_npc.disliked_items)
	
	# Change visual to represent farmer
	update_npc_appearance(Color.BROWN, "Farmer")

func setup_trader():
	# Traders love coins and valuable items
	parent_npc.preferred_items = ["coin", "flower", "gem"]
	parent_npc.disliked_items = []
	
	# Traders consume very little, they hoard
	parent_npc.inventory.set_consumable_types([
		InventoryItem.ItemType.FOOD  # Only consume food when hungry
	])
	
	parent_npc.inventory.set_preferences(parent_npc.preferred_items, parent_npc.disliked_items)
	update_npc_appearance(Color.GOLD, "Trader")

func setup_craftsman():
	# Craftsmen love tools and materials
	parent_npc.preferred_items = ["stick", "stone", "metal"]
	parent_npc.disliked_items = ["flower"]
	
	# Craftsmen consume food but keep tools and materials
	parent_npc.inventory.set_consumable_types([
		InventoryItem.ItemType.FOOD,
		InventoryItem.ItemType.MISC
	])
	
	parent_npc.inventory.set_preferences(parent_npc.preferred_items, parent_npc.disliked_items)
	update_npc_appearance(Color.ORANGE_RED, "Craftsman")

func setup_scholar():
	# Scholars love books and scrolls, appreciate gifts
	parent_npc.preferred_items = ["book", "scroll", "flower"]
	parent_npc.disliked_items = ["stick"]
	
	# Scholars consume food and appreciate gifts but keep books
	parent_npc.inventory.set_consumable_types([
		InventoryItem.ItemType.FOOD,
		InventoryItem.ItemType.GIFT,  # They "consume" gifts by appreciating them
		InventoryItem.ItemType.MISC
	])
	
	parent_npc.inventory.set_preferences(parent_npc.preferred_items, parent_npc.disliked_items)
	update_npc_appearance(Color.PURPLE, "Scholar")

func setup_guard():
	# Guards appreciate weapons and armor
	parent_npc.preferred_items = ["sword", "shield", "coin"]
	parent_npc.disliked_items = ["flower"]
	
	# Guards consume food but keep weapons
	parent_npc.inventory.set_consumable_types([
		InventoryItem.ItemType.FOOD,
		InventoryItem.ItemType.MISC
	])
	
	parent_npc.inventory.set_preferences(parent_npc.preferred_items, parent_npc.disliked_items)
	update_npc_appearance(Color.RED, "Guard")

func update_npc_appearance(color: Color, type_name: String):
	# Find the ColorRect child that represents the NPC visual
	for child in parent_npc.get_children():
		if child is ColorRect and child.size == Vector2(16, 16):
			child.color = color
			break
	
	# Update NPC name to include type if not already set
	if not parent_npc.npc_name.contains(type_name):
		parent_npc.npc_name = parent_npc.npc_name + " the " + type_name

# Helper function to create specialized items
static func create_specialized_item(item_name: String) -> InventoryItem:
	match item_name.to_lower():
		"seed":
			var item = InventoryItem.new("Seed", "A farming seed", 3, Color.GREEN_YELLOW)
			item.item_type = InventoryItem.ItemType.MISC
			return item
		"gem":
			var item = InventoryItem.new("Gem", "A precious gemstone", 50, Color.CYAN)
			item.item_type = InventoryItem.ItemType.GIFT
			return item
		"stone":
			var item = InventoryItem.new("Stone", "A solid crafting stone", 4, Color.GRAY)
			item.item_type = InventoryItem.ItemType.MISC
			return item
		"metal":
			var item = InventoryItem.new("Metal", "A piece of metal", 8, Color.SILVER)
			item.item_type = InventoryItem.ItemType.MISC
			return item
		"book":
			var item = InventoryItem.new("Book", "A book of knowledge", 15, Color.BLUE)
			item.item_type = InventoryItem.ItemType.GIFT
			return item
		"scroll":
			var item = InventoryItem.new("Scroll", "An ancient scroll", 12, Color.BEIGE)
			item.item_type = InventoryItem.ItemType.GIFT
			return item
		"sword":
			var item = InventoryItem.new("Sword", "A sturdy sword", 25, Color.STEEL_BLUE)
			item.item_type = InventoryItem.ItemType.TOOL
			return item
		"shield":
			var item = InventoryItem.new("Shield", "A protective shield", 20, Color.BROWN)
			item.item_type = InventoryItem.ItemType.TOOL
			return item
		_:
			# Return a basic item if not found
			return InventoryItem.new(item_name, "A mysterious item", 5, Color.WHITE)

# Method to get reaction text based on villager type
func get_type_specific_reaction(item: InventoryItem) -> String:
	match villager_type:
		VillagerType.FARMER:
			if item.item_type == InventoryItem.ItemType.FOOD:
				return "This will help me work the fields better!"
			elif item.item_type == InventoryItem.ItemType.TOOL:
				return "Perfect for farm work!"
			else:
				return "I suppose this could be useful on the farm."
		
		VillagerType.TRADER:
			if item.item_name.to_lower() == "coin" or item.item_value > 10:
				return "Excellent! I can use this in my business."
			else:
				return "I might be able to trade this later."
		
		VillagerType.CRAFTSMAN:
			if item.item_type == InventoryItem.ItemType.TOOL or item.item_name.to_lower() in ["stick", "stone", "metal"]:
				return "This will be perfect for my craft!"
			else:
				return "I can probably find a use for this in my workshop."
		
		VillagerType.SCHOLAR:
			if item.item_type == InventoryItem.ItemType.GIFT:
				return "How thoughtful! This will inspire my studies."
			else:
				return "Interesting... I'll study this further."
		
		VillagerType.GUARD:
			if item.item_type == InventoryItem.ItemType.TOOL:
				return "This will help me protect the village!"
			else:
				return "I appreciate your contribution to village security."
		
		_:
			return "Thank you for this gift!"

extends Interactable
class_name PickupItem

@export var item_name: String = "Item"
@export var item_value: int = 1
@export var can_be_thrown: bool = false
@export var item_type: String = "coin"  # coin, apple, flower, stick

func _ready():
	super._ready()
	interaction_text = "Pick up " + item_name
	if can_be_thrown:
		long_press_text = "Throw"
	create_visual()

func create_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	
	# Set color based on item type
	var color = Color.YELLOW
	match item_type.to_lower():
		"coin":
			color = Color.GOLD
		"apple":
			color = Color.RED
		"flower":
			color = Color.MAGENTA
		"stick":
			color = Color.SADDLE_BROWN
		_:
			color = Color.YELLOW
	
	sprite.color = color
	sprite.position = Vector2(-6, -6)
	add_child(sprite)
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)

func perform_standard_interaction(player: Node2D):
	# Create inventory item based on type
	var inventory_item: InventoryItem
	
	match item_type.to_lower():
		"coin":
			inventory_item = InventoryItem.create_coin()
		"apple":
			inventory_item = InventoryItem.create_apple()
		"flower":
			inventory_item = InventoryItem.create_flower()
		"stick":
			inventory_item = InventoryItem.create_stick()
		_:
			inventory_item = InventoryItem.new(item_name, "A mysterious item", item_value)
	
	# Try to add to inventory
	var inventory_system = get_inventory_system()
	if inventory_system:
		var added = inventory_system.add_item(inventory_item)
		if added:
			if GlobalMessageSystem:
				GlobalMessageSystem.add_pickup(inventory_item.item_name)
			queue_free()  # Remove from world
		else:
			if GlobalMessageSystem:
				GlobalMessageSystem.add_system("Inventory is full!")
	else:
		if GlobalMessageSystem:
			GlobalMessageSystem.add_pickup(item_name)
		queue_free()

func perform_long_press_interaction(player: Node2D):
	if can_be_thrown:
		var message = "You throw the %s!" % item_name
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(message)
		
		# Implement throwing logic
		queue_free()

func get_inventory_system() -> InventorySystem:
	# Try to find inventory system
	if get_tree().has_group("inventory_system"):
		return get_tree().get_first_node_in_group("inventory_system")
	elif get_tree().has_group("world_manager"):
		var world_manager = get_tree().get_first_node_in_group("world_manager")
		if world_manager:
			return world_manager.get_node_or_null("InventorySystem")
	return null

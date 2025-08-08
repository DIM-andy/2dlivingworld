extends Resource
class_name InventoryItem

@export var item_name: String = "Item"
@export var item_description: String = "A basic item"
@export var item_value: int = 1
@export var item_color: Color = Color.YELLOW
@export var item_type: ItemType = ItemType.MISC
@export var can_be_given: bool = true
@export var can_be_thrown: bool = false
@export var stackable: bool = false
@export var max_stack: int = 1

enum ItemType {
	MISC,
	FOOD,
	TOOL,
	GIFT,
	QUEST
}

func _init(name: String = "Item", description: String = "A basic item", value: int = 1, color: Color = Color.YELLOW):
	item_name = name
	item_description = description
	item_value = value
	item_color = color

func get_type_name() -> String:
	match item_type:
		ItemType.MISC:
			return "Misc"
		ItemType.FOOD:
			return "Food"
		ItemType.TOOL:
			return "Tool"
		ItemType.GIFT:
			return "Gift"
		ItemType.QUEST:
			return "Quest"
		_:
			return "Unknown"

static func create_coin() -> InventoryItem:
	var item = InventoryItem.new("Coin", "A shiny gold coin", 10, Color.GOLD)
	item.item_type = ItemType.MISC
	item.stackable = true
	item.max_stack = 99
	return item

static func create_apple() -> InventoryItem:
	var item = InventoryItem.new("Apple", "A fresh red apple", 5, Color.RED)
	item.item_type = ItemType.FOOD
	item.can_be_given = true
	return item

static func create_flower() -> InventoryItem:
	var item = InventoryItem.new("Flower", "A beautiful flower", 3, Color.MAGENTA)
	item.item_type = ItemType.GIFT
	item.can_be_given = true
	return item

static func create_stick() -> InventoryItem:
	var item = InventoryItem.new("Stick", "A sturdy wooden stick", 2, Color.SADDLE_BROWN)
	item.item_type = ItemType.TOOL
	item.can_be_thrown = true
	return item

extends Interactable
class_name PickupItem

@export var item_name: String = "Item"
@export var item_value: int = 1
@export var can_be_thrown: bool = false

func _ready():
	super._ready()
	interaction_text = "Pick up " + item_name
	if can_be_thrown:
		long_press_text = "Throw"
	create_visual()

func create_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.color = Color.YELLOW
	sprite.position = Vector2(-6, -6)
	add_child(sprite)
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)

func perform_standard_interaction(player: Node2D):
	print("Picked up " + item_name + "!")
	# Add to player inventory (implement inventory system later)
	queue_free()  # Remove from world

func perform_long_press_interaction(player: Node2D):
	if can_be_thrown:
		print("You throw the " + item_name + "!")
		# Implement throwing logic
		queue_free()

extends StaticBody2D
class_name Building

var building_type: String
var building_data: Dictionary = {}

func setup(type: String, pos: Vector2):
	building_type = type
	position = pos
	create_visual()
	create_collision()

func create_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.color = Color.BROWN
	add_child(sprite)

func create_collision():
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	add_child(collision)

extends Camera2D
class_name PlayerCamera

@export var follow_speed: float = 5.0  # How fast camera catches up to player
@export var look_ahead_distance: float = 50.0  # How far ahead to look when moving
@export var deadzone_size: Vector2 = Vector2(20, 20)  # Player can move this much before camera starts following
@export var max_distance: float = 100.0  # Maximum distance camera can be from player

var target_node: Node2D
var base_position: Vector2
var look_ahead_offset: Vector2 = Vector2.ZERO

func _ready():
	# Make this the current camera
	make_current()
	
	# Find the player
	call_deferred("find_target")

func find_target():
	# Look for player in the scene
	if get_tree().has_group("player"):
		target_node = get_tree().get_first_node_in_group("player")
		if target_node:
			# Initialize camera position to player position
			global_position = target_node.global_position
			base_position = global_position

func _process(delta):
	if not target_node:
		return
	
	update_camera_position(delta)

func update_camera_position(delta):
	var target_pos = target_node.global_position
	
	# Calculate look-ahead based on player movement
	var player_velocity = Vector2.ZERO
	if target_node.has_method("get_velocity"):
		player_velocity = target_node.get_velocity()
	elif target_node.has_method("get_real_velocity"):
		player_velocity = target_node.get_real_velocity()
	
	# Calculate look-ahead offset
	if player_velocity.length() > 70.0:  # Only look ahead if moving fast enough
		var normalized_velocity = player_velocity.normalized()
		look_ahead_offset = normalized_velocity * look_ahead_distance
	else:
		look_ahead_offset = look_ahead_offset.move_toward(Vector2.ZERO, look_ahead_distance * delta)
	
	# Target position includes look-ahead
	var desired_position = target_pos + look_ahead_offset
	
	# Apply deadzone - only move camera if player is outside the deadzone
	var distance_from_base = target_pos.distance_to(base_position)
	if distance_from_base > deadzone_size.length():
		base_position = base_position.move_toward(target_pos, follow_speed * 60 * delta)
	
	# Smoothly move to desired position
	global_position = global_position.move_toward(desired_position, follow_speed * 60 * delta)
	
	# Ensure camera doesn't get too far from player
	var distance_to_player = global_position.distance_to(target_pos)
	if distance_to_player > max_distance:
		global_position = target_pos + (global_position - target_pos).normalized() * max_distance

# Optional: Add screen shake functionality
func add_screen_shake(intensity: float = 10.0, duration: float = 0.5):
	var tween = create_tween()
	var original_offset = offset
	
	for i in int(duration * 60):  # 60 FPS assumption
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(self, "offset", original_offset + shake_offset, 1.0/60.0)
	
	tween.tween_property(self, "offset", original_offset, 0.1)

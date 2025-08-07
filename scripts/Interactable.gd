extends Area2D
class_name Interactable

signal interacted(player: Node2D)

@export var interaction_text: String = "Interact"
var can_interact: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Show interaction prompt
		show_interaction_prompt(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		show_interaction_prompt(false)

func show_interaction_prompt(show: bool):
	# You'd implement UI prompt here
	pass

func interact(player: Node2D):
	if can_interact:
		interacted.emit(player)
		perform_interaction(player)

func perform_interaction(player: Node2D):
	# Override in derived classes
	pass

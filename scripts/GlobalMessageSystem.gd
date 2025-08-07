extends Node
# This should be added as an AutoLoad/Singleton in Project Settings

var message_log: MessageLog

func _ready():
	# Find the message log when the game starts
	call_deferred("find_message_log")

func find_message_log():
	if get_tree().has_group("message_log"):
		var game_ui = get_tree().get_first_node_in_group("message_log")
		if game_ui and game_ui.message_log:
			message_log = game_ui.message_log

# Convenience functions that can be called from anywhere
func add_message(text: String, message_type: String = "system"):
	if not message_log:
		find_message_log()
	
	if message_log:
		message_log.add_message(text, message_type)
	else:
		print("MessageLog not found: ", text)  # Fallback to console

func add_dialogue(speaker: String, text: String):
	add_message("%s: %s" % [speaker, text], "dialogue")

func add_pickup(item_name: String):
	add_message("Picked up %s" % item_name, "pickup")

func add_interaction(text: String):
	add_message(text, "interaction")

func add_system(text: String):
	add_message(text, "system")

func add_error(text: String):
	add_message(text, "error")

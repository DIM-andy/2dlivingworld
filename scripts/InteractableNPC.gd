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

func perform_standard_interaction(player: Node2D):
	if npc_reference:
		# Cycle through dialogue
		var dialogue = dialogue_texts[current_dialogue_index % dialogue_texts.size()]
		print(npc_reference.npc_name + " says: " + dialogue)
		current_dialogue_index += 1
		
		# Make NPC look at player and change state
		npc_reference.change_state(NPC.AIState.INTERACTING)
		friendship_level += 1

func perform_double_press_interaction(player: Node2D):
	if npc_reference:
		print(npc_reference.npc_name + " waves back at you!")
		friendship_level += 2

func perform_long_press_interaction(player: Node2D):
	if npc_reference and friendship_level >= 5:
		print("You hug " + npc_reference.npc_name + "! They seem happy.")
		friendship_level += 5
		npc_reference.social += 20.0
	else:
		print(npc_reference.npc_name + " steps back awkwardly. Maybe you should talk more first...")

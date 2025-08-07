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
		
		# Use the global message system instead of print
		if GlobalMessageSystem:
			GlobalMessageSystem.add_dialogue(npc_reference.npc_name, dialogue)
		
		current_dialogue_index += 1
		
		# Make NPC look at player and change state
		npc_reference.change_state(NPC.AIState.INTERACTING)
		friendship_level += 1

func perform_double_press_interaction(player: Node2D):
	if npc_reference:
		var message = "%s waves back at you!" % npc_reference.npc_name
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(message)
		
		friendship_level += 2

func perform_long_press_interaction(player: Node2D):
	if npc_reference:
		var message: String
		if friendship_level >= 5:
			message = "You hug %s! They seem happy." % npc_reference.npc_name
			friendship_level += 5
			npc_reference.social += 20.0
		else:
			message = "%s steps back awkwardly. Maybe you should talk more first..." % npc_reference.npc_name
		
		if GlobalMessageSystem:
			GlobalMessageSystem.add_interaction(message)

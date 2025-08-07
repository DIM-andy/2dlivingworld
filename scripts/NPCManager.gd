extends Node
class_name NPCManager

var active_npcs: Array[NPC] = []
var npc_update_timer: float = 0.0
var update_interval: float = 0.1  # Update NPCs every 0.1 seconds

func _ready():
	set_process(true)

func _process(delta):
	npc_update_timer += delta
	if npc_update_timer >= update_interval:
		update_active_npcs(npc_update_timer)
		npc_update_timer = 0.0

func update_active_npcs(delta: float):
	for npc in active_npcs:
		if is_instance_valid(npc):
			npc.update_ai(delta)

func register_npc(npc: NPC):
	if not active_npcs.has(npc):
		active_npcs.append(npc)

func unregister_npc(npc: NPC):
	active_npcs.erase(npc)

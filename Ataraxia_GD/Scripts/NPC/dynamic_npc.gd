extends Character
class_name DynamicNPC
# TODO: Big things, FOCUS ON NPC first
# JobDriver class \ resource, occupations
# Skills for both player and NPCs
# DNPC generator for region\town root (DONE), consider race habitat and amount + paths
#	this ^ will need some reworks after regions are introduced
# accumulate time from last time scene visited and calculate progress on diff
# Event and Quest systems for both DNPC and SNPC

var npc_name: String
var race_name: String
var age: int = 0
var sex: String

@onready var npc_uid: int
signal NPC_DEATH(NPC_UID: int)
signal NPC_UNLOAD(NPC_UID: int)
	
func _ready():
	age = randi_range(12, 85) * TimeProcesser.year_to_ticks
	print("_ready called, race_name is already set")
	get_parent().npc_process_time.connect(_on_time_process)
	
func sprite_handler():
	if sex == "Male":
		pronouns["third_face"] = "he"
		pronouns["possesive"] = "his"
	if sex == "Female":
		pronouns["third_face"] = "she"
		pronouns["possesive"] = "her"
	if sex in ["BeastMale", "BeastFemale"]:
		pronouns["third_face"] = "it"
		pronouns["possesive"] = "it's"
	
func _on_time_process(time_amount: int):
	var ticks_to_process: int = TimeProcesser.time_to_ticks(time_amount)
	age += ticks_to_process
	# add human-readable age and compare it, too much calculations.
	# handle ticks less than 5 min | ticks under 5 min BREAK COMBAT DEATH
	print("%s processing time %d, ticks to process: %d" % [npc_name, time_amount, ticks_to_process])
	
func rot():
	corpse_decaying_timer += 5
	print("%s rotting, %d / %d" % [npc_name, corpse_decaying_timer, corpse_decay_time])
	if corpse_decaying_timer >= corpse_decay_time:
		print("%s finished rotting, clearing" % npc_name)
		NPC_UNLOAD.emit(npc_uid)
		queue_free()
		return false
	return true

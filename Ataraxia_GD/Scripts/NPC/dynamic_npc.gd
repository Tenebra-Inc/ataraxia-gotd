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
# Split routine controller for simplicity
# need routine_type, current path export, either store part in routine
@onready var routine_handler = $RoutineController
@onready var race = $PropertyController/RaceController.get_race(race_name, npc_name)
@onready var stats_handler = $PropertyController/StatsController.StatsHandler.new()
@onready var body = $PropertyController/BodyController.Body.new()
signal NPC_DEATH(NPC_UID: int)
signal NPC_DESTROY(NPC_UID: int)

func get_hit(bodypart_name: String, damage_amount: int, bleed_severity: int):
	# think about splitting into two modules -> npc body and npc behaviour
	print("%s got hit by player in %s by %d with bleed severity %d" % [npc_name, bodypart_name, damage_amount, bleed_severity])
	body.bodypart_get_hit(bodypart_name, damage_amount, bleed_severity)
	if !body.is_alive: handle_death()
	else: update_hbar()

func _mouse_enter() -> void:
	# TODO: maybe change to RichText + statuses?
	$PanelContainer/Label.text = "%s %d %s %s\n%d/%d %d\n" % [npc_name, age/TimeProcesser.year_to_ticks, sex, race_name, body.get_current_health(), body.get_max_health(), body.total_blood]
	$PanelContainer/Label.text += "Alive: %s, consious: %s" % [body.is_alive, body.is_consious]
	$PanelContainer/Label.text += str(stats_handler.stats)
	$PanelContainer/Label.text += "\n%s\n" % $RoutineController.current_routine
	$PanelContainer/Label.visible = true
	$PanelContainer.visible = true

func _mouse_exit() -> void:
	$PanelContainer/Label.visible = false
	$PanelContainer.visible = false
	
func _ready():
	print(routine_handler.current_routine)
	self.area_entered.connect(pair_offset)
	self.area_exited.connect(pair_offset_restore)
	# I really need to rewrite this part
	age = randi_range(60, 85) * TimeProcesser.year_to_ticks
	print("_ready called, race_name is already set")
	get_parent().npc_process_time.connect(_on_time_process)
	sprite_handler()
	stats_handler.modify_stats(race.get_race_buffs())
	body.apply_buffs_and_reset(stats_handler.get_stat_int("CON"))
	setup_hbar()
	print("%s %s %s, %d, level %d, spare points %d" % [race.race_name, sex, npc_name, age/TimeProcesser.year_to_ticks, stats_handler.level, stats_handler.spare_points])
	print("Current race buffs: ", race.get_race_buffs())
	print("Current stats: ", stats_handler.get_stats_dict())
	print("%d/%d" % [body.get_max_health(), body.get_current_health()])
	update_hbar()
	print("\n")

func handle_death():
	NPC_DEATH.emit(npc_uid)
	print("%s has died, starting to rot" % npc_name)
	$hbar.queue_free()
	$bloodbar.queue_free()

func setup_hbar():
	$hbar.max_value = body.get_max_health()
	$bloodbar.max_value = body.total_blood
	$bloodbar.add_theme_color_override("font_outline_color", Color(1, 0, 0))
	
func update_hbar():
	$hbar.value = body.get_current_health()
	$bloodbar.value = body.total_blood
	
func ping():
	if body.is_consious: return "Pong"
	else: return "silence"
	
func sprite_handler():
	# TODO: art-related
	# move to separate module
	# draw better sprites x(
	var sprite_name: String = race_name + sex
	$Sprite2D.texture = load("res://Sprites/NPC/%s/%s.png" % [race_name, sprite_name])
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
	for tick in ticks_to_process:
		routine_handler.process_routine()
		if roll_for_death(): break

# Split this into body processing and sudden death trigger
func roll_for_death():
	if body.is_alive:
		var human_age = age/TimeProcesser.year_to_ticks
		if human_age > 80:
			if DnD.roll(100) >= 70 + (110 - human_age):
				print("%s died from old age." % npc_name)
				body.kill()
		# Change body logic to tick, to it triggers internal funcs like bleed, heal
		body.bleed()
		update_hbar()
	else:
		if not state_corpse:
			state_corpse = true
			handle_death()
	if state_corpse:
		return !rot()
		
func rot():
	corpse_decaying_timer += 5
	print("%s rotting, %d / %d" % [npc_name, corpse_decaying_timer, corpse_decay_time])
	if corpse_decaying_timer >= corpse_decay_time:
		print("%s finished rotting, clearing" % npc_name)
		NPC_DESTROY.emit(npc_uid)
		queue_free()
		return false
	return true

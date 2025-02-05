extends Node2D
class_name SceneHandler
var SCENE_NPCS: Dictionary
var inactive_time: int = 0
var inactive: bool = true

@export var npc_spawn_number: int = 1
@export var scene_name: String = "Scene_name_placeholder"
@export var player_spawnpoint: Vector2i = Vector2i(17,7)
## In TileMap coordinates
@export var spawnpoints: Array[Vector2i]
signal npc_process_time(int)
func _init() -> void: print("Scene initialized")
# TODO: long, make houses as sub scenes for town, handle entering-leaving
func _ready() -> void:
	TimeProcesser.process_time.connect(process_global_time)
	print("%s::%s" % [_ready, name])
	
func spawn_player(player_object: Node = null, preferred_spawnpoint: Vector2i = Vector2i()) -> void:
	print("%s::%s::%s" % [spawn_player, player_object, scene_name])
	if player_object == null: player_object = preload("res://Scenes/player.tscn").instantiate()
	add_child(player_object)
	# get player spawnpoint from export variable from button
	if preferred_spawnpoint.length():
		player_object.position = player_object.local_to_global_pos(preferred_spawnpoint)
	else:
		player_object.position = player_object.local_to_global_pos(player_spawnpoint)

func unload_player() -> Node2D:
	print("%s::%s" % [unload_player, scene_name])
	var player_node: Node = get_node("player")
	remove_child(player_node)
	return player_node
	
# TODO: for future: add region inactive time, do not accumulate time for towns in inactive region,
# accumulate time for region, send time to towns on player entering reg instead, include
# last-time-visited for towns
# UPD: on region enter switch time processing for region towns to active
func process_global_time(global_time_tick: int = 0) -> void:
	if inactive:
		inactive_time += global_time_tick
		print("%s: Inactive time accumulated: %d" % [name, inactive_time])
	else:
		if inactive_time > 0:
			print("%s scene processing accumulated time of %d" % [name, inactive_time])
			process_active_time(inactive_time)
			inactive_time = 0
			return
		process_active_time(global_time_tick)

func process_active_time(time_to_process: int) -> void:
	print("%s is processing time: %d" % [name, time_to_process])
	npc_process_time.emit(time_to_process)

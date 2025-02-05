extends Character
class_name Player

# TODO: systems:
# Inventory (for both PC and NPC)
# UPD1: Items (only basic): do it via Resources, check link
# https://www.youtube.com/watch?v=nR0nCFJ8-qM
# 	Armor upd: handle with Resource class, damage process is still to come up with
# Weapons with different damage type (blunt, cut and pierce for now)
#	-||- with armor and items, Resource -> class name handling?
# UPD2: Armor\weapon damage solution: armor\weapon class
var interactable_areas: Dictionary
var in_combat: bool = false
var inputs = {
	"move_right": Vector2.RIGHT,
	"move_left": Vector2.LEFT,
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN
	}
# check for community inventory solutions
#	prolly separate scene added to player, maybe another resource?, global script sounds meh?
# A ton of Resource's for every item in game \ dynamic generation?
var inventory: Dictionary
func _ready():
	self.area_entered.connect(enter_area)
	self.area_exited.connect(leave_area)
	fix_position()
	print("\n")
	# Looks horrible, need an item spawner asap. Works though.
	inventory[load("res://Resources/BasicItem.tres")] = 1
	for item in inventory.keys(): item.DEBUG()

func enter_area(received_area: Area2D) -> void:
	# It gets 1 tile proximity areas to. (works only for nps)
	# Looks like a bug, probably due to tilesize of npcs.
	# I gonna utilize it for proximity interaction lmao. Prolly bad idea though.
	# I can fix it and later utilize it as "eyesight" with CollisionShape2d 1.5 times bigger than character xd
	print("Entering area %s" % received_area)
	interactable_areas[received_area.name] = received_area
	print("Total objects to interact: %s" % interactable_areas)
	if received_area is TransitionArea: print("Can move to %s" % received_area.scene_switch_to)

func leave_area(received_area: Area2D) -> void:
	if interactable_areas.has(received_area.name):
		interactable_areas.erase(received_area.name)
		print("Leaving area %s" % received_area)
		print("Total objects to interact: %s" % interactable_areas)
	else: print("WARN::Leaving non-registered area\n")
	
func _unhandled_input(event):
	# this catches mouse too, need to handle
	# ignores mouse -> ignores mouse+keyboard
	# print("In-combat:%s" % in_combat, event)
	if !in_combat:
		if event.is_action_pressed("ui_accept"): TimeProcesser.time_process()
		# var target = $RayCast2D.get_collider()
		# Think about on-enter-scene-switch approach
		# Prolly interactable objects with scene_to String
		#if target is TileMapLayer:
			#var tile_data: TileData = target.get_cell_tile_data(target.global_position)
			#print(tile_data.get_custom_data("scene_move_to"))
	for dir in inputs.keys():
		# Do not touch for now, solved key ghosting after fight
		if in_combat:
			if event.is_action(dir):
				# print("Got movement from is_action: %s" % dir)
				#stop_combat()
				move(dir)
		else:
			if event.is_action_pressed(dir):
				# print("Got movement %s" % dir)
				move(dir)

func collision_handler(direction):
	var raycast_x = tile_size * inputs[direction][0]
	var raycast_y = tile_size * inputs[direction][1]
	$RayCast2D.target_position = Vector2(raycast_x, raycast_y)
	$RayCast2D.force_raycast_update()
	#var target: Node = $RayCast2D.get_collider()
	#if target is Character:
		#return true
	return !$RayCast2D.is_colliding()
		
func move(dir):
	if collision_handler(dir):
		TimeProcesser.time_process(5)
		position += inputs[dir] * tile_size
		
# Split positioning into global, universal script
# check for BasicNPC, NPCSpawner
func fix_position() -> void:
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2
# Handle spawning player from SceneHandler without this function, depricated
func local_to_global_pos(local_points: Vector2i) -> Vector2i:
	return Vector2i((local_points.x*32 + 16), (local_points.y*32 + 16))

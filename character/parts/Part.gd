extends Node2D
class_name Part

var character: RobotCharacter

# == charge
var charge: int = charge_capacity
var charge_capacity: int = 100
signal charge_changed(new_charge: int)

@export var equippable_to: Array[Slot]
var can_do_actions : bool = true

@export var hold_time_curve: Curve
var held_time_ticks :int  = 0

enum Slot { LEFT_ARM, RIGHT_ARM, LEGS, }

func handle_actions(input_name: String) -> void:
	var t1 :float = int(hold_time_curve.sample(0.0)) if hold_time_curve else 0.0
	var t2 :float = int(hold_time_curve.sample(0.33)) if hold_time_curve else 10.0
	var t3 :float = int(hold_time_curve.sample(0.66)) if hold_time_curve else 35.0
	var t4 :float = int(hold_time_curve.sample(1.0)) if hold_time_curve else 60.0
	
	if Input.is_action_pressed(input_name):
		held_time_ticks += 1
	elif Input.is_action_just_released(input_name):
		if t1 <= held_time_ticks and held_time_ticks < t2:
			action_light()
		elif t2 <= held_time_ticks and held_time_ticks < t3:
			action_medium()
		elif t4 <= held_time_ticks:
			action_heavy()
		held_time_ticks = 0

func action_light() -> void:
	return

func action_medium() -> void:
	return

func action_heavy() -> void:
	return
	
func attach() -> bool:
	return false

func detach() -> bool:
	return false

func accept_charge_if_possible (additional_charge: int) -> int:
	# return accepted charge as int
	var accepted_charge : int = 0;
	if charge == charge_capacity: return accepted_charge
	
	if additional_charge + charge > charge_capacity:
		accepted_charge = charge_capacity - charge
		charge = charge_capacity
	
	return accepted_charge

func use_charge_if_possible (cost: int) -> bool:
	if cost > charge: return false
	else:
		charge -= cost
		charge_changed.emit(charge)
		return true
	
func create_splatter(spread: float, amount: int, direction: Vector2, origin: Vector2, raycast_range: float = 15.0, ) -> void:
	# print("ATTEMPING TO SPLATTER!")
	var increment = spread / amount
	for i in range(amount):
		# its actually 2x spread raycasts sorry
		var dir1 = direction.rotated(increment * (i + 1))
		var dir2 = direction.rotated(-1 * increment * (i + 1))
		
		splatter_raycast(dir1, origin, raycast_range)
		splatter_raycast(dir2, origin, raycast_range)
	splatter_raycast(direction, origin, raycast_range)
	return
	

func splatter_raycast(direction: Vector2, origin: Vector2, raycast_range: float = 15.0) -> bool:
	var normalized_dir : Vector2 = direction
	if !direction.is_normalized(): normalized_dir = direction.normalized()
	
	var result = fire_physics_raycast(normalized_dir, origin, raycast_range)
	if result.is_empty(): return false
	
	var collider = result.get("collider")
	# print("hit something: %s at %s" % [collider.name, result.get("position")])
	if !(collider is TileMapLayer): return false
	
	var body_rid = result.get("rid")
	if body_rid == null: return false
	
	if collider.has_method("get_coords_for_body_rid"): 
		# this is godot's instanceof
		var tile_coords = collider.get_coords_for_body_rid(body_rid)
		var atlas_coords = collider.get_cell_atlas_coords(tile_coords)
		
		# FIX THIS IMPLEMENTATION LATER MAYBE
		character.splatter_layer.set_cell(tile_coords, 0, atlas_coords)
		return true
		
	return false
	
func fire_raycast_to_aim_dir(raycast_range: float) -> Dictionary:
	if character == null: 
		# print("Error: 'character' null in %s, needed in method 'fire_raycast_to_aim_dir()'" % self.name)
		return {}
	
	return fire_physics_raycast(character.get_aim_direction(), character.global_position, raycast_range)
	
func impulse_raycast(direction: Vector2, origin: Vector2, strength: float, raycast_range: float = 15.0) -> bool:
	var normalized_dir : Vector2 = direction
	if !direction.is_normalized(): normalized_dir = direction.normalized()
	
	var result = fire_physics_raycast(normalized_dir, origin, raycast_range)

	if result.is_empty(): return false
	
	var collider = result.get("collider")
	if collider == null: return false
	if collider is RigidBody2D:
		collider.apply_impulse(normalized_dir * strength)
		return true;
	
	return false	
			

func fire_physics_raycast(direction: Vector2, origin: Vector2, length: float, layer:int=0xFFFFFFFF) -> Dictionary:
	var normalized_dir : Vector2 = direction
	if !direction.is_normalized(): normalized_dir = direction.normalized()
	
	var space_state = get_world_2d().direct_space_state
	var raycast_from := origin
	var raycast_to := origin + (normalized_dir * length)
	var query = PhysicsRayQueryParameters2D.create(raycast_from, raycast_to, layer)
	
	#print("in 'fire_physics_raycast', shot raycast from %s to %s, angle_deg: %s" % [
	#	raycast_from, 
	#	raycast_to, 
	#	rad_to_deg((raycast_to-raycast_from).angle())
	#	])
	
	return space_state.intersect_ray(query)
	
func save_state() -> Dictionary:
	return {}

func load_state(_state: Dictionary) -> void:
	return
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	queue_redraw()

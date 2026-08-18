extends Node2D
class_name Part

var character: RobotCharacter
var charge: int = charge_capacity
var charge_capacity: int = 100

@export var equippable_to: Array[Slot]

signal charge_changed(new_charge : int)
signal attached
signal detached


enum Slot {
	LEFT_ARM,
	RIGHT_ARM,
	LEGS,
}

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

func use_charge_if_possible (cost: int) -> bool:
	if cost > charge: return false
	else:
		charge -= cost
		charge_changed.emit(charge)
		return true
	
func create_splatter(spread: float, amount: int, direction: Vector2, origin: Vector2, range: float = 15.0, ) -> void:
	for i in range(amount):
		# its actually 2x spread raycasts sorry
		var dir1 = direction.from_angle(direction.angle() + spread / i)
		var dir2 = direction.from_angle(direction.angle() - spread / i)
		
		splatter_raycast(dir1, origin, range)
		splatter_raycast(dir2, origin, range)
	splatter_raycast(direction, origin, range)
	return
	

func splatter_raycast(direction: Vector2, origin: Vector2, range: float = 15.0) -> bool:
	var result = fire_physics_raycast(direction, origin, range)
	if result.is_empty(): return false
	
	var collider = result.get("collider")
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
	
func fire_raycast_to_aim_dir(length: int) -> Dictionary:
	if character == null: 
		# print("Error: 'character' null in %s, needed in method 'fire_raycast_to_aim_dir()'" % self.name)
		return {}
	
	return fire_physics_raycast(character.get_aim_direction(), character.global_position, length)
	
func impulse_raycast(direction: Vector2, origin: Vector2, strength: float, range: float = 15.0) -> bool:
	var result = fire_raycast_to_aim_dir(100)

	if result.is_empty(): return false
	
	var collider = result.get("collider")
	if collider == null: return false
	if collider is RigidBody2D:
		collider.apply_impulse(direction * strength)
		return true;
	
	return false	
			

func fire_physics_raycast(direction: Vector2, origin: Vector2, length: int) -> Dictionary:
	var space_state = get_world_2d().direct_space_state
	var raycast_from := origin
	var raycast_to := direction.normalized() * length
	raycast_to *= length
	var query = PhysicsRayQueryParameters2D.create(raycast_from, raycast_to)
	
	# print("in 'fire_physics_raycast', shot raycast from %s to %s, position is %s" % [raycast_from, raycast_to, character.global_position])
	
	return space_state.intersect_ray(query)
	
func save_state() -> Dictionary:
	return {}

func load_state(state: Dictionary) -> void:
	return
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()
	pass

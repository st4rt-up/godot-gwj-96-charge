extends RigidBody2D
class_name Part

var character: RobotCharacter

# == charge
var charge: int = 0
var pickup_charge_cost: int = 10
var charge_capacity: int = 100
@export var initial_charge = 50
var attached_in_slot: Part.Slot

var handle_actions : Callable = handle_actions_default
var action_light : Callable = empty_action
var action_medium : Callable = empty_action
var action_heavy : Callable = empty_action

var on_impact : Callable = on_impact_default
var on_explosion : Callable = on_impact_default

var tick : Callable = tick_default

@export var modifier : PartModifier
@export var equippable_to: Array[Slot]
var can_do_actions : bool = true
var detect_impacts : bool = false

var saved_collision_layer : int = 1
var last_tick_velocity := Vector2.ZERO
var last_tick_angular_vel : float = 0.0
@onready var splatter_layer: TileMapLayer = $dummy_level/SplatterLayer

@export var hold_time_curve: Curve
var input_held_time :int  = 0

enum Slot { NONE, LEFT_ARM, RIGHT_ARM, LEGS, }

func _physics_process(_delta: float) -> void:
	tick.call()
	if character:
		global_rotation = character.get_aim_direction().rotated(PI/2).angle()
	
	var velocity_check : bool = (
		(last_tick_velocity-linear_velocity).length() >= 300 
		and last_tick_velocity.length() > linear_velocity.length()
		)
	var angular_vel_check : bool = abs(last_tick_angular_vel-angular_velocity) >= 25
	
	if ((velocity_check or angular_vel_check)
		and detect_impacts):
		var impact = last_tick_velocity-linear_velocity
		on_impact.call(impact)
	
	last_tick_velocity = linear_velocity
	last_tick_angular_vel = angular_velocity
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if character:
		global_position = character.global_position
		
	
func _ready() -> void:
	charge = initial_charge
	
	contact_monitor = true
	max_contacts_reported = 1
	
	if modifier:
		modifier.attach_to_part(self)
		modifier.setup(attached_in_slot)
	
func setup () -> void:
	tick = tick_default
	
func on_impact_default(...args: Array) -> void:
	queue_free()

func handle_actions_default(input_name: String) -> void:
	if !can_do_actions: return 
	var t1 :float = get_light_hold_ticks()
	var t2 :float = get_medium_hold_ticks()
	var t3 :float = get_heavy_hold_ticks()
	
	if Input.is_action_pressed(input_name):
		input_held_time += 1
	elif Input.is_action_just_released(input_name):
		if t1 <= input_held_time and input_held_time < t2:
			action_light.call() if action_light != null else empty_action()
		elif t2 <= input_held_time and input_held_time < t3:
			action_medium.call() if action_medium != null else empty_action()
		elif t3 <= input_held_time:
			action_heavy.call() if action_heavy != null else empty_action()
		input_held_time = 0

func get_light_hold_ticks() -> int:
	return int(hold_time_curve.sample(0.0)) if hold_time_curve else 0

func get_medium_hold_ticks() -> int:
	return int(hold_time_curve.sample(0.33)) if hold_time_curve else 10

func get_heavy_hold_ticks() -> int:
	return int(hold_time_curve.sample(0.66)) if hold_time_curve else 35

func empty_action() -> void:
	return

func action_light_default() -> void: return
func action_medium_default() -> void: return
func action_heavy_default() -> void: return

func tick_default() -> void:
	if character:
		global_position = character.global_position
	return
	
func attach_to_character(char: RobotCharacter, slot: Part.Slot) -> bool:
	if char == null: return false
	
	character = char
	attached_in_slot = slot
	
	splatter_layer = character.splatter_layer
	
	saved_collision_layer = collision_layer
	collision_layer = 0
	
	freeze = true
	
	setup()
	return true

func detach_from_character() -> bool:
	if character == null: return false
	attached_in_slot = Part.Slot.NONE
	character = null
	freeze = false
	collision_layer = saved_collision_layer
	return true

func accept_charge_if_possible (additional_charge: int) -> int:
	# return accepted charge as int
	var accepted_charge : int = 0;
	if charge >= charge_capacity: return accepted_charge

	if additional_charge + charge > charge_capacity:
		accepted_charge = charge_capacity - charge
		charge = charge_capacity
	else:
		accepted_charge = additional_charge
		charge += additional_charge

	EventBus.part_charge_changed.emit(charge, self)
	return accepted_charge

func use_charge_if_possible (cost: int) -> bool:
	if cost > charge: return false
	else:
		charge -= cost
		EventBus.part_charge_changed.emit(charge, self)
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
	
	var result = fire_physics_raycast(normalized_dir, origin, raycast_range, 2)
	if result.is_empty(): return false
	
	var collider = result.get("collider")
	# print("hit something: %s at %s" % [collider.name, result.get("position")])
	if !(collider is TileMapLayer): return false
	
	var body_rid = result.get("rid")
	if body_rid == null: return false
	
	if collider.has_method("get_coords_for_body_rid"): 
		if !(collider is TileMapLayer): return false 
		# this is godot's instanceof
		var tile_coords = collider.get_coords_for_body_rid(body_rid)
		var atlas_coords = collider.get_cell_atlas_coords(tile_coords)
		
		# FIX THIS IMPLEMENTATION LATER MAYBE
		if splatter_layer:
			splatter_layer.set_cell(tile_coords, 0, atlas_coords)
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
	
	return space_state.intersect_ray(query)
	
func attach_modifier(mod: PartModifier) -> bool:
	if mod != null: return false
	
	return modifier.attach_to_part(self)
	
func rocket_punch() -> void:
	var angle : float = 0.0
	if character: 
		angle = character.get_aim_direction().rotated(PI/2).angle()
		
	if !character.detach_part_if_possible(attached_in_slot): return
	
	# fix colliding before travel starts
	freeze = true
	rotation = angle
	position += Vector2.UP.rotated(rotation) * 5
	freeze = false
	
	gravity_scale = 0.2
	lock_rotation = true
	apply_impulse(Vector2.from_angle(rotation-(PI/2)) * 200.0)
	self.tick = (func() -> void: 
		if !detect_impacts: detect_impacts = true
		
		apply_force(Vector2.from_angle(rotation-(PI/2)) * 2500.0)
		
		var cost_per_tick := 2
		if !use_charge_if_possible(cost_per_tick) or charge < cost_per_tick:
			# set_constant_force(Vector2.ZERO)
			gravity_scale = 1.0
			lock_rotation = false
			self.tick = tick_default
			return
			
	)
	
func save_state() -> Dictionary:
	return {}

func load_state(_state: Dictionary) -> void:
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	queue_redraw()

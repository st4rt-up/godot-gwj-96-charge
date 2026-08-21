extends CharacterBody2D
class_name RobotCharacter

# == statss
const ACCEL := 20.0
const MAX_SPEED := 200
const SPEED = 150
const JUMP_VELOCITY = 400.0 # negative is up

# == placeholder

@export var tile_layer: TileMapLayer
@export var splatter_layer: TileMapLayer
var DEBUG : bool = true;

# == graphics
@onready var character_graphics: Node2D = $graphics

# == hitboxes
@onready var pickup_box: Area2D = $pickup_box
@onready var splatter_detector: Area2D = $splatter_collision_box

# == charge
var charge: int = 100
var charge_capacity: int = 100

# attach mode: physics ticks per 1 charge sent to the held part
const CHARGE_TICK_INTERVAL := 20
var charge_ticks: int = 0

# == parts
var left_arm: Part
var right_arm: Part
var legs: Part

var nearby_parts: Array[Part] = []

# placeholder input code
var held_space_ticks: int = 0

func _ready():
	pickup_box.connect("body_entered", _on_pickup_box_area_entered)
	pickup_box.connect("body_exited", _on_pickup_box_area_exited)
	EventBus.emit_signal("body_charge_changed", charge)

func _physics_process(delta: float) -> void:
	handle_rolling_movement(delta)
	placeholder_graphics()
	
	if Input.is_action_just_pressed("attach"):
		EventBus.emit_signal("body_attaching_state_changed", Input.is_action_pressed("attach"))
	if Input.is_action_just_released("attach"):
		EventBus.emit_signal("body_attaching_state_changed", Input.is_action_pressed("attach"))

	if Input.is_action_pressed("attach"):
		handle_charge_part()
		handle_attach()
	else:
		charge_ticks = 0
		placeholder_jump()
		handle_part_actions()


func _draw() -> void:
	if DEBUG:
		draw_debug_input_display()

func _process(_float) -> void:
	queue_redraw()

# == general helper functions
func get_movement_direction() -> Vector2:
	var dir: Vector2  = Vector2.ZERO;
	dir.x = Input.get_axis("left", "right")
	dir.y = Input.get_axis("up", "down")
	return dir.normalized()

func get_aim_direction() -> Vector2:
	var char_to_mouse: Vector2 = get_global_mouse_position()-global_position
	return char_to_mouse.normalized();

func get_aim_angle() -> float:
	return get_angle_to(get_global_mouse_position())

func fire_raycast_to_aim_dir(length: int) -> Dictionary:
	
	var space_state = get_world_2d().direct_space_state
	var raycast_from := position
	var raycast_to := get_aim_direction() * length

	var query = PhysicsRayQueryParameters2D.create(raycast_from, raycast_to)
	return space_state.intersect_ray(query)

# == movement code
func handle_rolling_movement(delta: float) -> void:
	var direction := get_movement_direction()
	var accel_vec : Vector2 = Vector2.ZERO
	var apply_gravity : bool = true

	var is_in_goo := false
	if splatter_detector:
		is_in_goo = splatter_detector.has_overlapping_bodies()

	# helper bool
	# var holding_same_direction: bool = velocity.x * direction.x >= 0
	var holding_oppos_direction: bool = velocity.x * direction.x < 0

	if is_on_floor():

		# movement keys
		if abs(velocity.x + accel_vec.x) < MAX_SPEED:
			accel_vec.x += direction.x * ACCEL

		if holding_oppos_direction:
			accel_vec.x += direction.x * ACCEL

		if is_in_goo:
			accel_vec.x -= velocity.x * 0.2
			if velocity.y >= 0:
				velocity.y = 0
		# ground friction
		accel_vec.x -= velocity.x * 0.15

	else:
		# movement keys
		if abs(velocity.x + accel_vec.x) < MAX_SPEED * 1.2:
			if holding_oppos_direction:
				accel_vec.x += direction.x * ACCEL * 0.35

			accel_vec.x += direction.x * ACCEL * 0.35

		# air friction
		accel_vec.x -= velocity.x * 0.05
		# air friction
		accel_vec.y -= velocity.y * 0.0001

	if is_in_goo and is_on_wall():
		# roll up walls
		apply_gravity = false
		accel_vec.y += direction.y * ACCEL * 0.4;

		# sticky
		accel_vec.y -= velocity.y * 0.05

		# goo slide down
		accel_vec.y += get_gravity().y * 0.2 * delta

		var wall_direction: int = int(sign(get_wall_normal().dot(Vector2.LEFT)))
		accel_vec.x += wall_direction * ACCEL * 0.1

		if wall_direction * direction.x > 0 && velocity.y > 0:
			accel_vec.y -= velocity.y * 0.10

	if apply_gravity:
		accel_vec.y += get_gravity().y * delta

	velocity += accel_vec
	move_and_slide()

	# move_and_collide(accel_vec)

# == placeholder
func placeholder_graphics() -> void:
	# graphics placeholder
	if is_on_floor():
		# PLACEHOLDER
		character_graphics.rotation += velocity.x * 0.1 / (2 * 3.1415 * 10.0)
		#character_graphics.scale = Vector2.ONE
		#character_graphics.skew = 0
	else:
		character_graphics.rotation += velocity.x * 0.01 / (2 * 3.1415 * 10.0)

	if is_on_wall():
		var wall_right_side := int(sign(get_wall_normal().dot(Vector2.RIGHT)))
		character_graphics.rotation += wall_right_side * velocity.y * 0.1 / (2 * 3.1415 * 10.0)
		
func placeholder_jump() -> void:
	if Input.is_action_pressed("action_4"):
			held_space_ticks += 1
	elif Input.is_action_just_released("action_4"):
		if (held_space_ticks > 40 
			&& (is_on_floor() or is_on_wall_only())
			&& use_charge_if_possible(5)
			):
			velocity += get_aim_direction() * JUMP_VELOCITY 
		held_space_ticks = 0
	else:
		held_space_ticks = 0

# == part related code
func handle_part_actions() -> void:
	if left_arm: left_arm.handle_actions.call("action_1")
	if right_arm: right_arm.handle_actions.call("action_2")
	if legs:  legs.handle_actions.call("action_3")
	
func get_part_in_slot(slot: Part.Slot) -> Part:
	match slot:
		Part.Slot.LEFT_ARM: return left_arm
		Part.Slot.RIGHT_ARM: return right_arm
		Part.Slot.LEGS: return legs
	return null

func get_slot_from_input(input_check: Callable = Input.is_action_just_pressed) -> Part.Slot:
	if input_check.call("action_1"): return Part.Slot.LEFT_ARM
	if input_check.call("action_2"): return Part.Slot.RIGHT_ARM
	if input_check.call("action_3"): return Part.Slot.LEGS
	return Part.Slot.NONE

func handle_attach() -> void:
	var slot : int = get_slot_from_input()
	if slot != Part.Slot.NONE:
		var candidate_parts = scan_for_nearby_parts(slot)

		var nearest_part : Part = candidate_parts[0] if !candidate_parts.is_empty() else null
		if attach_part_if_possible(nearest_part, slot):
			charge_ticks = nearest_part.get_heavy_hold_ticks()
			print("DEBUG: attached %s to slot %s" % [nearest_part.name, slot])
		return
	
	# detach waits for released
	var released : Part.Slot = get_slot_from_input(Input.is_action_just_released)
	if released == Part.Slot.NONE: return

	var part : Part = get_part_in_slot(released)
	if part == null or charge_ticks >= part.get_heavy_hold_ticks(): return

	# placeholder, implement "detaching/di" mode
	detach_part_if_possible(released)	# detach if tap
	
	
	var random_fly_direction := (Vector2.UP * (125 * randf() + 50) 
		+ Vector2.RIGHT * (100 * randf() - 50)
		+ get_aim_direction() * 200
		+ velocity)
	
	var random_rotational_force = randf() * 200 - 100
	
	var aiming_down_percent = max(0.0, get_aim_direction().dot(Vector2.DOWN))
	if aiming_down_percent > 0.0:
		print(1.0 - aiming_down_percent)
		random_fly_direction *= 1.0 - aiming_down_percent
		random_rotational_force *= max(0.0, 1.5 - aiming_down_percent)
		
	part.apply_torque_impulse(random_rotational_force)
	part.apply_impulse(random_fly_direction)

func attach_part_if_possible(part: Part, slot: Part.Slot) -> bool:
	if part == null: return false	
	
	# already part in slot
	if get_part_in_slot(slot) != null: return false
	
	match slot:
		Part.Slot.LEFT_ARM: left_arm = part
		Part.Slot.RIGHT_ARM: right_arm = part
		Part.Slot.LEGS: legs = part
		Part.Slot.NONE: return false
	
	part.attach_to_character(self, slot)
	
	if part.charge == 0:
		send_charge_if_possible(part.pickup_charge_cost, part)
	nearby_parts.erase(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	EventBus.emit_signal("body_attached_part", part, slot)
	return true

func detach_part_if_possible(slot: Part.Slot) -> bool:
	var part: Part = null
	
	part = get_part_in_slot(slot)
	if part == null: return false
	
	match slot:
		Part.Slot.LEFT_ARM: left_arm = null
		Part.Slot.RIGHT_ARM: right_arm = null
		Part.Slot.LEGS: legs = null
	
	# drop the part at the current position
	part.detach_from_character()
	
	nearby_parts.append(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	EventBus.emit_signal("body_detached_part", slot)
	return true
	
# all cached parts that fit `slot`, nearest first
func scan_for_nearby_parts(slot: Part.Slot) -> Array[Part]:
	var result: Array[Part] = []

	for part in nearby_parts:
		if !is_instance_valid(part): continue
		if !(part is Part): continue
		if (left_arm != null) and left_arm == part: continue
		if (right_arm != null) and right_arm == part: continue
		if (legs != null) and legs == part: continue
		
		if part.equippable_to.has(slot):
			result.append(part)

	var origin := global_position
	result.sort_custom(func(a: Part, b: Part) -> bool:
		return a.global_position.distance_squared_to(origin) \
			< b.global_position.distance_squared_to(origin))

	return result
	
func handle_charge_part() -> void:
	# a fresh press starts a new hold; the count is left alone on release
	# so handle_attach can still read how long the button was down
	if get_slot_from_input() != Part.Slot.NONE: charge_ticks = 0

	var slot : int = get_slot_from_input(Input.is_action_pressed)
	var part : Part = get_part_in_slot(slot) if slot != Part.Slot.NONE else null
	if part == null: return

	charge_ticks += 1
	if charge_ticks < part.get_heavy_hold_ticks(): return
	if charge_ticks % CHARGE_TICK_INTERVAL != 0: return

	send_charge_if_possible(1, part)

# == charge related code
func set_charge(new_charge: int) -> void:
	
	if charge > charge_capacity: return
	if new_charge > charge_capacity:
		charge = charge_capacity
	else:
		charge = new_charge
	
	EventBus.emit_signal("body_charge_changed", charge)

func send_charge_if_possible(amt : int, part: Part) -> bool:
	if part.charge >= part.charge_capacity: return false
	if DEBUG: print("DEBUG: sending %s charge to %s. current capcity %s " % [amt, part.name, charge])
	if amt > charge: return false
	
	var accepted_charge := part.accept_charge_if_possible(amt)
	if accepted_charge == 0: return false
	
	use_charge_if_possible(accepted_charge)
	return true

func use_charge_if_possible(cost: int) -> bool:
	if cost > charge: return false
	else:
		charge -= cost
		EventBus.emit_signal("body_charge_changed", charge)
		return true

func draw_debug_input_display() -> void:
	# === aim direction display
		var aim_direction := get_aim_direction()
		var line_length := 30
		draw_line(Vector2.ZERO, aim_direction * line_length, Color.GREEN, 1.0)

		# === input display
		var colorDefault = Color.WHITE
		var colorPressedLight = Color.LIGHT_SLATE_GRAY
		var colorPressedMid = Color.YELLOW
		var colorPressed = Color.RED

		draw_rect(Rect2(-24.0, -26.0, 5.0, 5.0), colorPressed if Input.is_action_pressed("up") else colorDefault) # W
		draw_rect(Rect2(-30.0, -20.0, 5.0, 5.0), colorPressed if Input.is_action_pressed("left") else colorDefault	) # A
		draw_rect(Rect2(-24.0, -20.0, 5.0, 5.0), colorPressed if Input.is_action_pressed("down") else colorDefault) # S
		draw_rect(Rect2(-18.0, -20.0, 5.0, 5.0), colorPressed if Input.is_action_pressed("right") else colorDefault) # D

		draw_rect(Rect2(-26.5, -14.0, 10.0, 5.0), colorPressed if Input.is_action_pressed("action_4") else colorDefault) # Space

		draw_circle(Vector2(18.0, -20.0), 2.5, colorPressed if Input.is_action_pressed("action_1") else colorDefault) #LMB
		draw_circle(Vector2(30.0, -20.0), 2.5, colorPressed if Input.is_action_pressed("action_2") else colorDefault) #RMB
		draw_circle(Vector2(24.0, -18.0), 2.5, colorPressed if Input.is_action_pressed("action_3") else colorDefault) #SHIFT


		var colorHeld1;
		if (held_space_ticks < 20):
			colorHeld1 = Color.WHITE
		elif (held_space_ticks < 40):
			colorHeld1 = Color.YELLOW
		else:
			colorHeld1 = Color.RED
		draw_rect(Rect2(-35.0, 0.0, 5.0, max(-10, -(held_space_ticks/4.0))), colorHeld1)

# == signals
func _on_pickup_box_area_entered(body) -> void:
	# var part := area.get_parent() as Part
	if !(body is Part): return
	var part = body as Part
	if body == null: return
	
	if nearby_parts.has(part): return
	if left_arm == part && left_arm != null: return
	if right_arm == part && right_arm != null: return
	if legs == part && legs != null: return
	
	nearby_parts.append(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	if DEBUG: print("part in range: %s" % part.name)

func _on_pickup_box_area_exited(body) -> void:
	# var part := area.get_parent() as Part
	if !(body is Part): return
	var part = body as Part
	if part == null: return

	nearby_parts.erase(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	if DEBUG: print("part out of range: %s" % part.name)

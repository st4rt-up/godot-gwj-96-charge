extends CharacterBody2D
class_name RobotCharacter

const ACCEL := 20.0
const MAX_SPEED := 200
const SPEED = 150
const JUMP_VELOCITY = 400.0 # negative is up


@export var character_graphics: Node2D

@export var tile_layer: TileMapLayer
@export var splatter_layer: TileMapLayer

@onready var pickup_box: Area2D = $pickup_box
@onready var splatter_detector: Area2D = $splatter_collision_box

var DEBUG : bool = true;

var charge: int = 100
var charge_capacity: int = 100

var left_arm: Part
var right_arm: Part
var legs: Part

var nearby_parts: Array[Part] = []

# placeholder input code
var held_space_ticks: int = 0

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

func placeholder_graphics() -> void:
	# graphics placeholder
	if is_on_floor():
		# PLACEHOLDER
		character_graphics.sprite.rotation += velocity.x * 0.1 / (2 * 3.1415 * 10.0)
		#character_graphics.scale = Vector2.ONE
		#character_graphics.skew = 0
	else:
		character_graphics.sprite.rotation += velocity.x * 0.01 / (2 * 3.1415 * 10.0)

	if is_on_wall():
		var wall_right_side := int(sign(get_wall_normal().dot(Vector2.RIGHT)))
		character_graphics.rotation += wall_right_side * velocity.y * 0.1 / (2 * 3.1415 * 10.0)

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

func _draw() -> void:
	if DEBUG:
		draw_debug_input_display()

func _process(_float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	handle_rolling_movement(delta)
	placeholder_graphics()
	
	if Input.is_action_just_pressed("attach"):
		EventBus.emit_signal("body_attaching_state_changed", Input.is_action_pressed("attach"))
	if Input.is_action_just_released("attach"):
		EventBus.emit_signal("body_attaching_state_changed", Input.is_action_pressed("attach"))

	if Input.is_action_pressed("attach"):
		handle_attach()
	else:
		placeholder_jump()
		handle_part_actions()
		
func placeholder_jump() -> void:
	if Input.is_action_pressed("action_4"):
			held_space_ticks += 1
	elif Input.is_action_just_released("action_4"):
		if (held_space_ticks > 40 
			&& (is_on_floor() or is_on_wall_only())
			&& use_charge_if_able(5)
			):
			velocity += get_aim_direction() * JUMP_VELOCITY 
		held_space_ticks = 0
	else:
		held_space_ticks = 0
			
func handle_part_actions() -> void:
	if left_arm: left_arm.handle_actions("action_1")
	if right_arm: right_arm.handle_actions("action_2")
	if legs:  legs.handle_actions("action_3")

func handle_attach() -> void:
	var slot : Part.Slot 
	if Input.is_action_just_pressed("action_1"):
		slot = Part.Slot.LEFT_ARM
	elif Input.is_action_just_pressed("action_2"):
		slot = Part.Slot.RIGHT_ARM
	elif Input.is_action_just_pressed("action_3"):
		slot = Part.Slot.LEGS
	else: 
		return
		
	
	var candidate_parts = scan_for_nearby_parts(slot)

	var nearest_part : Part = candidate_parts[0] if !candidate_parts.is_empty() else null
	if attach_part_if_able(nearest_part, slot):
		print("DEBUG: attached %s to slot %s" % [nearest_part.name, slot])
	else:
		detach_part_if_able(slot)

func attach_part_if_able(part: Part, slot: Part.Slot) -> bool:
	if part == null: return false
	
	match slot:
		Part.Slot.LEFT_ARM:
			if left_arm: return false
			left_arm = part
		Part.Slot.RIGHT_ARM:
			if right_arm: return false
			right_arm = part
		Part.Slot.LEGS:
			if legs: return false
			legs = part
			
	part.character = self
	nearby_parts.erase(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	EventBus.emit_signal("body_attached_part", part, slot)
	return true

func detach_part_if_able(slot: Part.Slot) -> bool:
	var part: Part = null
	
	match slot:
		Part.Slot.LEFT_ARM:
			part = left_arm
			left_arm = null
		Part.Slot.RIGHT_ARM:
			part = right_arm
			right_arm = null
		Part.Slot.LEGS:
			part = legs
			legs = null

	if part == null: return false
	
	# drop the part at the current position
	part.global_position = global_position
	part.character = null
	part.detach()
	
	nearby_parts.append(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	EventBus.emit_signal("body_detached_part", slot)
	return true
	
func set_charge(new_charge: int) -> void:
	if charge > charge_capacity: return
	if new_charge > charge_capacity:
		charge = charge_capacity
	else:
		charge = new_charge
	
	EventBus.emit_signal("body_charge_changed", charge)

func use_charge_if_able(cost: int) -> bool:
	if cost > charge: return false
	else:
		charge -= cost
		EventBus.emit_signal("body_charge_changed", charge)
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

func _ready():
	EventBus.emit_signal("body_charge_changed", charge)

func _on_pickup_box_area_entered(area: Area2D) -> void:
	var part := area.get_parent() as Part
	if part == null: return
	if nearby_parts.has(part): return
	if left_arm == part && left_arm != null: return
	if right_arm == part && right_arm != null: return
	if legs == part && legs != null: return
	
	nearby_parts.append(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	if DEBUG: print("part in range: %s" % part.name)

func _on_pickup_box_area_exited(area: Area2D) -> void:
	var part := area.get_parent() as Part
	if part == null: return

	nearby_parts.erase(part)
	EventBus.emit_signal("nearby_parts_updated", nearby_parts)
	if DEBUG: print("part out of range: %s" % part.name)

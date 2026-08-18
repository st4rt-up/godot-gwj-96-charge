extends CharacterBody2D


const ACCEL := 20.0
const MAX_SPEED := 200
const SPEED = 150
const JUMP_VELOCITY = 400.0 # negative is up

# place holder testing 
@export var splatter_aim_cone: Area2D
@export var splatter_detector: Area2D
@export var character_graphics: Node2D
@export var tile_layer: TileMapLayer
@export var splatter_layer: TileMapLayer
var DEBUG : bool = true;

var left_arm

# placeholder input code
var held_action1_ticks: int = 0
var held_space_ticks: int = 0

func get_movement_direction() -> Vector2:
	var dir: Vector2  = Vector2.ZERO;
	dir.x = Input.get_axis("left", "right")
	dir.y = Input.get_axis("up", "down")
	return dir.normalized()

func get_aim_direction() -> Vector2:
	var char_to_mouse: Vector2 = get_global_mouse_position()-position
	return char_to_mouse.normalized();
	
func get_aim_angle() -> float:
	return get_angle_to(get_global_mouse_position())
	
func handle_movement(delta: float) -> void:
	var direction := get_movement_direction()
	var accel_vec : Vector2 = Vector2.ZERO
	var apply_gravity : bool = true
	
	var is_in_goo := false
	if splatter_detector:
		is_in_goo = splatter_detector.has_overlapping_bodies()
		
	elif DEBUG:
		print("ERROR: %s does not have 'splatter_detector' set in editor" % self.name)
	
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
			
	if is_in_goo and is_on_wall():
		# roll up walls
		apply_gravity = false
		accel_vec.y += direction.y * ACCEL * 0.4;
		
		# sticky
		accel_vec.y -= velocity.y * 0.05
		
		# goo slide down	
		accel_vec.y += get_gravity().y * 0.2 * delta
			
	if apply_gravity:
		accel_vec.y += get_gravity().y * delta
	
	velocity += accel_vec
	move_and_slide()
	
	# move_and_collide(accel_vec)

func placeholder_graphics() -> void:
	# graphics placeholder
	if is_on_floor():
		# PLACEHOLDER
		character_graphics.rotation += velocity.x * 0.1 / (2 * 3.1415 * 10.0)
	else:
		character_graphics.rotation += velocity.x * 0.01 / (2 * 3.1415 * 10.0)

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
	
		var colorAction1;
		if (held_action1_ticks == 0):
			colorAction1 = colorDefault
		elif (held_action1_ticks < 20):
			colorAction1 = colorPressedLight
		elif (held_action1_ticks < 40):
			colorAction1 = colorPressedMid
		else:
			colorAction1 = colorPressed
			
		draw_circle(Vector2(18.0, -20.0), 2.5, colorAction1) #LMB
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
	handle_movement(delta)
	placeholder_graphics()

	
	if Input.is_action_pressed("action_4"):
		held_space_ticks += 1
	elif Input.is_action_just_released("action_4"):
		if held_space_ticks > 40:
			velocity += get_aim_direction() * JUMP_VELOCITY
		held_space_ticks = 0
	else:
		held_space_ticks = 0 
		
	if Input.is_action_pressed("action_1"):
		held_action1_ticks += 1
	elif Input.is_action_just_released("action_1"):
		# im gonna factor this out so each part just has a 
		# lightAction() // midAction() // heavyAction()
		# called here
		
		# if held_action1_ticks > 0 && held_action1_ticks < 20:
			
		if held_action1_ticks >= 20 && held_action1_ticks < 40 && splatter_aim_cone:
			splatter_aim_cone.rotation = get_aim_angle()
			splatter_aim_cone.monitoring = true
			splatter_aim_cone.visible = true
			# splatter_layer.update_internals()
		held_action1_ticks = 0
	else:
		held_action1_ticks = 0 
		splatter_aim_cone.monitoring = false
		splatter_aim_cone.visible = false
		

	

func _ready():
	# placeholder
	splatter_aim_cone.body_shape_entered.connect(area_entered)
	
func area_entered(body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int):
	if body.has_method("get_coords_for_body_rid"): 
		# this is godot's instanceof
		var tile_coords = body.get_coords_for_body_rid(body_rid)
		var atlas_coords = body.get_cell_atlas_coords(tile_coords)
		splatter_layer.set_cell(tile_coords, 0, atlas_coords)

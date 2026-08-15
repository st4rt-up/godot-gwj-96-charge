extends CharacterBody2D


const SPEED = 150
const JUMP_VELOCITY = -400.0

@export var splatter_aim_cone: Area2D
@export var splatter_detector: Area2D

@export var tile_layer: TileMapLayer
@export var splatter_layer: TileMapLayer

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
	
func _draw() -> void:
	var DEBUG_DISPLAY := true;
	
	if DEBUG_DISPLAY:
		
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
	
func _process(_float) -> void:
	queue_redraw()
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := get_movement_direction()
		
	if direction.x != 0:
		velocity.x = direction.x * SPEED
	else:
		# friction
		if is_on_floor():
			velocity.x *= 0.4
		else:
			velocity.x *= 0.99
			
	if Input.is_action_pressed("action_4"):
		held_space_ticks += 1
	elif Input.is_action_just_released("action_4"):
		if held_space_ticks > 40:
			velocity += get_aim_direction() * -JUMP_VELOCITY
		held_space_ticks = 0
	else:
		held_space_ticks = 0 
		
	if Input.is_action_pressed("action_1"):
		held_action1_ticks += 1
	elif Input.is_action_just_released("action_1"):
		# im gonna factor this out so each part just has a 
		# lightAction() // midAction() // heavyAction()
		# called here
		
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
		
	if splatter_detector.has_overlapping_bodies():
		if is_on_floor():
			velocity.x *= 0.4
		
		if direction.y != 0 && is_on_wall():
			velocity.y = direction.y * SPEED;
			if is_on_floor() && velocity.y >= 0:
				velocity.y = 0
		elif is_on_wall():
			velocity.y = get_gravity().y * delta * 0.2

	move_and_slide()

func _ready():
	splatter_aim_cone.body_shape_entered.connect(area_entered)
	
func area_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int):
	if body.has_method("get_coords_for_body_rid"): 
		# this is godot's instanceof
		var tileCoords = body.get_coords_for_body_rid(body_rid)
		splatter_layer.set_cell(tileCoords, 0, Vector2(0, 0))

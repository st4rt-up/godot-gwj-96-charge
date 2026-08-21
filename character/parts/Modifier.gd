class_name PartModifier
extends Resource

var part: Part

func _init() -> void:
	return
	
func _ready() -> void:
	if part: 
		setup(part.attached_in_slot)

func on_contact() -> void:
	# brushing against, etc
	return
	
func in_area() -> void:
	return

func on_impact() -> void: return
	
func on_explosion () -> void: return
	
func projectile_in_flight() -> void: return
	
func projectile_connected() -> void:
	return
	
func attach_to_part(new_part : Part) -> bool:
	if new_part == null: return false
	part = new_part
	setup(part.attached_in_slot)
	return true

func detach_from_part() -> void:
	if part == null: return
	part.handle_actions = part.handle_actions_default
	part = null
	
func setup(slot: Part.Slot) -> void:
	return

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
	
	var result = part.fire_physics_raycast(normalized_dir, origin, raycast_range)
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
		# character.splatter_layer.set_cell(tile_coords, 0, atlas_coords)
		return true
		
	return false
	
# magnet
	# magnetize object..?
# bounce
	# strong physics force
	# wave of physics force
	# explosion of
# sticky

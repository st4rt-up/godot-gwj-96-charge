extends PartModifier
class_name StickyModifier

var particles : CPUParticles2D
@export var spread = PI / 8

func _init() -> void:
	super._init()
	
func setup(slot: Part.Slot) -> void:
	part.action_light = test_spend_two_charge
	part.action_medium = action_medium
	part.action_heavy = part.rocket_punch
	
	part.on_impact = on_explosion
	
	particles = CPUParticles2D.new()
	particles.amount = 500
	particles.lifetime = 0.48
	particles.lifetime_randomness = 0.45
	particles.explosiveness = 0.5
	particles.initial_velocity_min = 200
	particles.initial_velocity_max = 800
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 3.5
	particles.spread = rad_to_deg(spread)
	particles.one_shot = true
	particles.color = Color8(0, 204, 0)
	particles.emitting = false
	
	if particles.get_parent():
		particles.get_parent().remove_child(particles)
	part.add_child(particles)

func action_medium() -> void:
	if !part.use_charge_if_possible(20): return
	
	part.add_child(particles)
	if particles:
		particles.global_position = part.character.global_position
		particles.direction = Vector2.UP
		particles.emitting = true
	
	part.create_splatter(spread, 30, part.character.get_aim_direction(), part.character.global_position, 250.0)

func on_explosion (...args: Array) -> void:
	var offset : Vector2 = part.last_tick_velocity.normalized() * -15
	var impact_angle := 0.0
	if !args.is_empty():
		impact_angle = (args[0] as Vector2).rotated(PI).angle()
	
	part.create_splatter((PI), 500, Vector2.ONE, part.global_position+offset, 250.0)
	part.queue_free()
	
	if particles:
		part.remove_child(particles)
		
		particles.global_position = part.global_position
		particles.rotation = 0
		# particles.direction = Vector2.from_angle(impact_angle)
		particles.initial_velocity_min = 200
		particles.initial_velocity_max = 800
		particles.scale_amount_min = 2.5
		particles.scale_amount_max = 3.5
		particles.spread = rad_to_deg(PI)
		
		particles.emitting = true
		
		part.get_parent().add_child(particles)
		await part.get_tree().create_timer(3).timeout
		particles.queue_free() 

	
func test_spend_two_charge() -> void:
	part.use_charge_if_possible(2)

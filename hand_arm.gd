extends Part

@export var particles: CPUParticles2D

func action_light() -> void:
	impulse_raycast(character.get_aim_direction(), character.global_position, 250, 15.0)

func action_medium() -> void:
	# if use_charge_if_possible(30):
	# print("attempted to splatter from hand arm")
	impulse_raycast(character.get_aim_direction(), character.global_position, 500, 30.0)
	var spread = (3.14159 / 4)
	if particles:
		particles.global_position = character.global_position
		particles.initial_velocity_min = 200
		particles.initial_velocity_max = 800
		particles.scale_amount_min = 2.5
		particles.scale_amount_max = 3.5
		particles.spread = rad_to_deg(spread / 2)
		particles.direction = character.get_aim_direction()
		# particles.process_material.direction = Vector3(character.get_aim_direction().x, character.get_aim_direction().y, 0)
		particles.emitting = true
		
	create_splatter(spread, 30, character.get_aim_direction(), character.global_position, 30.0)

func _physics_process(_delta: float) -> void:
	if character:
		position = character.position
	
	
	return

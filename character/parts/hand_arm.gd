extends Part

func action_light_default() -> void:
	impulse_raycast(character.get_aim_direction(), character.global_position, 250, 100.0)

func action_medium_default() -> void:
	# if use_charge_if_possible(30):
	# print("attempted to splatter from hand arm")
	
	if !use_charge_if_possible(10): return
	impulse_raycast(character.get_aim_direction(), character.global_position, 500, 250.0)

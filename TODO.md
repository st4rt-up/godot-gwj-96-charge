# Modifier
enum EffectType

onContact
onImpact
applyEffect

# RobotCharacter
### to implement
charging parts
- in attaching mode, pressing the "attach" button to a filled slot will charge the part in that slot

detaching mode
- in detaching mode, pressing the button for a slot will detach the part and steal some battery from it, with some waste (leaving it on the ground)


## quick restart
#### save/load
- make save_state and load_state functions
save_state() -> Dictionary
load_state(state: Dictionary) -> bool

example:
	save_state()
		var current_state : Dictionary
		current_state["charge"] = self.charge
		
	load_state(state: Dictionary)
		charge = state("charge", charge_capacity)
		

# input remapping
# volume controls

# title screen
# save/load system scene manager

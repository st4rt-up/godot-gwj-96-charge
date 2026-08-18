extends Node2D
class_name PuzzleComponent

var parent: Node

@export_range(0.1, 100.0, 0.1) var speed := 5.0
var progress: float

# var activates: Array[PuzzleComponent]
@export var is_activated_by: Array[PuzzleComponent]

var state := PuzzleObjectState.FullyDeactivated

enum PuzzleObjectState {
	FullyDeactivated,
	Deactivating, 
	Activating,
	FullyActivated,
	ForcedDeactivated,
	ForcedActivated,
}

signal switched_states
signal activated
signal deactivated

func activate() -> void:
	progress = clamp(progress, 0.0, 100.0)
	if state == PuzzleObjectState.ForcedActivated: return
	
	var prev_state = state
	
	if progress < 100.0:
		state = PuzzleObjectState.Activating
	elif progress >= 100.0:
		state = PuzzleObjectState.FullyActivated
		
	if prev_state != state:
		switched_states.emit()
		activated.emit()
		
func deactivate() -> void:
	progress = clamp(progress, 0.0, 100.0)
	if state == PuzzleObjectState.ForcedDeactivated: return
	
	var prev_state = state
	
	if progress > 0.0:
		state = PuzzleObjectState.Deactivating
	elif progress <= 0.0:
		state = PuzzleObjectState.FullyDeactivated
		
	if prev_state != state:
		switched_states.emit()
		deactivated.emit()
		
func force_activate() -> void:
	state = PuzzleObjectState.ForcedActivated
			
func force_deactivate() -> void:
	state = PuzzleObjectState.ForcedDeactivated
	
func is_activated() -> bool:
	return state == PuzzleObjectState.FullyActivated or state == PuzzleObjectState.ForcedActivated
	
func is_deactivated() -> bool:
	return state == PuzzleObjectState.FullyDeactivated

func reset() -> void:
	state = PuzzleObjectState.FullyDeactivated
	progress = 0.0

func _ready() -> void:
	var parent := get_parent()
	if parent == null:
		# components are not supposed to exist by themselves
		self.queue_free()
		return
	
	parent = owner
	self.reset()
	
func check_activators() -> bool:
	if state == PuzzleObjectState.ForcedDeactivated:
		return false
	elif state == PuzzleObjectState.ForcedActivated:
		print("this is running")
		return true
	
	if !is_activated_by.is_empty():
		for activator in is_activated_by:
			if (activator != null 
			&& activator.has_method("is_activated") 
			&& activator.is_activated()):
				return true
				
	
	return false	
			

func _physics_process(_delta: float) -> void:
	if check_activators():
		activate()
	else:
		print("%s" % check_activators())
		deactivate()
	
	match state:
		PuzzleObjectState.Activating:
			if progress + speed >= 100.0: 
				progress = 100.0
				state = PuzzleObjectState.FullyActivated
			else: 
				progress += speed
		PuzzleObjectState.Deactivating:
			if progress - speed <= 0.0:
				progress = 0.0
				state = PuzzleObjectState.FullyDeactivated
			else:
				progress -= speed
			
		

extends Node2D

@export var handler: PuzzleComponent
@export var collision_box: Area2D

# debug
@export var DEBUG_LABEL: Label

func _ready() -> void:
	handler.speed = 100.0

func _physics_process(delta: float) -> void:
	if DEBUG_LABEL:
		DEBUG_LABEL.text = "%s" % handler.is_activated() 
	
	if collision_box:
		if collision_box.has_overlapping_bodies():
			handler.force_activate()
		else:
			handler.force_deactivate()


func recieved_impact() -> void:
	return

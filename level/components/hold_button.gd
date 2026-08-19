extends PuzzleComponent

@export var collision_box: Area2D

# debug
@export var DEBUG_LABEL: Label

func _ready() -> void:
	super._ready()
	speed = 100.0

func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)
	if DEBUG_LABEL:
		# DEBUG_LABEL.text = "%s" % handler.is_activated() 
		DEBUG_LABEL.text = "%s" % get_state_text()
	
	if collision_box:
		if collision_box.has_overlapping_bodies():
			force_activate()
		else:
			force_deactivate()
	elif DEBUG_LABEL:
		DEBUG_LABEL.text = "n/a"
		
func get_state_text() -> String:
	if is_activated():
		return "pressed"
	else:
		return "off"

func recieved_impact() -> void:
	return

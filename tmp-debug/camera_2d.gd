extends Camera2D

@export var target: Node2D
@export_range(0.0, 1.0) var smoothing := 0.05   # Smaller values follow more slowly and smoothly
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	# Interpolation that keeps the follow speed constant across frame rates
	global_position = global_position.lerp(target.global_position, 1.0 - pow(smoothing, delta))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

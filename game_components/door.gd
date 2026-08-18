extends PuzzleComponent

# @export var handler: PuzzleComponent
# @export var collision: RigidBody2D

var initial_position: Vector2 = Vector2.ZERO
var initial_rotation: float = 0.0

var timeout: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_position = position
	super._ready()
	

func _physics_process(_delta: float) -> void:
	super._physics_process(_delta)
	# room to add smoothing function
	position = initial_position + (Vector2.UP * progress * speed * 0.1)
	
func reset() -> void:
	position = initial_position
	super.reset()
	

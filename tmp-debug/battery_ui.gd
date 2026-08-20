extends Control

@onready var bg: ColorRect = $battery_bg
@onready var fg: ColorRect = $battery_fg

@export_range(0.0, 1.0, 0.01) var margin: float = 0.05

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
# 	fg.size = size - size * margin
#	fg.global_position = global_position + global_position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

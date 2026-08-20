extends Control

@onready var bg := $battery_bg
@onready var fg := $battery_fg

var margin: float = 0.05

var height := 100.0
var width := 100.0


func _ready() -> void:
	fg.size = Vector2(width, height)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

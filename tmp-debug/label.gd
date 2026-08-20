extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.body_charge_changed.connect(_on_charge_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_charge_changed(new_charge:int) -> void:
	text = "main charge: %s" % new_charge

extends Label

var nearby_parts_cache: Array[Part] = []

func _ready() -> void:
	EventBus.nearby_parts_updated.connect(_on_nearby_parts_updated)
	EventBus.body_attaching_state_changed.connect(_on_body_attaching_state_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_nearby_parts_updated(nearby_parts: Array[Part]) -> void:
	nearby_parts_cache = nearby_parts
	
	if nearby_parts_cache.is_empty(): 
		text = ""
		return
	
	var string_array : Array[String] = ["nearby parts:"]
	for part in nearby_parts:
		string_array.append("%s, can be attached to: %s" % [part.name, part.equippable_to])
	
	text = "%s" % "\n".join(string_array)
	
	return

func _on_body_attaching_state_changed(is_attaching: bool) -> void:
	visible = is_attaching
	return

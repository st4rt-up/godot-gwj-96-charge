extends Label

var nearby_parts_cache: Array[Part] = []

func _ready() -> void:
	EventBus.nearby_parts_updated.connect(_on_nearby_parts_updated)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_nearby_parts_updated(nearby_parts: Array[Part]) -> void:
	nearby_parts_cache = nearby_parts
	
	if nearby_parts_cache.is_empty(): 
		text = ""
		return
	
	var string_array : Array[String] = []
	for part in nearby_parts:
		string_array.insert(0, "%s, can be attached to: %s" % [part.name, part.equippable_to])
	
	text = "%s" % "\n".join(string_array)
	
	return

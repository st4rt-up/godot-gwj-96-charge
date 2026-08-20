extends Label

var legs_part : Part = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.body_attached_part.connect(_on_part_attached)
	EventBus.body_detached_part.connect(_on_part_detached)

func _process(delta: float) -> void:
	if legs_part:
		text = "legs, %s: %s charge" % [legs_part.name, legs_part.charge]
	else:
		text = "legs empty"

func _on_part_attached(part: Part, slot: Part.Slot) -> void:
	if slot == Part.Slot.LEGS:
		legs_part = part
	
func _on_part_detached(slot: Part.Slot) -> void:
	if slot == Part.Slot.LEGS:
		legs_part = null

extends Label

var left_arm_part : Part = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.body_attached_part.connect(_on_part_attached)
	EventBus.body_detached_part.connect(_on_part_detached)

func _process(delta: float) -> void:
	if left_arm_part:
		text = "left, %s: %s charge" % [left_arm_part.name, left_arm_part.charge]
	else:
		text = "left arm empty"

func _on_part_attached(part: Part, slot: Part.Slot) -> void:
	if slot == Part.Slot.LEFT_ARM:
		left_arm_part = part
	
func _on_part_detached(slot: Part.Slot) -> void:
	if slot == Part.Slot.LEFT_ARM:
		left_arm_part = null

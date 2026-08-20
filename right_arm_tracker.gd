extends Label

var right_arm_part : Part = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.body_attached_part.connect(_on_part_attached)
	EventBus.body_detached_part.connect(_on_part_detached)

func _process(delta: float) -> void:
	if right_arm_part:
		text = "right, %s: %s charge" % [right_arm_part.name, right_arm_part.charge]
	else:
		text = "right arm empty"

func _on_part_attached(part: Part, slot: Part.Slot) -> void:
	if slot == Part.Slot.RIGHT_ARM:
		right_arm_part = part
	
func _on_part_detached(slot: Part.Slot) -> void:
	if slot == Part.Slot.RIGHT_ARM:
		right_arm_part = null

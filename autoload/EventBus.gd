extends Node

signal body_charge_changed(new_charge: int)

signal body_attached_part(part: Part, slot: Part.Slot)
signal body_attached_part_fail(slot: Part.Slot)

signal body_attaching_state_changed(is_attaching : bool)

signal body_detached_part(slot: Part.Slot)
signal body_detached_part_fail(slot: Part.Slot)

signal character_jumped()

signal nearby_parts_updated(nearby_parts:Array[Part])

signal part_charge_changed(new_charge:int, part: Part)

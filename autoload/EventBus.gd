extends Node

signal main_body_charge_changed(new_charge: int)
signal body_attached_part(part: Part,slot: Part.Slot)
signal body_detached_part(slot: Part.Slot)
signal part_charge_changed(new_charge:int, part: Part)

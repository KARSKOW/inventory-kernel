@tool
extends HBoxContainer

@onready var num: EditorSpinSlider = $num

@onready var label: Label = $Label

func set_variant_property(value: int) -> void:
	num.value = int(round(value))

func get_variant_property() -> int:
	return int(round(num.value))
	
func set_variant_text(variant_name: String) -> void:
	label.text = variant_name
	
func get_variant_text() -> String:
	return label.text

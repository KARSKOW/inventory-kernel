@tool
extends HBoxContainer

@onready var x_size_num: EditorSpinSlider = $x_size_num
@onready var y_size_num: EditorSpinSlider = $y_size_num

@onready var label: Label = $Label

func set_variant_property(value: Vector2i) -> void:
	x_size_num.value = value.x
	y_size_num.value = value.y
	
func get_variant_property() -> Vector2i:
	return Vector2i(int(round(x_size_num.value)), int(round(y_size_num.value)))
	
func set_variant_text(variant_name: String) -> void:
	label.text = variant_name
	
func get_variant_text() -> String:
	return label.text

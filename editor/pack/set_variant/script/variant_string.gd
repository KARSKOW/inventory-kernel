@tool
extends HBoxContainer

@onready var line_edit: LineEdit = $LineEdit
@onready var label: Label = $Label

func set_variant_property(value) -> void:
	line_edit.text = value
	
func get_variant_property() -> String:
	return line_edit.text
	
func set_variant_text(variant_name: String) -> void:
	label.text = variant_name
	
func get_variant_text() -> String:
	return label.text

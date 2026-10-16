@tool
extends HBoxContainer

@onready var label: Label = $Label

var get_resource_texture: Texture2D

func get_variant_property() -> Texture2D:
	return get_resource_texture

func set_variant_text(variant_name: String) -> void:
	label.text = variant_name
	

func get_variant_text() -> String:
	return label.text


func _on_editor_resource_changed(resource: Resource) -> void:
	if resource == null:
		get_resource_texture = null
		return
		
	get_resource_texture = resource

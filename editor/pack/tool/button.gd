@tool
extends Button

var resource_class: StringName
var resource_path: String = "uid://evig614rtpon"
signal selected_template(type: StringName, path: String)

func _on_pressed() -> void:
	selected_template.emit(resource_class, resource_path)

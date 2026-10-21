@tool
extends HBoxContainer

@onready var repeat: RichTextLabel = $repeat

@onready var editor_resource_picker: EditorResourcePicker = $EditorResourcePicker


var is_mark_repeat: bool = false:
	set(value):
		is_mark_repeat = value
		repeat.visible = is_mark_repeat

var picker_resource: Resource

func set_resource(res: Resource) -> void:
	editor_resource_picker.edited_resource = res
	picker_resource = res


func _on_editor_resource_picker_resource_changed(resource: Resource) -> void:
	if resource == null:
		picker_resource = null
		return
	picker_resource = resource


func _on_button_pressed() -> void:
	self.queue_free()

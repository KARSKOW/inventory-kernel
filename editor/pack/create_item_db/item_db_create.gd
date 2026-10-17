@tool
extends TabBar

@onready var candidate_item_list: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer

const UI_CANDIDATE_ITEM = preload("uid://de1hijm6rdeev")


func _on_create_db_pressed() -> void:
	pass # Replace with function body.


func _on_join_item_pressed() -> void:
	var set_candidate_item = UI_CANDIDATE_ITEM.instantiate()
	candidate_item_list.add_child(set_candidate_item)
	set_candidate_item.is_mark_skip = false

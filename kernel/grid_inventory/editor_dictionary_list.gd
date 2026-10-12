@tool
extends Node

@export var item_data: GridItemData
@export_tool_button("Write data ->") var button = _clicked_button

@export var editor_dictionary: GridInventoryItemList

func _clicked_button():
	editor_dictionary.write_dictionary_list(item_data)
	item_data = null

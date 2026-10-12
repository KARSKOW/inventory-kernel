@tool
extends Resource

class_name GridInventoryItemList

@export var dictionary_list: Dictionary = {}

func write_dictionary_list(item: GridItemData):
	if item != null:
		dictionary_list[item.item_name] = item
	else:
		push_error("NO Items write.")

func get_item_resource(item_name: String):
	return dictionary_list.get(item_name)

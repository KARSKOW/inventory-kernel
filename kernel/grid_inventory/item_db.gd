extends Resource
class_name ItemDB

@export var item_library: Dictionary

func get_library_item(name: String):
	return item_library[name]

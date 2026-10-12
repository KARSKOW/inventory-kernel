extends RefCounted

class_name GridInventoryItemData

var data: GridItemData
var quantity: int
var cache: Dictionary

func get_item_name() -> String:
	return data.item_name

func get_item_describes() -> String:
	return data.describes

func get_item_type() -> String:
	return data.item_type

func get_item_image() -> Texture2D:
	return data.item_image

func get_stack_size() -> int:
	return data.stack_size


func get_item_size(is_rotated_size: bool = false) -> Vector2i:
	if is_rotated_size == true:
		return Vector2i(data.item_size.y, data.item_size.x)
	return data.item_size

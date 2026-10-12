extends CanvasLayer

class_name TakeModule

var is_dragging: bool = false

const ITEM_PACK = preload("uid://l2hhk8ohwlwn")

func _process(_delta: float) -> void:
	if is_dragging == true:
		var math_size = Vector2(get_dragging_item().item_size) * get_dragging_item().item_cell_size
		get_child(0).position = get_child(0).get_global_mouse_position() - math_size / 2

func create_new_drag_item(data: GridInventoryItemData, set_quantity: int, is_rotate: bool):
	var new_item = ITEM_PACK.instantiate()
	new_item.item_database = data
	new_item.quantity = set_quantity
	new_item.is_rotated = is_rotate
	new_item.set_rotated()
	add_child(new_item)

	var math_size = Vector2(new_item.item_size) * new_item.item_cell_size
	new_item.position = new_item.get_global_mouse_position() - math_size / 2
	get_child(0).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	is_dragging = true

func get_dragging_itemdata():
	if is_dragging == true:
		var get_item: GridInventoryItem = get_child(0)
		return get_item.item_database
		
func get_dragging_item():
	if is_dragging == true:
		var get_item: GridInventoryItem = get_child(0)
		return get_item
		
func get_dragging_item_rotated():
	if is_dragging == true:
		return get_dragging_item().is_rotated

func holding_item(target: GridInventoryItem):
	target.reparent(self)
	get_child(0).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	is_dragging = true
	
func rotate_hold_item(is_rotated: bool):
	if is_dragging == true:
		if is_rotated == true:
			get_dragging_item().is_rotated = true
			get_dragging_item().set_rotated()
		else:
			get_dragging_item().is_rotated = false
			get_dragging_item().set_rotated()
	
func dropped_item(target_item_list):
	get_child(0).mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	get_child(0).reparent(target_item_list, false)
	is_dragging = false
	

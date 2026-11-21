extends RefCounted

func grab_and_drop_item():
	var interface = InventoryInterface
	if interface.is_grabbing == false:
		if interface.get_inventory_gui == null:
			return

		var mouse_grid_pos = Vector2i(interface.get_inventory_gui.get_local_mouse_position() / interface.get_inventory_gui.cell_size)
		var get_map_item = interface.get_inventory_gui.get_grid_item(mouse_grid_pos)
		if get_map_item == null:
			return

		interface.grabbing_item = get_map_item
		interface.cancel_target_inventory = interface.get_inventory_gui
		interface.cancel_rotated = interface.grabbing_item.is_rotated
		interface.grab_before_position = Vector2i(interface.grabbing_item.position / interface.get_inventory_gui.cell_size)
		interface.get_inventory_gui._tar_clean_item_occupy(interface.grabbing_item)
		interface.grabbing_item.reparent(interface)
		interface.grabbing_item.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		interface.grab_offset = interface.grabbing_item.global_position - interface.grabbing_item.get_global_mouse_position()
		
		return

	if _get_computed_top_left() == Vector2i(-1, -1):
		return
	
	var get_grab_item = interface.grabbing_item.item_database
	if interface.get_inventory_gui.get_cells_occupy(_get_computed_top_left(), get_grab_item.get_item_size(interface.grabbing_item.is_rotated)) != null:
		grabbing_merge()
		return

	var item_size = interface.grabbing_item.item_size

	interface.grabbing_item.reparent(interface.get_inventory_gui)
	interface.grabbing_item.position = Vector2(_get_computed_top_left()) * interface.get_inventory_gui.cell_size
	interface.grabbing_item.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED

	interface.get_inventory_gui.set_cells_occupy(_get_computed_top_left(), get_grab_item.get_item_size(interface.grabbing_item.is_rotated), interface.grabbing_item)
	interface.cancel_target_inventory = null
	interface.cancel_source_item = null
	interface.grab_before_position = Vector2i(-1, -1)
	interface.grabbing_item = null

func grabbing_merge():
	var interface = InventoryInterface
	var interface_grabbing_item = interface.grabbing_item
	
	if interface_grabbing_item == null:
		return
	if interface.get_inventory_gui == null:
		return

	var get_inventory_map = interface.get_inventory_gui
	var mouse_grid_pos = Vector2i(get_inventory_map.get_local_mouse_position() / get_inventory_map.cell_size)
	var get_source_item: GridItemExample = get_inventory_map.get_grid_item(mouse_grid_pos)
	if get_source_item == null:
		return

	var get_source_data = get_source_item.item_database
	var get_grab_data = interface_grabbing_item.item_database
	if get_source_data.get_item_name() != get_grab_data.get_item_name():
		return

	var space: int = get_source_data.get_stack_size() - get_source_data.quantity
	if space <= 0:
		return

	var move_qty: int = mini(space, get_grab_data.quantity)
	get_source_data.quantity += move_qty
	get_grab_data.quantity -= move_qty
	get_source_item.update_item_viewport()

	if get_grab_data.quantity <= 0:
		interface_grabbing_item.queue_free()
		interface_grabbing_item = null
		interface.grabbing_item = null
		interface.cancel_source_item = null
		interface.cancel_target_inventory = null
		interface.grab_before_position = Vector2i(-1, -1)
	else:
		interface_grabbing_item.update_item_viewport()
		

func grabbing_cancel():
	var interface = InventoryInterface
	if interface.grabbing_item == null:
		return
		
	if interface.cancel_source_item != null:
		interface.cancel_source_item.item_database.quantity += interface.grabbing_item.item_database.quantity
		interface.cancel_source_item.update_item_viewport()
		
		interface.grabbing_item.queue_free()
		interface.grabbing_item = null
		
		interface.cancel_source_item = null
		return
		
	var get_item_size = interface.grabbing_item.item_database.get_item_size(interface.cancel_rotated)
	interface.grabbing_item.reparent(interface.cancel_target_inventory)
	interface.grabbing_item.position = Vector2(interface.grab_before_position) * interface.cancel_target_inventory.cell_size
	interface.grabbing_item.is_rotated = interface.cancel_rotated
	print("item cancel <-")
	interface.cancel_target_inventory.set_cells_occupy(interface.grab_before_position, get_item_size, interface.grabbing_item)
	interface.cancel_target_inventory = null
	interface.cancel_rotated = false
	
	interface.grab_before_position = Vector2i(-1, -1)
	
	interface.grabbing_item = null


func grab_half_item():
	var interface = InventoryInterface
	if interface.get_inventory_gui == null:
		return
	var get_inventory_map = interface.get_inventory_gui
	var mouse_grid_pos = Vector2i(get_inventory_map.get_local_mouse_position() / get_inventory_map.cell_size)
	var get_source_item: GridItemExample = get_inventory_map.get_grid_item(mouse_grid_pos)
	if get_source_item == null or get_source_item.item_database.quantity <= 1:
		return

	var get_source_half = get_inventory_map._drag_half_item(get_source_item)
	if get_source_half <= 0:
		return

	var create_new_item: GridItemExample = get_inventory_map.item_package.instantiate()
	var create_new_data := GridInventoryItemData.new()
	create_new_data.data = get_source_item.item_database.data
	create_new_data.cache = get_source_item.item_database.cache.duplicate()
	create_new_data.quantity = get_source_half
	
	create_new_item.item_database = create_new_data
	create_new_item.item_cell_size = get_inventory_map.cell_size
	create_new_item.item_size = get_source_item.item_size
	create_new_item.is_rotated = get_source_item.is_rotated

	interface.add_child(create_new_item)
	create_new_item._update_item_size()
	create_new_item.update_item_viewport()
	get_source_item.update_item_viewport()

	create_new_item.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	interface.grab_offset = -Vector2(create_new_item.item_size) * create_new_item.item_cell_size * 0.5
	create_new_item.global_position = create_new_item.get_global_mouse_position() + interface.grab_offset

	interface.grabbing_item = create_new_item
	interface.cancel_source_item = interface.get_inventory_gui.get_grid_item(mouse_grid_pos)



func grab_rotated_item():
	var interface = InventoryInterface
	if interface.grabbing_item == null:
		return

	var get_base_size = interface.grabbing_item.item_database.get_item_size()
	if get_base_size.x == get_base_size.y:
		return

	interface.grabbing_item.is_rotated = not interface.grabbing_item.is_rotated

	interface.grab_offset = -Vector2(interface.grabbing_item.item_size) * interface.grabbing_item.item_cell_size * 0.5


func grab_exchange_item():
	pass


func _get_computed_top_left() -> Vector2i:
	var interface = InventoryInterface
	var interface_grabbing_item = interface.grabbing_item
	
	if interface.get_inventory_gui == null or interface_grabbing_item == null:
		return Vector2i(-1, -1)

	var get_map_local_pos = interface.get_inventory_gui.get_local_mouse_position()
	var get_map_index = interface.get_inventory_gui.map_index
	
	var get_item_half_size = Vector2(interface_grabbing_item.item_size) * 0.5
	var item_data_size = interface_grabbing_item.item_database.get_item_size(interface_grabbing_item.is_rotated)
	var top_left = get_map_local_pos / interface.get_inventory_gui.cell_size - get_item_half_size
	var computed_top_left = Vector2i(round(top_left.x), round(top_left.y))

	if computed_top_left.x < 0 or computed_top_left.y < 0:
		return Vector2i(-1, -1)

	if computed_top_left.x > (get_map_index.x - 1) or computed_top_left.y > (get_map_index.y - 1):
		return Vector2i(-1, -1)

	if (computed_top_left.x + item_data_size.x) > get_map_index.x or (computed_top_left.y + item_data_size.y) > get_map_index.y:
		return Vector2i(-1, -1)

	return computed_top_left

@tool
extends GridInventoryKernel
class_name GridInventoryMap

var inventory_item_data_tree = []

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_build_cells_divination()
		mouse_exited.connect(func(): _preview_gridmap_hide())
		
func create_item(item_name: String, set_quantity: int, write_cache: Dictionary = {}):
	var get_item_data: GridItemData = item_data_list.get_item_resource(item_name)

	if get_item_data == null:
		print("Can't found this item: ", item_name)
		return

	var math: int = set_quantity / get_item_data.stack_size
	var quantity_left: int = set_quantity
	
	for i in range(math):
		_create_grid_item(item_name, get_item_data.stack_size, write_cache)
		quantity_left -= get_item_data.stack_size
	
	if quantity_left > 0:
		_create_grid_item(item_name, quantity_left, write_cache)
		
func create_item_base(data: GridItemData, quantity: int, i_size: Vector2i, i_position: Vector2, i_rorated: bool):
	_create_grid_item_base(data, i_position, i_size, quantity, i_rorated)

func create_inventory_item_data():
	inventory_item_data_tree = _create_snapshot()
	return _create_snapshot()

func clear_all_items(use_free: bool = true):
	for item in self.get_children():
		if use_free == true:
			item.queue_free()
		else:
			remove_child(item)
	cells_occupy = []
	_build_cells_divination()

func clear_item(item: GridInventoryItem):
	_tar_clean_item_divination(item)
	item.queue_free()
	
func clear_item_from_cursor(set_divination: bool = true) -> void:
	if set_divination == true and mouse_selection != null:
		mouse_selection.queue_free()
		_tar_clean_item_divination(mouse_selection)

func can_add_inventory(i_size: Vector2i) -> bool:
	if _scan_inventory_cells_empty(i_size) == Vector2i(-1, -1):
		if _scan_inventory_cells_empty(i_size, true) != Vector2i(-1, -1):
			return true
		return false
	return true

func stacked_item(target_item: GridInventoryItem, selection: GridInventoryItem) -> bool:
	if selection == null or selection.item_database.get_item_name() != target_item.item_database.get_item_name():
		return false

	var stack_max = selection.item_database.get_stack_size()
	var math = target_item.quantity + selection.quantity

	if math <= stack_max:
		selection.quantity += target_item.quantity
		target_item.queue_free()
		return false
	else:
		var space = stack_max - selection.quantity
		selection.quantity += space
		target_item.quantity -= space
		return target_item.quantity > 0
	
func external_write_inventory_data(inventory_timeshift: Array):
	_read_snapshot(inventory_timeshift)

func has_item_name(target_name: String) -> bool:
	for i: GridInventoryItem in get_children():
		if i.item_database.get_item_name() == target_name:
			return true
	return false

func addition_item(target_name: String, add_quantity: int, write_cache: Dictionary = {}):
	var addition_item_data: GridItemData = item_data_list.get_item_resource(target_name)
	if addition_item_data == null:
		return

	var quantity_left: int = add_quantity

	for item: GridInventoryItem in get_children():
		if item.item_database.get_item_name() == target_name:
			var math_stack_quantity = item.item_database.get_stack_size() - item.quantity
			if math_stack_quantity > 0:
				var get_min_quantity = mini(quantity_left, math_stack_quantity)
				item.quantity += get_min_quantity
				quantity_left -= get_min_quantity
				if quantity_left <= 0:
					return

	if quantity_left > 0:
		var full_stacks: int = quantity_left / addition_item_data.stack_size
		for i in range(full_stacks):
			_create_grid_item(addition_item_data.item_name, addition_item_data.stack_size, write_cache)
			quantity_left -= addition_item_data.stack_size
		if quantity_left > 0:
			_create_grid_item(addition_item_data.item_name, quantity_left, write_cache)

func subtract_item(target_name: String, sub_quantity: int):
	var subtract_item_data: GridItemData = item_data_list.get_item_resource(target_name)
	var get_currect_item: Array[GridInventoryItem]
	var quantity_left: int = sub_quantity
	if subtract_item_data == null:
		return

	for item: GridInventoryItem in get_children():
		if item.item_database.get_item_name() == target_name:
			get_currect_item.push_back(item)

	if get_currect_item.is_empty():
		return

	for item: GridInventoryItem in get_currect_item:
		if quantity_left <= 0:
			break
		if item._is_item_fulled():
			continue
		var get_min_quantity = mini(quantity_left, item.quantity)
		item.quantity -= get_min_quantity
		quantity_left -= get_min_quantity
		if item.quantity <= 0:
			_clean_item_divination(Vector2i(item.position / item.item_cell_size), item.item_size)
			item.queue_free()

	if quantity_left <= 0:
		return

	for item: GridInventoryItem in get_currect_item:
		if quantity_left <= 0:
			break
		if not item._is_item_fulled():
			continue
		var get_min_quantity = mini(quantity_left, item.quantity)
		item.quantity -= get_min_quantity
		quantity_left -= get_min_quantity
		if item.quantity <= 0:
			_clean_item_divination(Vector2i(item.position / item.item_cell_size), item.item_size)
			item.queue_free()


func sorted_item():
	var sort_collect = []

	for item: GridInventoryItem in get_children():
		sort_collect.append(item)

	_clean_item_divination(Vector2i.ZERO, gridmap_index)
	
	if sort_collect.size() <= 0:
		return
	
	sort_collect.sort_custom(_sort_item_custom)
	
	for item: GridInventoryItem in sort_collect:
		var get_top_left = _scan_cells_ract_empty(item.item_size)
		var set_top_left = Vector2(get_top_left) * cell_size
		if get_top_left != Vector2i(-1, -1):
			item.position = set_top_left
			_added_item_divination(get_top_left, item.item_size, item)

func _scan_inventory_cells_empty(item_size: Vector2i, rotated_scan: bool = false) -> Vector2i:
	if rotated_scan == false:
		return _scan_cells_ract_empty(item_size)
	return _scan_cells_ract_empty(Vector2i(item_size.y, item_size.x))

func get_item(is_children: bool) -> Array:
	if is_children == true:
		return get_children()
		
	return [get_child(-1)]

func set_item_divination_map(set_map: Array) -> void:
	cells_occupy = set_map
	
func get_item_divination_map() -> Array:
	return cells_occupy

func _is_item_stack_full(target_item: GridInventoryItem) -> bool:
	return target_item.quantity >= target_item.item_database.get_stack_size()

func _is_same_item_name(target_item: GridInventoryItem, selection: GridInventoryItem):
	var get_selection_item_name: String = selection.item_database.get_item_name()
	var get_target_item_name: String = target_item.item_database.get_item_name()
	return get_selection_item_name == get_target_item_name

func _sort_item_custom(a: GridInventoryItem, b:GridInventoryItem):
	if a.item_size != b.item_size:
		return a.item_size > b.item_size
	
	return a.quantity > b.quantity

func _drag_half_item(selection: GridInventoryItem):
	var compute_half = selection.quantity / 2
	selection.quantity -= compute_half
	return compute_half

func _clean_item_divination(up_left: Vector2i, item_size: Vector2i):
	_set_cells_divination(up_left, item_size, null)
	
func _tar_clean_item_divination(clean_target: GridInventoryItem):
	var get_top_left = Vector2i(clean_target.position / clean_target.item_cell_size)
	_clean_item_divination(get_top_left, clean_target.item_size)

func _added_item_divination(up_left: Vector2i, item_size: Vector2i, get_item: Variant):
	_set_cells_divination(up_left, item_size, get_item)

func connection_item_selection():
	for item: GridInventoryItem in get_children():
		if not item.mouse_entered_item_rect.is_connected(_is_mouse_entered_item):
			item.mouse_entered_item_rect.connect(_is_mouse_entered_item)
			item.mouse_exited_item_rect.connect(_is_mouse_exited_item)
		else:
			continue

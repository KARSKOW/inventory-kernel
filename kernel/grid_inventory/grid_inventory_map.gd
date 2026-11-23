@tool
extends GridInventoryKernel
class_name GridInventoryMap

var inventory_item_data_tree = []

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_create_cells_data()
		_create_cells_empty_list()
		_connect_signal()
		

func _connect_signal():
	mouse_entered.connect(func(): InventoryInterface.get_inventory_gui = self)
	mouse_exited.connect(func(): InventoryInterface.get_inventory_gui = null)

func create_item_for_name(item_name: String, set_quantity: int, write_cache: Dictionary = {}):
	var get_item_data: GridItemData = item_db.get_library_item(item_name)

	if get_item_data == null:
		print("Can't found this item: ", item_name)
		return

	var math: int = set_quantity / get_item_data.stack_size
	var quantity_left: int = set_quantity
	
	for i in range(math):
		create_grid_item(item_name, get_item_data.stack_size, write_cache)
		quantity_left -= get_item_data.stack_size
	
	if quantity_left > 0:
		create_grid_item(item_name, quantity_left, write_cache)


func create_item_for_resource(item_data: GridItemData, set_quantity: int, write_cache: Dictionary = {}):
	var math: int = set_quantity / item_data.stack_size
	var quantity_left: int = set_quantity
	
	for i in range(math):
		create_grid_item_for_resource(item_data, item_data.stack_size, write_cache)
		quantity_left -= item_data.stack_size
	
	if quantity_left > 0:
		create_grid_item_for_resource(item_data, quantity_left, write_cache)


func create_item_base(data: GridItemData, quantity: int, i_size: Vector2i, i_position: Vector2, i_rorated: bool):
	_create_grid_item_base(data, i_position, i_size, quantity, i_rorated)

func clear_all_items(use_free: bool = true):
	for item in self.get_children():
		if use_free == true:
			item.queue_free()
		else:
			remove_child(item)
	cells_occupy_data = []
	cells_non_occupy_list.clear()
	_create_cells_data()
	_create_cells_empty_list()

func clear_item(item: GridItemExample):
	_tar_clean_item_occupy(item)
	item.queue_free()
	
func clear_item_from_cursor(set_occupy: bool = true) -> void:
	if set_occupy == true and get_cursor_item != null:
		get_cursor_item.queue_free()
		_tar_clean_item_occupy(get_cursor_item)

func can_add_inventory(i_size: Vector2i) -> bool:
	if _scan_inventory_cells_empty(i_size) == Vector2i(-1, -1):
		if _scan_inventory_cells_empty(i_size, true) != Vector2i(-1, -1):
			return true
		return false
	return true

func stacked_item(target_item: GridItemExample, selection: GridItemExample) -> bool:
	if selection == null or selection.item_database.get_item_name() != target_item.item_database.get_item_name():
		return false

	var stack_max = selection.item_database.get_stack_size()
	var math = target_item.item_database.quantity + selection.item_database.quantity

	if math <= stack_max:
		selection.item_database.quantity += target_item.item_database.quantity
		target_item.queue_free()
		return false
	else:
		var space = stack_max - selection.item_database.quantity
		selection.item_database.quantity += space
		target_item.item_database.quantity -= space
		return target_item.item_database.quantity > 0

func create_inventory_snapshot():
	inventory_item_data_tree = create_snapshot()
	return create_snapshot()
	
func read_inventory_snapshot(inventory_snapshot: Array):
	read_snapshot(inventory_snapshot)

func has_item_name(target_name: String) -> bool:
	for i: GridItemExample in get_children():
		if i.item_database.get_item_name() == target_name:
			return true
	return false

func addition_item(target_name: String, add_quantity: int, write_cache: Dictionary = {}):
	var addition_item_data: GridItemData = item_db.get_library_item(target_name)
	if addition_item_data == null:
		return

	var quantity_left: int = add_quantity

	for item: GridItemExample in get_children():
		if item.item_database.get_item_name() == target_name:
			var math_stack_quantity = item.item_database.get_stack_size() - item.item_database.quantity
			if math_stack_quantity > 0:
				var get_min_quantity = mini(quantity_left, math_stack_quantity)
				item.item_database.quantity += get_min_quantity
				quantity_left -= get_min_quantity
				if quantity_left <= 0:
					return

	if quantity_left > 0:
		var full_stacks: int = quantity_left / addition_item_data.stack_size
		for i in range(full_stacks):
			create_grid_item(addition_item_data.item_name, addition_item_data.stack_size, write_cache)
			quantity_left -= addition_item_data.stack_size
		if quantity_left > 0:
			create_grid_item(addition_item_data.item_name, quantity_left, write_cache)

func subtract_item(target_name: String, sub_quantity: int):
	var subtract_item_data: GridItemData = item_db.get_library_item(target_name)
	var get_currect_item = find_grid_item(target_name)
	var quantity_left: int = sub_quantity
	if subtract_item_data == null:
		return

	if get_currect_item.is_empty():
		return

	for item: GridItemExample in get_currect_item:
		if quantity_left <= 0:
			break
		if item.item_database.quantity >= item.item_database.get_stack_size():
			continue
		var get_min_quantity = mini(quantity_left, item.item_database.quantity)
		item.item_database.quantity -= get_min_quantity
		quantity_left -= get_min_quantity
		if item.item_database.quantity <= 0:
			set_cells_occupy(Vector2i(item.position / item.item_cell_size), item.item_size, null)
			item.queue_free()

	if quantity_left <= 0:
		return

	for item: GridItemExample in get_currect_item:
		if quantity_left <= 0:
			break
		if not item._is_item_fulled():
			continue
		var get_min_quantity = mini(quantity_left, item.item_database.quantity)
		item.item_database.quantity -= get_min_quantity
		quantity_left -= get_min_quantity
		if item.item_database.quantity <= 0:
			set_cells_occupy(Vector2i(item.position / item.item_cell_size), item.item_size, null)
			item.queue_free()


func sorted_item():
	var sort_collect = []

	for item: GridItemExample in get_children():
		sort_collect.append(item)

	set_cells_occupy(Vector2i.ZERO, map_index, null)
	
	if sort_collect.size() <= 0:
		return
	
	sort_collect.sort_custom(_sort_item_custom)
	
	for item: GridItemExample in sort_collect:
		var get_top_left = scan_can_place_cells(item.item_size)
		var set_top_left = Vector2(get_top_left) * cell_size
		if get_top_left != Vector2i(-1, -1):
			item.position = set_top_left
			set_cells_occupy(get_top_left, item.item_size, item)

func _scan_inventory_cells_empty(item_size: Vector2i, rotated_scan: bool = false) -> Vector2i:
	if rotated_scan == false:
		return scan_can_place_cells(item_size)
	return scan_can_place_cells(Vector2i(item_size.y, item_size.x))

func get_grid_item(target: Vector2i) -> GridItemExample:
	return cells_occupy_data[target.y][target.x]


func _is_item_stack_full(target_item: GridItemExample) -> bool:
	return target_item.item_database.quantity >= target_item.item_database.get_stack_size()

func _is_same_item_name(target_item: GridItemExample, selection: GridItemExample):
	var get_selection_item_name: String = selection.item_database.get_item_name()
	var get_target_item_name: String = target_item.item_database.get_item_name()
	return get_selection_item_name == get_target_item_name

func _sort_item_custom(a: GridItemExample, b:GridItemExample):
	if a.item_size != b.item_size:
		return a.item_size > b.item_size
	
	return a.item_database.quantity > b.item_database.quantity

func _drag_half_item(selection: GridItemExample):
	var compute_half = selection.item_database.quantity / 2
	selection.item_database.quantity -= compute_half
	return compute_half

	
func _tar_clean_item_occupy(clean_target: GridItemExample):
	var get_top_left = Vector2i(clean_target.position / clean_target.item_cell_size)
	set_cells_occupy(get_top_left, clean_target.item_size, null)

func connection_item_selection():
	for item: GridItemExample in get_children():
		if not item.mouse_entered_item_rect.is_connected(_is_mouse_entered_item):
			item.mouse_entered_item_rect.connect(_is_mouse_entered_item)
			item.mouse_exited_item_rect.connect(_is_mouse_exited_item)
		else:
			continue

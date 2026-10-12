@tool
extends TextureRect
class_name GridInventoryKernel

## 处理无法放进时输出物品数据
signal inventory_overflow_item(overflow_data: Array)
signal is_inventory_change(item: Node)

@export var gridmap_index: Vector2i

@export var item_data_list: GridInventoryItemList

@export var cell_size: int = 64
@export_tool_button("Update index") var update_index: Callable = _build_cells_panel

@export var item_selection_size: GridInventorySelectionRect
@export var item_package: PackedScene = preload("uid://l2hhk8ohwlwn")

var cells_occupy = []

var mouse_selection: GridInventoryItem

func _ready() -> void:
	child_entered_tree.connect(_on_item_entered_tree)
	child_exiting_tree.connect(_on_item_exited_tree)

func _can_place_on_grid(pos: Vector2i, item_size: Vector2i):
	var math_bottom_right = pos + item_size - Vector2i(1, 1)
	
	if pos.x < 0 or pos.y < 0 \
	 or math_bottom_right.x >= gridmap_index.x \
	 or math_bottom_right.y >= gridmap_index.y:
		return false
		
	return _is_cells_empty(pos, item_size)

func _create_grid_item(item_name: String, set_quantity: int, write_cache: Dictionary = {}):
	var get_item_data: GridItemData = item_data_list.get_item_resource(item_name)
	if get_item_data == null:
		print_rich("[color=red] [ERROR][/color]", " Can't found this item: ", item_name)
		inventory_overflow_item.emit([item_name, set_quantity])
		return
	var size_normal: Vector2i = get_item_data.item_size
	var size_rotated := Vector2i(get_item_data.item_size.y, get_item_data.item_size.x)
	var get_top_left = _scan_cells_ract_empty(size_normal)
	var get_top_left_rotated = _scan_cells_ract_empty(size_rotated)

	if get_top_left == Vector2i(-1, -1):
		if get_top_left_rotated != Vector2i(-1, -1):
			var set_top_left_rotate = Vector2(get_top_left_rotated) * cell_size
			_add_item_to_grid(
				set_top_left_rotate, 
				get_top_left_rotated, 
				size_rotated, 
				get_item_data, 
				set_quantity, 
				true, 
				write_cache
				)

			return
		print_rich("[color=red] [ERROR][/color]", " Can't add this item. this object will not be generated. ")
		inventory_overflow_item.emit([item_name, set_quantity])
		return
	
	var set_top_left = Vector2(get_top_left) * cell_size
	_add_item_to_grid(
		set_top_left, 
		get_top_left, 
		size_normal, 
		get_item_data, 
		set_quantity, 
		false, 
		write_cache
		)

func _create_grid_item_base(data: GridItemData, i_position: Vector2, i_size: Vector2i, quantity: int, is_rotated: bool, write_cache: Dictionary = {}):
	if data == null:
		return
	var get_top_left = Vector2(i_position) / cell_size
	var set_top_left = Vector2(get_top_left) * cell_size
	_add_item_to_grid(set_top_left, get_top_left, i_size, data, quantity, is_rotated, write_cache)

func _create_snapshot() -> Array:
	var save_timeshift = []
	if get_child_count() > 0:
		for item: GridInventoryItem in get_children():
			if item.item_database == null:
				continue
			var create_config = {}
			create_config["data"] = item.item_database.data
			create_config["quantity"] = item.quantity
			create_config["position"] = item.position
			create_config["is_rotated"] = item.is_rotated
			create_config["cache_storage"] = item.item_database.cache
			save_timeshift.append(create_config)

	return save_timeshift
	

func _read_snapshot(read_resource: Array) -> void:
	if not read_resource.is_empty():
		for sav_config in read_resource:
			var port_data: GridItemData = sav_config.get("data")
			var port_quantity = sav_config.get("quantity")
			var port_position = sav_config.get("position")
			var port_is_rotated = sav_config.get("is_rotated")
			var port_cache = sav_config.get("cache_storage")
			
			if port_data == null:
				continue
			if port_cache == null:
				continue
			_create_grid_item_base(port_data, port_position, port_data.item_size, port_quantity, port_is_rotated, port_cache)
	

func _add_item_to_grid(c_position: Vector2, grid_pos: Vector2i, c_size: Vector2i, item_data: GridItemData, quantity: int, is_rotated: bool = false, write_cache: Dictionary = {}) -> void:
	var inter_item: GridInventoryItem = item_package.instantiate()
	inter_item.position = c_position
	inter_item.quantity = quantity

	var layer_data := GridInventoryItemData.new()
	layer_data.data = item_data
	layer_data.quantity = quantity
	layer_data.cache = write_cache
	
	inter_item.item_database = layer_data
	inter_item.item_size = c_size
	inter_item.is_rotated = is_rotated
	self.add_child(inter_item)
	inter_item._update_item_size()
	inter_item._update_item_data()
	inter_item.mouse_entered_item_rect.connect(_is_mouse_entered_item)
	inter_item.mouse_exited_item_rect.connect(_is_mouse_exited_item)
	_set_cells_divination(grid_pos, inter_item.item_size, inter_item)

func _math_top_left(math_px: Vector2, item_size: Vector2i) -> Vector2i:
	var math_size = Vector2(item_size) * 0.5
	var math_grid_index = (math_px / cell_size) - math_size
	var math_pos_px = Vector2i(round(math_grid_index.x), round(math_grid_index.y))
	return math_pos_px

func _build_cells_divination() -> void:
	for y in range(gridmap_index.y):
		var y_cell = []
		for x in range(gridmap_index.x):
			y_cell.append(null)
		cells_occupy.append(y_cell)
		
func _build_cells_panel():
	self.custom_minimum_size = Vector2(gridmap_index) * cell_size

func _scan_item_rect(px: Vector2, area: Vector2i):
	var top_left = _math_top_left(px, area)
	var item_found = []

	for y in range(area.y):
		for x in range(area.x):
			var gx = top_left.x + x
			var gy = top_left.y + y
			if gx < 0 or gy < 0 or gx >= gridmap_index.x or gy >= gridmap_index.y:
				continue
			var cell = cells_occupy[gy][gx]
			if cell != null:
				if not item_found.has(cell):
					item_found.append(cell)
	return item_found

func _scan_cells_ract_empty(area: Vector2i) -> Vector2i:
	for y in range(gridmap_index.y - area.y + 1):
		for x in range(gridmap_index.x - area.x + 1):
			if _is_cells_empty(Vector2(x, y), Vector2(area.x, area.y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _is_cells_empty(pos: Vector2i, item: Vector2i) -> bool:
	for rect_x in range(item.x):
		for rect_y in range(item.y):
			if cells_occupy[pos.y + rect_y][pos.x + rect_x] != null:
				return false
	return true

func _is_within_bounds(px: Vector2, g_size: Vector2i) -> bool:
	var top_left_index = _math_top_left(px, g_size)
	var math_bottom_right = top_left_index + g_size - Vector2i(1, 1)
	
	if top_left_index.x >= 0 and top_left_index.y >= 0 \
		and math_bottom_right.x < gridmap_index.x \
		and math_bottom_right.y < gridmap_index.y:
		return true
	else:
		return false

func _set_cells_divination(start_vec: Vector2i, item_size: Vector2i, divination: Variant) -> void:
	for y in range(item_size.y):
		for x in range(item_size.x):
			cells_occupy[start_vec.y + y][start_vec.x + x] = divination

func _get_cells_divination(start_vec: Vector2i, item_size: Vector2i):
	for y in range(item_size.y):
		for x in range(item_size.x):
			var gy = start_vec.y + y
			var gx = start_vec.x + x
			if gy < 0 or gy >= gridmap_index.y or gx < 0 or gx >= gridmap_index.x:
				return false
			if cells_occupy[gy][gx] != null:
				return false
	return true

func _preview_gridmap(mouse_px: Vector2, selection_size: Vector2i) -> void:
	if item_selection_size == null:
		return
	var math_size = Vector2(selection_size) * 0.5
	var top_left_index = _math_top_left(mouse_px, selection_size)
	var px = (Vector2(top_left_index) + math_size) * cell_size
	
	if _is_within_bounds(mouse_px, selection_size):
		if _scan_item_rect(mouse_px, selection_size).size() <= 1:
			var new_size = Vector2(selection_size.x * cell_size, selection_size.y * cell_size)
			item_selection_size.set_selection_rect(new_size)
			item_selection_size.set_selection_position(px - new_size / 2)
			item_selection_size.visible = true
		else:
			item_selection_size.visible = false
	else:
		item_selection_size.visible = false

func _preview_gridmap_hide() -> void:
	if item_selection_size == null:
		return
	item_selection_size.visible = false



func _dev_update_index() -> void:
	_build_cells_panel()

func _on_resized() -> void:
	_build_cells_panel()

func _is_mouse_entered_item(rect):
	mouse_selection = rect
	
func _is_mouse_exited_item():
	mouse_selection = null
	
func _on_item_entered_tree(node):
	is_inventory_change.emit(node)
	
func _on_item_exited_tree(node):
	is_inventory_change.emit(node)

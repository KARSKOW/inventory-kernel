@tool
@abstract
extends Control

class_name GridInventoryKernel

signal inventory_overflow_item(overflow_data: Array)
signal is_inventory_change(item: Node)

signal _is_entered_trigger(event: InputEvent, tar_kernel)

@export var map_index: Vector2i = Vector2i(1, 1):
	set(value):
		map_index = value
		_update_cells_panel()
		
#@export var map_choosing_texture: Texture2D
@export var map_choosing_color: Color
		
@export var item_db: ItemDB
@export var item_package: PackedScene

@export_group("Cell setting")
@export var cell_size: int = 64:
	set(value):
		cell_size = value
		_update_cells_panel()
		
@export var cell_texture: Texture2D:
	set(value):
		cell_texture = value
		queue_redraw()

var cells_occupy_data = []


var cells_non_occupy_list = {}

var get_cursor_item: GridItemExample




func _ready() -> void:
	child_entered_tree.connect(_on_item_entered_tree)
	child_exiting_tree.connect(_on_item_exited_tree)
	gui_input.connect(_on_trigger_is_inventory)



func _draw() -> void:
	if cell_texture:
		draw_texture_rect(
			cell_texture,
			Rect2(Vector2.ZERO, size),
			true
		)
	if not Engine.is_editor_hint():
		if InventoryInterface.grabbing_item != null:
			var get_item_size = InventoryInterface.grabbing_item.item_database.get_item_size(InventoryInterface.grabbing_item.is_rotated)
			_update_selecter_preview(get_local_mouse_position(), get_item_size)



func _input(_event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		if InventoryInterface.grabbing_item != null:
			queue_redraw()



func create_grid_item(item_name: String, set_quantity: int, write_cache: Dictionary = {}):
	var get_item_data: GridItemData = item_db.get_library_item(item_name)
	if get_item_data == null:
		print_rich("[color=red] [ERROR][/color]", " Can't found this item: ", item_name)
		inventory_overflow_item.emit([item_name, set_quantity])
		return


	var size_normal: Vector2i = get_item_data.item_size
	var size_rotated := Vector2i(get_item_data.item_size.y, get_item_data.item_size.x)
	var get_top_left = scan_can_place_cells(size_normal)
	var get_top_left_rotated = scan_can_place_cells(size_rotated)

	if get_top_left == Vector2i(-1, -1):
		if get_top_left_rotated != Vector2i(-1, -1):
			var set_top_left_rotate = Vector2(get_top_left_rotated) * cell_size
			_add_item_to_grid(set_top_left_rotate, set_quantity, get_item_data, true, write_cache)

			return
		print_rich("[color=red] [ERROR][/color]", " Can't add this item. this object will not be generated. ")
		inventory_overflow_item.emit([item_name, set_quantity])
		return
	
	var set_top_left = Vector2(get_top_left) * cell_size
	_add_item_to_grid(set_top_left, set_quantity, get_item_data, false, write_cache)



func create_grid_item_for_resource(item_data: GridItemData, set_quantity: int, write_cache: Dictionary = {}):
	var size_normal: Vector2i = item_data.item_size
	var size_rotated := Vector2i(item_data.item_size.y, item_data.item_size.x)
	var get_top_left = scan_can_place_cells(size_normal)
	var get_top_left_rotated = scan_can_place_cells(size_rotated)

	if get_top_left == Vector2i(-1, -1):
		if get_top_left_rotated != Vector2i(-1, -1):
			var set_top_left_rotate = Vector2(get_top_left_rotated) * cell_size
			_add_item_to_grid(set_top_left_rotate, set_quantity, item_data, true, write_cache)

			return
		print_rich("[color=red] [ERROR][/color]", " Can't add this item. this object will not be generated. ")
		inventory_overflow_item.emit([item_data.name, set_quantity])
		return
	
	var set_top_left = Vector2(get_top_left) * cell_size
	_add_item_to_grid(set_top_left, set_quantity, item_data, false, write_cache)


# Warning: Experimental.
# Need TEST this function acceptable.
func find_grid_item(item_name: String):
	var found_item = []
	for item: GridItemExample in get_children():
		if item.item_database.get_item_name() == item_name:
			found_item.append(item)
	return found_item


# Warning: Experimental.
# Need TEST this function acceptable.
func placed_grid_item(item_object: Array[GridItemExample]):
	for item: GridItemExample in item_object:
		if scan_can_place_cells(item.item_database.get_item_size(item.is_rotated)) != Vector2i(-1, -1):
			item.reparent(self)
			item.position = scan_can_place_cells(item.item_database.get_item_size(item.is_rotated)) * cell_size
			set_cells_occupy(Vector2i(Vector2(item.position) / cell_size), item.item_database.get_item_size(item.is_rotated), item)



# Warning: Experimental.
# Need TEST this function acceptable.
func remove_grid_item(item_object: GridItemExample):
	var get_item_size = item_object.item_database.get_item_size(item_object.is_rotated)
	set_cells_occupy(Vector2i(Vector2(item_object.position) / cell_size), get_item_size, null)
	item_object.queue_free()


func get_grid_item(target: Vector2i) -> GridItemExample:
	if not is_cells_in_bounds(target, Vector2i.ONE):
		return null

	if cells_occupy_data.is_empty():
		return null

	if target.y >= cells_occupy_data.size():
		return null

	if target.x >= cells_occupy_data[target.y].size():
		return null

	return cells_occupy_data[target.y][target.x]


func create_snapshot() -> Array:
	var save_timeshift = []
	if get_child_count() > 0:
		for item: GridItemExample in get_children():
			if item.item_database == null:
				continue
			var create_config = {}
			create_config["data"] = item.item_database.data
			create_config["quantity"] = item.item_database.quantity
			create_config["position"] = item.position
			create_config["is_rotated"] = item.is_rotated
			create_config["cache_storage"] = item.item_database.cache
			save_timeshift.append(create_config)

	return save_timeshift



func read_snapshot(read_resource: Array) -> void:
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
			_create_grid_item_base(port_data, port_position, port_quantity, port_is_rotated, port_cache)



func scan_can_place_cells(item_size: Vector2i):
	var get_cells_non_occupy_list = cells_non_occupy_list.keys()
	var lambda = func(a: Vector2i, b: Vector2i): return a.y < b.y if a.y != b.y else a.x < b.x
	get_cells_non_occupy_list.sort_custom(lambda)
	
	for i in get_cells_non_occupy_list:
		if is_cells_in_bounds(i, item_size) and get_cells_occupy(i, item_size) == null:
			return Vector2i(i)
	return Vector2i(-1, -1)



func set_cells_occupy(start_vec: Vector2i, item_size: Vector2i, set_occupy: Variant) -> void:
	if cells_occupy_data.is_empty():
		_create_cells_data()
	
	if not is_cells_in_bounds(start_vec, item_size):
		return

	for y in range(item_size.y):
		for x in range(item_size.x):
			cells_occupy_data[start_vec.y + y][start_vec.x + x] = set_occupy
	
	if set_occupy != null:
		_remove_target_cells(start_vec)
	else:
		_add_target_cells(start_vec)


func get_cells_occupy_map() -> Array:
	var cell_list = []
	for cell_y in range(map_index.y):
		for cell_x in range(map_index.x):
			if cells_occupy_data[cell_y][cell_x] != null:
				cell_list.append(cells_occupy_data[cell_y][cell_x].item_database)
			else:
				cell_list.append(null)
			
	return cell_list


func get_cells_occupy(start_vec: Vector2i, item_size: Vector2i) -> GridItemExample:
	assert(is_cells_in_bounds(start_vec, item_size))

	if cells_occupy_data.is_empty():
		return null
		
	for y in range(item_size.y):
		for x in range(item_size.x):
			var occupy_item = cells_occupy_data[start_vec.y + y][start_vec.x + x]
			if occupy_item != null:
				return occupy_item
	return null


func is_cells_in_bounds(start_vec: Vector2i, item_size: Vector2i) -> bool:
	if item_size.x <= 0 or item_size.y <= 0:
		return false

	if start_vec.x < 0 or start_vec.y < 0:
		return false

	if start_vec.x + item_size.x > map_index.x:
		return false

	if start_vec.y + item_size.y > map_index.y:
		return false

	return true


func _create_grid_item_base(data: GridItemData, i_position: Vector2, quantity: int, is_rotated: bool, write_cache: Dictionary = {}):
	if data == null:
		return
	var set_top_left = (Vector2(i_position) / cell_size) * cell_size
	_add_item_to_grid(set_top_left, quantity, data, is_rotated, write_cache)



func _add_item_to_grid(i_position: Vector2, quantity: int, i_data: GridItemData, is_rotated: bool = false, write_cache: Dictionary = {}) -> void:
	var inter_item: GridItemExample = item_package.instantiate()
	var i_position_index = Vector2(i_position) / cell_size
	
	inter_item.position = i_position
	inter_item.item_cell_size = cell_size

	var layer_data := GridInventoryItemData.new()
	layer_data.data = i_data
	layer_data.quantity = quantity
	layer_data.cache = write_cache
	
	inter_item.item_database = layer_data
	inter_item.item_size = layer_data.get_item_size(is_rotated)
	inter_item.is_rotated = is_rotated
	self.add_child(inter_item)
	inter_item._update_item_size()
	inter_item.mouse_entered_item_rect.connect(_is_mouse_entered_item)
	inter_item.mouse_exited_item_rect.connect(_is_mouse_exited_item)
	set_cells_occupy(Vector2i(i_position_index), inter_item.item_size, inter_item)

				 # ===== COMPUTE CELLS RECT ===== #

func _compute_top_left(math_px: Vector2, _item_size: Vector2i) -> Vector2i:
	# 按抓取偏移计算物品的虚拟左上角
	var virtual_top_left = math_px + InventoryInterface.grab_offset
	var math_grid_index = virtual_top_left / cell_size
	return Vector2i(round(math_grid_index.x), round(math_grid_index.y))



func _create_cells_data() -> void:
	cells_occupy_data.clear()
	for y in range(map_index.y):
		var create_line = []
		create_line.resize(map_index.x)
		create_line.fill(null)
		cells_occupy_data.append(create_line)
	

func _create_cells_empty_list() -> void:
	for point_y in range(map_index.y):
		for point_x in range(map_index.x):
			if not cells_occupy_data[point_y][point_x]:
				cells_non_occupy_list[Vector2i(point_x, point_y)] = Vector2i(point_x, point_y)

func _remove_target_cells(target_vec: Vector2i) -> void:
	cells_non_occupy_list.erase(target_vec)
	
func _add_target_cells(target_vec: Vector2i) -> void:
	cells_non_occupy_list[target_vec] = target_vec



						# ===== PREVIEW ===== #

func _update_cells_panel() -> void:
	
	custom_minimum_size = Vector2(map_index) * cell_size
	size = Vector2(map_index) * cell_size
	
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _update_selecter_preview(mouse_px: Vector2, chooise_size: Vector2i) -> void:
	var math_size = Vector2(chooise_size) * 0.5
	var top_left_index = _compute_top_left(mouse_px, chooise_size)
	var px = (Vector2(top_left_index) + math_size) * cell_size
	
	if not is_cells_in_bounds(top_left_index, chooise_size):
		return

	if get_cells_occupy(top_left_index, chooise_size) != null:
		return
	
	var new_size = Vector2(chooise_size.x * cell_size, chooise_size.y * cell_size)
	draw_rect(Rect2((px - new_size / 2), new_size), map_choosing_color)



func _on_trigger_is_inventory(event: InputEvent) -> void:
	_is_entered_trigger.emit(event, self)


func _dev_update_index() -> void:
	_update_cells_panel()

func _on_resized() -> void:
	_update_cells_panel()

func _is_mouse_entered_item(rect):
	get_cursor_item = rect
	
func _is_mouse_exited_item():
	get_cursor_item = null
	
func _on_item_entered_tree(node):
	is_inventory_change.emit(node)
	
func _on_item_exited_tree(node):
	is_inventory_change.emit(node)

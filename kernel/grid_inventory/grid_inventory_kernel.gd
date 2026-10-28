@tool
@abstract
extends Control
class_name GridInventoryKernel

signal inventory_overflow_item(overflow_data: Array)
signal is_inventory_change(item: Node)

@export var map_index: Vector2i = Vector2i(1, 1):
	set(value):
		map_index = value
		_update_cells_panel()
		
@export var map_choosing_texture: Texture2D
		
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

var cells_occupy: BitMap

var cells_non_occupy_list = {}

var mouse_selection: GridInventoryItem




func _ready() -> void:
	child_entered_tree.connect(_on_item_entered_tree)
	child_exiting_tree.connect(_on_item_exited_tree)



func _draw() -> void:
	if cell_texture:
		draw_texture_rect(
			cell_texture,
			Rect2(Vector2.ZERO, size),
			true
		)
	#if map_choosing_texture:
		#_preview_selecter(get_local_mouse_position(), Vector2i())



func _can_place_on_grid(pos: Vector2i, item_size: Vector2i):
	var math_bottom_right = pos + item_size - Vector2i(1, 1)
	
	if pos.x < 0 or pos.y < 0 \
	 or math_bottom_right.x >= map_index.x \
	 or math_bottom_right.y >= map_index.y:
		return false
		
	return _is_cells_empty(pos, item_size)



func _create_grid_item(item_name: String, set_quantity: int, write_cache: Dictionary = {}):
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



func _create_grid_item_for_resource(item_data: GridItemData, set_quantity: int, write_cache: Dictionary = {}):
	var size_normal: Vector2i = item_data.item_size
	var size_rotated := Vector2i(item_data.item_size.y, item_data.item_size.x)
	var get_top_left = scan_can_place_cells(size_normal)
	var get_top_left_rotated = scan_can_place_cells(size_rotated)

	if get_top_left == Vector2i(-1, -1):
		if get_top_left_rotated != Vector2i(-1, -1):
			var set_top_left_rotate = Vector2(get_top_left_rotated) * cell_size
			_add_item_to_grid(
				set_top_left_rotate, 
				get_top_left_rotated, 
				size_rotated, 
				item_data, 
				set_quantity, 
				true, 
				write_cache
				)

			return
		print_rich("[color=red] [ERROR][/color]", " Can't add this item. this object will not be generated. ")
		inventory_overflow_item.emit([item_data.name, set_quantity])
		return
	
	var set_top_left = Vector2(get_top_left) * cell_size
	_add_item_to_grid(
		set_top_left, 
		get_top_left, 
		size_normal, 
		item_data, 
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
	_set_cells_occupy(grid_pos, inter_item.item_size, inter_item)

				 # ===== COMPUTE CELLS RECT ===== #

func _compute_top_left(math_px: Vector2, item_size: Vector2i) -> Vector2i:
	var math_size = Vector2(item_size) * 0.5
	var math_grid_index = (math_px / cell_size) - math_size
	var math_pos_px = Vector2i(round(math_grid_index.x), round(math_grid_index.y))
	return math_pos_px



func _create_cells_data() -> void:
	cells_occupy_data.clear()
	cells_occupy = BitMap.new()
	cells_occupy.create(map_index)
	for y in range(map_index.y):
		var create_line = []
		create_line.resize(map_index.x)
		create_line.fill(null)
		cells_occupy_data.append(create_line)
	

func _create_cells_empty_list() -> void:
	for point_y in range(cells_occupy.get_size().y):
		for point_x in range(cells_occupy.get_size().x):
			if not cells_occupy.get_bit(point_x, point_y):
				cells_non_occupy_list[Vector2i(point_x, point_y)] = Vector2i(point_x, point_y)

func _remove_target_cells(target_vec: Vector2i) -> void:
	cells_non_occupy_list.erase(target_vec)
	
func _add_target_cells(target_vec: Vector2i) -> void:
	cells_non_occupy_list[target_vec] = target_vec

func scan_can_place_cells(item_size: Vector2i):
	var get_cells_non_occupy_list = cells_non_occupy_list.keys()
	var lambda = func(a: Vector2i, b: Vector2i): return a.y < b.y if a.y != b.y else a.x < b.x
	get_cells_non_occupy_list.sort_custom(lambda)
	print(get_cells_non_occupy_list)
	
	for i in get_cells_non_occupy_list:
		if _is_cells_empty(i, item_size):
			return Vector2i(i)
	return Vector2i(-1, -1)



func _is_cells_empty(start_pos: Vector2i, item_size: Vector2i) -> bool:
	if start_pos.x < 0 or start_pos.y < 0:
		return false
		
	if start_pos.x + item_size.x > map_index.x:
		return false
		
	if start_pos.y + item_size.y > map_index.y:
		return false
		
	for rect_x in range(item_size.x):
		for rect_y in range(item_size.y):
			if cells_occupy_data[start_pos.y + rect_y][start_pos.x + rect_x] != null:
				return false
	return true


func _is_within_bounds(px: Vector2, g_size: Vector2i) -> bool:
	var top_left_index = _compute_top_left(px, g_size)
	var math_bottom_right = top_left_index + g_size - Vector2i(1, 1)
	
	if top_left_index.x >= 0 and top_left_index.y >= 0 \
		and math_bottom_right.x < map_index.x \
		and math_bottom_right.y < map_index.y:
		return true
	else:
		return false



func _set_cells_occupy(start_vec: Vector2i, item_size: Vector2i, set_occupy: Variant) -> void:
	if cells_occupy_data.is_empty():
		_create_cells_data()

	for y in range(item_size.y):
		for x in range(item_size.x):
			cells_occupy_data[start_vec.y + y][start_vec.x + x] = set_occupy
	
	if set_occupy != null:
		cells_occupy.set_bit_rect(Rect2i(start_vec, item_size), true)
		_remove_target_cells(start_vec)
	else:
		cells_occupy.set_bit_rect(Rect2i(start_vec, item_size), false)
		_add_target_cells(start_vec)



func _get_cells_occupy(start_vec: Vector2i, item_size: Vector2i):
	if start_vec.x < 0 or start_vec.y < 0:
		return false
		
	if start_vec.x + item_size.x > map_index.x:
		return false
		
	if start_vec.y + item_size.y > map_index.y:
		return false
		
	for y in range(item_size.y):
		for x in range(item_size.x):
			if cells_occupy_data[start_vec.y + y][start_vec.x + x] != null:
				return false
	return true

						# ===== PREVIEW ===== #

func _update_cells_panel() -> void:
	custom_minimum_size = Vector2(map_index) * cell_size
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


#func _preview_selecter(mouse_px: Vector2, chooise_size: Vector2i) -> void:
	#var math_size = Vector2(chooise_size) * 0.5
	#var top_left_index = _compute_top_left(mouse_px, chooise_size)
	#var px = (Vector2(top_left_index) + math_size) * cell_size
	#
	#if _is_within_bounds(mouse_px, chooise_size):
		#if _scan_item_rect(mouse_px, chooise_size).size() <= 1:
			#var new_size = Vector2(chooise_size.x * cell_size, chooise_size.y * cell_size)
			#draw_texture_rect(
				#map_choosing_texture,
				#Rect2((px - new_size / 2), new_size),
				#false
				#)
			##item_selection_size.set_selection_rect(new_size)
			##item_selection_size.set_selection_position(px - new_size / 2)
		#else:
			#queue_redraw()
	#else:
		#queue_redraw()



func _dev_update_index() -> void:
	_update_cells_panel()

func _on_resized() -> void:
	_update_cells_panel()

func _is_mouse_entered_item(rect):
	mouse_selection = rect
	
func _is_mouse_exited_item():
	mouse_selection = null
	
func _on_item_entered_tree(node):
	is_inventory_change.emit(node)
	
func _on_item_exited_tree(node):
	is_inventory_change.emit(node)

extends CanvasLayer

const GrabService = preload("uid://cdpum4qhf7ycg")

const smooth_offset: float = 0.5

# 抓取模式：0 = Drag（拖拽），1 = Take（拿起），对应项目设置中的枚举
var grab_action: int

var is_grabbing: bool

# 鼠标当前所在的库存地图，由 GridInventoryMap 的 mouse_entered / mouse_exited 维护
var mouse_entered_inventory: GridInventoryMap

var revoked_target_inventory: GridInventoryMap
var revoked_rotated: bool
var revoked_source_item: GridInventoryItem

var grabbing_item: GridInventoryItem:
	set(value):
		grabbing_item = value
		if grabbing_item != null:
			is_grabbing = true
		else:
			is_grabbing = false

var grab_offset: Vector2
var grab_before_position: Vector2i = Vector2i(-1, -1)


enum GrabStatus{
	NONE,
	DRAGGING
}

func _ready() -> void:
	_get_config()


func _input(event: InputEvent) -> void:
	var grab = GrabService.new()

	if _mouse_trigger(event, MOUSE_BUTTON_LEFT):
		if mouse_entered_inventory == null:
			return
		_grab_and_drop_item()
		
	if _mouse_trigger(event, MOUSE_BUTTON_RIGHT):
		_grab_revoked_item()
		
	if _keyboard_trigger(event, "grab_half"):
		_grab_half_item()
		
	if _keyboard_trigger(event, "grab_rotate"):
		_grab_rotated_item()

func _process(_delta: float) -> void:
	if grabbing_item == null:
		return

	grabbing_item.global_position = grabbing_item.get_global_mouse_position() + grab_offset
	
func _get_config() -> void:
	grab_action = int(ProjectSettings.get_setting("inventory-kernel/mouse_grab_action", 1))

	#var value = ProjectSettings.get_setting("inventory-kernel/mouse_grab_button", MOUSE_BUTTON_LEFT)
	#grab_button = int(value) if value is int else MOUSE_BUTTON_LEFT

func _mouse_trigger(event: InputEvent, button_index: int) -> bool:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == button_index:
			return true
		return false
	return false
	
func _keyboard_trigger(event: InputEvent, input_name: String):
	if event.is_action_pressed(input_name):
		return true
	return false

func _grab_and_drop_item():
	if is_grabbing == false:
		var mouse_grid_pos = Vector2i(mouse_entered_inventory.get_local_mouse_position() / mouse_entered_inventory.cell_size)
		var get_map_item = mouse_entered_inventory.get_grid_item(mouse_grid_pos)
		if get_map_item == null:
			return

		grabbing_item = get_map_item
		revoked_target_inventory = mouse_entered_inventory
		revoked_rotated = grabbing_item.is_rotated
		grab_before_position = Vector2i(grabbing_item.position / mouse_entered_inventory.cell_size)
		mouse_entered_inventory._tar_clean_item_occupy(grabbing_item)
		grabbing_item.reparent(self)
		grabbing_item.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		grab_offset = grabbing_item.global_position - grabbing_item.get_global_mouse_position()
		
		return

	if _get_computed_top_left() == Vector2i(-1, -1):
		return
	
	var get_grab_item = grabbing_item.item_database
	if mouse_entered_inventory.get_cells_occupy(_get_computed_top_left(), get_grab_item.get_item_size(grabbing_item.is_rotated)) == false:
		_grab_merge_item()
		return

	var item_size = grabbing_item.item_size

	grabbing_item.reparent(mouse_entered_inventory)
	grabbing_item.position = Vector2(_get_computed_top_left()) * mouse_entered_inventory.cell_size
	grabbing_item.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED

	mouse_entered_inventory._added_item_occupy(_get_computed_top_left(), get_grab_item.get_item_size(grabbing_item.is_rotated), grabbing_item)
	revoked_target_inventory = null
	revoked_source_item = null
	grab_before_position = Vector2i(-1, -1)
	grabbing_item = null


func _grab_revoked_item():
	if grabbing_item == null:
		return
		
	if revoked_source_item != null:
		revoked_source_item.item_database.quantity += grabbing_item.item_database.quantity
		revoked_source_item.update_item_data()
		
		grabbing_item.queue_free()
		grabbing_item = null
		
		revoked_source_item = null
		return
		
	var get_item_size = grabbing_item.item_database.get_item_size(revoked_rotated)
	grabbing_item.reparent(revoked_target_inventory)
	grabbing_item.position = Vector2(grab_before_position) * revoked_target_inventory.cell_size
	grabbing_item.is_rotated = revoked_rotated
	print("revoke")
	revoked_target_inventory._added_item_occupy(grab_before_position, get_item_size, grabbing_item)
	revoked_target_inventory = null
	revoked_rotated = false
	
	grab_before_position = Vector2i(-1, -1)
	
	grabbing_item = null


func _grab_half_item():
	if mouse_entered_inventory == null:
		return
	var get_inventory_map = mouse_entered_inventory
	var mouse_grid_pos = Vector2i(get_inventory_map.get_local_mouse_position() / get_inventory_map.cell_size)
	var get_source_item: GridInventoryItem = get_inventory_map.get_grid_item(mouse_grid_pos)
	if get_source_item == null or get_source_item.item_database.quantity <= 1:
		return

	var get_source_half = get_inventory_map._drag_half_item(get_source_item)
	if get_source_half <= 0:
		return

	var create_new_item: GridInventoryItem = get_inventory_map.item_package.instantiate()
	var create_new_data := GridInventoryItemData.new()
	create_new_data.data = get_source_item.item_database.data
	create_new_data.cache = get_source_item.item_database.cache.duplicate()
	create_new_data.quantity = get_source_half
	
	create_new_item.item_database = create_new_data
	create_new_item.item_cell_size = get_inventory_map.cell_size
	create_new_item.item_size = get_source_item.item_size
	create_new_item.is_rotated = get_source_item.is_rotated

	add_child(create_new_item)
	create_new_item._update_item_size()
	create_new_item.update_item_data()
	get_source_item.update_item_data()

	create_new_item.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	grab_offset = -Vector2(create_new_item.item_size) * create_new_item.item_cell_size * 0.5
	create_new_item.global_position = create_new_item.get_global_mouse_position() + grab_offset

	grabbing_item = create_new_item
	revoked_source_item = mouse_entered_inventory.get_grid_item(mouse_grid_pos)

func _grab_merge_item():
	if grabbing_item == null:
		return
	if mouse_entered_inventory == null:
		return

	var get_inventory_map = mouse_entered_inventory
	var mouse_grid_pos = Vector2i(get_inventory_map.get_local_mouse_position() / get_inventory_map.cell_size)
	var get_source_item: GridInventoryItem = get_inventory_map.get_grid_item(mouse_grid_pos)
	if get_source_item == null:
		return

	var get_source_data = get_source_item.item_database
	var get_grab_data = grabbing_item.item_database
	if get_source_data.get_item_name() != get_grab_data.get_item_name():
		return

	var space: int = get_source_data.get_stack_size() - get_source_data.quantity
	if space <= 0:
		return

	var move_qty: int = mini(space, get_grab_data.quantity)
	get_source_data.quantity += move_qty
	get_grab_data.quantity -= move_qty
	get_source_item.update_item_data()

	if get_grab_data.quantity <= 0:
		grabbing_item.queue_free()
		grabbing_item = null
		revoked_target_inventory = null
		grab_before_position = Vector2i(-1, -1)
	else:
		grabbing_item.update_item_data()
		

func _grab_rotated_item():
	if grabbing_item == null:
		return

	var get_base_size = grabbing_item.item_database.get_item_size()
	if get_base_size.x == get_base_size.y:
		return

	grabbing_item.is_rotated = not grabbing_item.is_rotated

	grab_offset = -Vector2(grabbing_item.item_size) * grabbing_item.item_cell_size * 0.5

func _get_computed_top_left() -> Vector2i:
	if mouse_entered_inventory == null or grabbing_item == null:
		return Vector2i(-1, -1)

	var get_map_local_pos = mouse_entered_inventory.get_local_mouse_position()
	var get_map_index = mouse_entered_inventory.map_index
	
	var get_item_half_size = Vector2(grabbing_item.item_size) * 0.5
	var item_data_size = grabbing_item.item_database.get_item_size(grabbing_item.is_rotated)
	var top_left = get_map_local_pos / mouse_entered_inventory.cell_size - get_item_half_size
	var computed_top_left = Vector2i(round(top_left.x), round(top_left.y))

	if computed_top_left.x < 0 or computed_top_left.y < 0:
		return Vector2i(-1, -1)

	if computed_top_left.x > (get_map_index.x - 1) or computed_top_left.y > (get_map_index.y - 1):
		return Vector2i(-1, -1)

	if (computed_top_left.x + item_data_size.x) > get_map_index.x or (computed_top_left.y + item_data_size.y) > get_map_index.y:
		return Vector2i(-1, -1)

	return computed_top_left

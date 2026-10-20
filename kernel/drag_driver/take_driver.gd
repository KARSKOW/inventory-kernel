extends DragModule

var get_equip_list: Control

var last_drop_item: Vector2i
var last_drop_rotate: bool
var last_drop_origin

var mouse_select_equip

var mouse_entered_inventory: GridInventoryMap

func _ready() -> void:
	_connect_equipment_mouse_entered()

func _process(_delta: float) -> void:
	super._process(_delta)
	if mouse_entered_inventory != null:
		var get_item_selection = mouse_entered_inventory.mouse_selection
		var mouse_entered_inventory_mouse_position = mouse_entered_inventory.get_local_mouse_position()
		var get_item = get_dragging_item()
		
		if Input.is_action_just_pressed("inventory_hold"):
			if is_dragging == false and get_item_selection != null:
				dragging()
			else:
				if get_item != null:
					if mouse_select_equip != null:
						dropped_equip()
					else:
						var top_left = _math_top_left(mouse_entered_inventory_mouse_position, get_item.item_size, get_item.item_cell_size)
						var scan_result = mouse_entered_inventory._scan_item_rect(mouse_entered_inventory_mouse_position, get_item.item_size)
						if mouse_entered_inventory._can_place_on_grid(top_left, get_item.item_size):
							if scan_result.size() == 0:
								dropped()
								
						if scan_result.size() == 1:
							if mouse_entered_inventory._is_within_bounds(mouse_entered_inventory_mouse_position, get_item.item_size):
								if mouse_entered_inventory._is_same_item_name(get_dragging_item(), scan_result[0]):
									is_dragging = mouse_entered_inventory.stacked_item(get_dragging_item(), scan_result[0])
								else:
									exchange(mouse_entered_inventory_mouse_position)
							else:
								revoked()

		if Input.is_action_just_pressed("inventory_rotate"):
			if is_dragging == true:
				if get_dragging_item_rotated() == false:
					rotate_hold_item(true)
				else:
					rotate_hold_item(false)
					
		if Input.is_action_just_pressed("inventory_revoked"):
			if is_dragging == true:
				revoked()
				
		if Input.is_action_just_pressed("inventory_item_half"):
			if get_item_selection != null and is_dragging == false:
				var get_select_compute_quantity = mouse_entered_inventory._drag_half_item(get_item_selection)
				if get_select_compute_quantity < 1:
					return
				create_new_drag_item(
					get_item_selection.item_database,
					get_select_compute_quantity,
					get_item_selection.is_rotated
				)
				last_drop_item = Vector2i(-1, -1)
				
		if is_dragging == true:
			mouse_entered_inventory._preview_gridmap(mouse_entered_inventory_mouse_position, get_dragging_item().item_size)
		else:
			mouse_entered_inventory._preview_gridmap_hide()
			
func dragging():
	if mouse_select_equip == null:
		var get_item_selection = mouse_entered_inventory.mouse_selection
		var top_left = Vector2i(get_item_selection.position / get_item_selection.item_cell_size)
		last_drop_item = top_left
		last_drop_rotate = get_item_selection.is_rotated
		last_drop_origin = null
		mouse_entered_inventory._clean_item_occupy(top_left, get_item_selection.item_size)
	else:
		last_drop_origin = mouse_select_equip
	holding_item(mouse_entered_inventory.mouse_selection)
	printt("last topleft", last_drop_item)
	
func dropped():
	if get_dragging_item() != null:
		var get_item = get_dragging_item()
		var mouse_position = mouse_entered_inventory.get_local_mouse_position()
		var top_left = _math_top_left(mouse_position, get_item.item_size, get_item.item_cell_size)
		mouse_entered_inventory._added_item_occupy(top_left, get_item.item_size, get_item)
		get_item.global_position = Vector2(top_left) * get_item.item_cell_size
		dropped_item(mouse_entered_inventory)
		mouse_entered_inventory.connection_item_selection()
		printt("topleft", top_left)
		
func dropped_equip():
	if mouse_select_equip == null:
		return
	
	var get_dragging_item_type = get_dragging_item().item_database.item_type
	var get_equippment_type = mouse_select_equip.slot_type
	
	if mouse_select_equip.get_child_count() > 0:
		var existing_item = mouse_select_equip.get_child(0)
		if existing_item is GridInventoryItem and (get_dragging_item_type == get_equippment_type):
			var new_spot = mouse_entered_inventory._scan_cells_ract_empty(existing_item.item_size)
			if new_spot != Vector2i(-1, -1):
				existing_item.reparent(mouse_entered_inventory, false)
				existing_item.position = Vector2(new_spot) * existing_item.item_cell_size
				mouse_entered_inventory._added_item_occupy(new_spot, existing_item.item_size, existing_item)
			else:
				mouse_select_equip = null
				revoked()
				return
	
	if get_dragging_item_type == get_equippment_type:
		dropped_item(mouse_select_equip)
	else:
		revoked()

func revoked():
	if get_dragging_item() != null:
		var get_item = get_dragging_item()
		
		if last_drop_origin != null:
			get_item.is_rotated = last_drop_rotate
			get_item.set_rotated()
			dropped_item(last_drop_origin)
		else:
			var top_left = last_drop_item
			if mouse_entered_inventory._get_cells_occupy(last_drop_item, get_item.item_size):
				get_item.global_position = Vector2(top_left) * get_item.item_cell_size
				get_item.is_rotated = last_drop_rotate
				get_item.set_rotated()
				mouse_entered_inventory._added_item_occupy(top_left, get_item.item_size, get_item)
				dropped_item(mouse_entered_inventory)
				mouse_entered_inventory.connection_item_selection()
			else:
				var get_top_left = mouse_entered_inventory._scan_cells_ract_empty(get_item.item_size)
				if get_top_left == Vector2i(-1, -1):
					return
				get_item.global_position = Vector2(get_top_left) * get_item.item_cell_size
				get_item.is_rotated = last_drop_rotate
				get_item.set_rotated()
				mouse_entered_inventory._added_item_occupy(get_top_left, get_item.item_size, get_item)
				dropped_item(mouse_entered_inventory)
				mouse_entered_inventory.connection_item_selection()
	print("REVOKE ITEM")
func exchange(mouse_px):
	var dragged_item = get_dragging_item()
	var target_item = mouse_entered_inventory._scan_item_rect(mouse_px, dragged_item.item_size)[0]
	var target_old_pos = Vector2i(target_item.position / target_item.item_cell_size)
	var drag_top_left = _math_top_left(mouse_px, dragged_item.item_size, dragged_item.item_cell_size)
	
	if target_item != null:
		mouse_entered_inventory._clean_item_occupy(target_old_pos, target_item.item_size)
		mouse_entered_inventory._added_item_occupy(drag_top_left, dragged_item.item_size, dragged_item)
		dragged_item.global_position = Vector2(drag_top_left) * dragged_item.item_cell_size
		
		var new_spot = mouse_entered_inventory._scan_cells_ract_empty(target_item.item_size)
		if new_spot != Vector2i(-1, -1):
			target_item.position = Vector2(new_spot) * target_item.item_cell_size
			mouse_entered_inventory._added_item_occupy(new_spot, target_item.item_size, target_item)
			dropped_item(mouse_entered_inventory)
			mouse_entered_inventory.connection_item_selection()
		else:
			mouse_entered_inventory._clean_item_occupy(drag_top_left, dragged_item.item_size)
			mouse_entered_inventory._added_item_occupy(target_old_pos, target_item.item_size, target_item)
			revoked()


func _connect_equipment_mouse_entered():
	if get_equip_list == null:
		push_warning("NON EQUIP LIST. EQUIP-SLOT ISN'T NOT WORKED.")
		return
	for i in get_equip_list.get_children():
		if i is GridInventoryMap:
			i.mouse_entered_slot.connect(mouse_entered_equip_slot)
			i.mouse_exited_slot.connect(mouse_exited_equip_slot)

func _math_top_left(math_px: Vector2, item_size: Vector2i, cell_size: int) -> Vector2i:
	var math_size = Vector2(item_size) * 0.5
	var math_grid_index = (math_px / cell_size) - math_size
	var math_pos_px = Vector2i(round(math_grid_index.x), round(math_grid_index.y))
	return math_pos_px
	
func mouse_entered_equip_slot(slot):
	mouse_select_equip = slot

func mouse_exited_equip_slot():
	mouse_select_equip = null

func _on_player_inventory_visibility_changed() -> void:
	if get_parent().visible == false:
		revoked()

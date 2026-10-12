@tool
extends PanelContainer

class_name GridInventoryItem

signal mouse_entered_item_rect(rect: Panel)
signal mouse_exited_item_rect()

@export var item_cell_size: int

var item_database: GridInventoryItemData

@export_tool_button("update_size") var button: Callable = _update_size

@export var texture_rect: TextureRect
@export var quantity_text: Label
@export var name_text: Label

var item_size: Vector2i

var quantity: int:
	set(value):
		quantity = value
		_update_item_data()

var is_rotated: bool:
	set(value):
		is_rotated = value
		_update_rotate()

var is_entered: bool 
var is_exited: bool

var item_entered_one_shoot: bool
var item_exited_one_shoot: bool

func _ready() -> void:
	set_name("gridmap_item_1")
	_update_item_data()
	
func set_rotated():
	if item_database == null:
		return
	var read_size = item_database.get_item_size()
	if is_rotated == true:
		item_size = Vector2i(read_size.y, read_size.x)
	else:
		item_size = Vector2i(read_size)
	_update_item_size()
	
	
func _is_mouse_entered_rect() -> bool:
	if Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		return true
	else:
		return false

func _is_item_fulled():
	if item_database != null:
		return item_database.get_stack_size() <= quantity
	return false

func _update_item_data():
	if item_database != null and item_database.data != null:
		if quantity > 1:
			quantity_text.text = str(quantity)
		else:
			quantity_text.text = ""
		
		name_text.text = item_database.get_item_name()
		texture_rect.texture = item_database.get_item_image()
			

func _update_size():
	if Engine.is_editor_hint():
		size = Vector2.ZERO
		size = Vector2(item_cell_size, item_cell_size)
		size.x = size.x * item_size.x
		size.y = size.y * item_size.y

func _update_item_size():
	size = Vector2(item_size) * item_cell_size
	custom_minimum_size = Vector2(item_size) * item_cell_size
	custom_maximum_size = Vector2(item_size) * item_cell_size

func _update_rotate():
	if item_database == null:
		return
	
	if is_rotated == true:
		texture_rect.offset_transform_enabled = true
		texture_rect.offset_transform_rotation = deg_to_rad(90.0)
	else:
		texture_rect.offset_transform_enabled = false
		texture_rect.offset_transform_rotation = 0.0

	set_rotated()
	
	texture_rect.position = Vector2.ZERO

func _on_mouse_entered() -> void:
	mouse_entered_item_rect.emit(self)


func _on_mouse_exited() -> void:
	mouse_exited_item_rect.emit()

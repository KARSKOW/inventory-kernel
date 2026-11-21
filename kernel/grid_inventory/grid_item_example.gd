@tool
@abstract
extends Control

class_name GridItemExample

signal mouse_entered_item_rect(rect: Panel)
signal mouse_exited_item_rect()

@export var item_cell_size: int

@export var quantity_text: Label
@export var name_text: Label


var item_database: GridInventoryItemData:
	set(value):
		item_database = value
		
		queue_redraw()
		update_item_viewport()

var item_size: Vector2i


var is_rotated: bool:
	set(value):
		is_rotated = value
		_update_item_rotate()

var is_entered: bool 
var is_exited: bool

var item_entered_one_shoot: bool
var item_exited_one_shoot: bool

func _ready() -> void:
	set_name("gridmap_item_1")

func _draw() -> void:
	draw_texture_rect(
		item_database.get_item_image(), 
		Rect2(Vector2.ZERO, Vector2(item_database.get_item_size() * item_cell_size)),
		false,
		Color(1, 1, 1, 1),
		is_rotated
		)
	
func update_item_viewport():
	if item_database != null and item_database.data != null:
		if item_database.quantity > 1:
			quantity_text.text = str(item_database.quantity)
		else:
			quantity_text.text = ""
		
		name_text.text = item_database.get_item_name()


func _update_item_size():
	size = Vector2(item_size) * item_cell_size
	custom_minimum_size = Vector2(item_size) * item_cell_size
	custom_maximum_size = Vector2(item_size) * item_cell_size

func _update_item_rotate():
	if item_database == null:
		return
		
	var read_size = item_database.get_item_size()
	if is_rotated == true:
		item_size = Vector2i(read_size.y, read_size.x)
	else:
		item_size = Vector2i(read_size)
	_update_item_size()

func _on_mouse_entered() -> void:
	mouse_entered_item_rect.emit(self)


func _on_mouse_exited() -> void:
	mouse_exited_item_rect.emit()

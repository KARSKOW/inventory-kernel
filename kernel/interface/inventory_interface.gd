extends CanvasLayer

const GrabService = preload("uid://cdpum4qhf7ycg")

const smooth_offset: float = 0.5

# 抓取模式：0 = Drag（拖拽），1 = Take（拿起），对应项目设置中的枚举
var grab_action: int

var is_grabbing: bool


var mouse_entered_inventory: GridInventoryMap:
	set(value):
		mouse_entered_inventory = value
		
		#if mouse_entered_inventory != null:
			#if mouse_entered_inventory.gui_input.is_connected(_grab_input):
				#return
			#mouse_entered_inventory.gui_input.connect(_grab_input)
			

var inventory_gui_input: InputEvent

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


var drag_server

func _ready() -> void:
	_get_config()


func _input(event: InputEvent):
	if _mouse_trigger(event, MOUSE_BUTTON_LEFT):
		drag_server.grab_and_drop_item()
		
	if _mouse_trigger(event, MOUSE_BUTTON_RIGHT):
		drag_server.grab_revoked_item()
		
	if _keyboard_trigger(event, "grab_half"):
		drag_server.grab_half_item()
		
	if _keyboard_trigger(event, "grab_rotate"):
		drag_server.grab_rotated_item()

func _process(_delta: float) -> void:
	if grabbing_item == null:
		return

	grabbing_item.global_position = grabbing_item.get_global_mouse_position() + grab_offset
	
func _get_config() -> void:
	grab_action = int(ProjectSettings.get_setting("inventory-kernel/mouse_grab_action", 1))
	drag_server = GrabService.new()

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

extends CanvasLayer

signal is_item_out_of_bounds(get_grabbing_item)

const GrabService = preload("uid://cdpum4qhf7ycg")

const smooth_offset: float = 0.5

# 抓取模式：0 = Drag（拖拽），1 = Take（拿起），对应项目设置中的枚举
var grab_action: int

var is_grabbing: bool


var get_inventory_gui: GridInventoryMap:
	set(value):
		get_inventory_gui = value
		
		if get_inventory_gui != null:
			if get_inventory_gui._is_entered_trigger.is_connected(_gui_grab_input):
				return
			get_inventory_gui._is_entered_trigger.connect(_gui_grab_input)
			

var inventory_gui_input: InputEvent

var cancel_target_inventory: GridInventoryMap
var cancel_rotated: bool
var cancel_source_item: GridItemExample

var grabbing_item: GridItemExample:
	set(value):
		grabbing_item = value
		if grabbing_item != null:
			is_grabbing = true
		else:
			is_grabbing = false

var grab_offset: Vector2
var grab_before_position: Vector2i = Vector2i(-1, -1)


var drag_server: GrabService

func _ready() -> void:
	_get_config()

func _gui_grab_input(event: InputEvent, tar_kernel) -> void:
	if tar_kernel != get_inventory_gui:
		return
	
	if _input_event_trigger(event, "interface_grab_and_drop_item"):
		drag_server.grab_and_drop_item()

func _input(event: InputEvent) -> void:
	if _input_event_trigger(event, "interface_cancel_item"):
		drag_server.grabbing_cancel()
		
	if _input_event_trigger(event, "interface_grabbing_half_item"):
		drag_server.grab_half_item()
		
	if _input_event_trigger(event, "interface_grabbing_rotated_item"):
		drag_server.grab_rotated_item()

func _process(_delta: float) -> void:
	if grabbing_item == null:
		return

	grabbing_item.global_position = grabbing_item.get_global_mouse_position() + grab_offset
	
func _get_config() -> void:
	grab_action = int(ProjectSettings.get_setting("inventory-kernel/mouse_grab_action", 1))
	drag_server = GrabService.new()

func _input_event_trigger(event: InputEvent, input_name: String) -> bool:
	if event.is_action_pressed(input_name):
		return true
	return false

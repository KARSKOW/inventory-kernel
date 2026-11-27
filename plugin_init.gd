@tool
extends EditorPlugin

const inventory_tools = preload("uid://crladll77hhap")

const set_plugin_settings := {
	"inventory-kernel/mouse_grab_action": {
		"value": 1,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Drag,Take",
	},
	# 用 int 枚举保存鼠标键，枚举索引与 MOUSE_BUTTON_* 的值一一对应（None=0, Left=1, Right=2, Middle=3）。
	# 相比保存整个 InputEvent 对象，默认值合法、不会出现 button_index=0 或类型转换错误。
	"inventory-kernel/mouse_grab_button": {
		"value": MOUSE_BUTTON_LEFT,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "None,Left,Right,Middle",
	},
}

var set_plugin_input = [
	"input/interface_grab_and_drop_item",
	"input/interface_cancel_item",
	"input/interface_grabbing_half_item",
	"input/interface_grabbing_rotated_item"
]

var input_event_example = {
	"deadzone": 0.2,
	"events": []
}


var driver_theme: Control


func _enter_tree() -> void:
	driver_theme = inventory_tools.instantiate()
	driver_theme.name = "InventoryKernelScreen"
	driver_theme.size_flags_vertical = Control.SIZE_EXPAND_FILL
	driver_theme.hide()
	
	
	EditorInterface.get_editor_main_screen().add_child(driver_theme)

	
	for input_setting in set_plugin_settings:
		if not ProjectSettings.has_setting(input_setting):
			ProjectSettings.set_setting(input_setting, input_event_example)
			

	InputMap.load_from_project_settings()
	_init_settings()


func _exit_tree() -> void:
	if is_instance_valid(driver_theme):
		driver_theme.queue_free()
		driver_theme = null


func _enable_plugin() -> void:
	add_autoload_singleton("InventoryInterface", "res://addons/inventorykernel/kernel/interface/inventory_interface.gd")

	ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton("InventoryInterface")
	
	_clear_settings()
	ProjectSettings.save()


func _clear_settings():
	for key in set_plugin_settings:
		ProjectSettings.clear(key)
		
	for input_key in set_plugin_input:
		ProjectSettings.clear(input_key)



func _init_settings() -> void:
	for key in set_plugin_settings:
		var data: Dictionary = set_plugin_settings[key]
		# 不覆盖用户已经保存过的值
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, data["value"])
		
		ProjectSettings.add_property_info({
			"name": key,
			"type": data["type"],
			"hint": data["hint"],
			"hint_string": data["hint_string"],
		})


func _make_visible(visible: bool) -> void:
	if is_instance_valid(driver_theme):
		driver_theme.visible = visible
		if visible:
			var data_creater := driver_theme.get_node_or_null("theme/TabContainer/ItemData")
			if data_creater != null and data_creater.has_method("refresh_resource_selecter"):
				data_creater.refresh_resource_selecter()


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Inventory-Kernel"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Grid", "EditorIcons")

@tool
extends EditorPlugin

const inventory_tools = preload("uid://crladll77hhap")

var _welcome_screen: Control


func _enter_tree() -> void:
	_welcome_screen = inventory_tools.instantiate()
	_welcome_screen.name = "InventoryKernelScreen"
	_welcome_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(_welcome_screen)
	_welcome_screen.hide()


func _exit_tree() -> void:
	if is_instance_valid(_welcome_screen):
		_welcome_screen.queue_free()
		_welcome_screen = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_welcome_screen):
		_welcome_screen.visible = visible
		if visible:
			var data_creater := _welcome_screen.get_node_or_null("MES/TabContainer/Data-Creator")
			if data_creater != null and data_creater.has_method("refresh_resource_selecter"):
				data_creater.refresh_resource_selecter()


func _get_plugin_name() -> String:
	return "Inventory-Kernel"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Grid", "EditorIcons")

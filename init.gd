@tool
extends EditorPlugin

const inventory_tools = preload("uid://crladll77hhap")

var driver_theme: Control


func _enter_tree() -> void:
	driver_theme = inventory_tools.instantiate()
	driver_theme.name = "InventoryKernelScreen"
	driver_theme.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(driver_theme)
	driver_theme.hide()


func _exit_tree() -> void:
	if is_instance_valid(driver_theme):
		driver_theme.queue_free()
		driver_theme = null


func _enable_plugin() -> void:
	pass



func _make_visible(visible: bool) -> void:
	if is_instance_valid(driver_theme):
		driver_theme.visible = visible
		if visible:
			var data_creater := driver_theme.get_node_or_null("MES/TabContainer/Data-Creator")
			if data_creater != null and data_creater.has_method("refresh_resource_selecter"):
				data_creater.refresh_resource_selecter()


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Inventory-Kernel"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Grid", "EditorIcons")

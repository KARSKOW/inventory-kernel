@tool
extends TabBar

@onready var variant_list: VBoxContainer = $VBoxContainer/variant_list/VBoxContainer
@onready var resource_selecter: EditorResourcePicker = $VBoxContainer/resource_selecter
@onready var editor_file_dialog: EditorFileDialog = $VBoxContainer/HBoxContainer/EditorFileDialog

const VARIANT_IMAGE = preload("uid://bjn7nrwx2a2p3")
const VARIANT_STRING = preload("uid://bng6tkywrl1gc")
const VARIANT_VEC_2_INT = preload("uid://bi807ijemasdr")
const VARIANT_INT = preload("uid://co0wntcy40css")

var selecter_resource

func refresh_resource_selecter() -> void:
	if not is_node_ready():
		return

	var trash_selector := resource_selecter
	var trash_selector_parent := trash_selector.get_parent()
	var trash_selector_index := trash_selector.get_index()
	var new_selector := EditorResourcePicker.new()
	
	new_selector.base_type = trash_selector.base_type
	new_selector.edited_resource = trash_selector.edited_resource
	new_selector.resource_changed.connect(_on_resource_changed)
	new_selector.name = "resource_selecter"
	
	trash_selector.name += "trash_selector"
	trash_selector_parent.add_child(new_selector)
	trash_selector_parent.move_child(new_selector, trash_selector_index)
	trash_selector.queue_free()
	
	resource_selecter = new_selector

func get_item_resource_list(resource: Resource) -> Array[Dictionary]:
	var output_result: Array[Dictionary] = []
	var get_resource_script := resource.get_script()
	if get_resource_script == null:
		return []

	for i_variant in get_resource_script.get_script_property_list():
		if i_variant.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			output_result.append(i_variant)
	return output_result

func get_tools_all_variant() -> Dictionary:
	var dict = {}
	for i in variant_list.get_children():
		dict[i.get_variant_text()] = i.get_variant_property()
		
	return dict

func _clean_all_variant():
	for i in variant_list.get_children():
		variant_list.remove_child(i)
		i.queue_free()

func _on_resource_changed(resource) -> void:
	_clean_all_variant()
		
	if resource == null:
		selecter_resource = null
		return

	selecter_resource = resource

	for i in get_item_resource_list(resource):
		if i.get("hint_string") == "Texture2D":
			var texture = VARIANT_IMAGE.instantiate()
			variant_list.add_child(texture)
			texture.set_variant_text(i.get("name"))
		
		match i.get("type"):
			TYPE_VECTOR2I:
				var i_vector2 = VARIANT_VEC_2_INT.instantiate()
				variant_list.add_child(i_vector2)
				i_vector2.set_variant_text(i.get("name"))
				i_vector2.set_variant_property(selecter_resource.get(i.get("name")))
		
			TYPE_STRING:
				var i_string = VARIANT_STRING.instantiate()
				variant_list.add_child(i_string)
				i_string.set_variant_text(i.get("name"))
				i_string.set_variant_property(selecter_resource.get(i.get("name")))
				
			TYPE_INT:
				var i_int = VARIANT_INT.instantiate()
				variant_list.add_child(i_int)
				i_int.set_variant_text(i.get("name"))
				i_int.set_variant_property(selecter_resource.get(i.get("name")))
		
	#print(get_item_resource_list(resource))

func _on_save_button_pressed() -> void:
	if selecter_resource == null:
		print_rich("[color=yellow]","[savfile] NIL return: You must select resource template.")
		return
	editor_file_dialog.current_file = get_tools_all_variant()["item_name"] + ".tres"
	editor_file_dialog.popup_file_dialog()


func _on_editor_dialog_file_selected(path: String) -> void:
	if selecter_resource == null:
		print_rich("[color=yellow]","[savfile] NIL return: You must select resource template.")
		return

	var new_item_data: Resource = selecter_resource.duplicate()
	var variant_values := get_tools_all_variant()

	for property_name in variant_values:
		new_item_data.set(property_name, variant_values[property_name])
		printt("[savefile]", "name:", property_name, "property:", variant_values[property_name])
	print("[done] \n")

	new_item_data.take_over_path(path)

	var save_item_data = ResourceSaver.save(new_item_data, path)

	if save_item_data != OK:
		push_error(save_item_data)
		return

	EditorInterface.get_resource_filesystem().scan()

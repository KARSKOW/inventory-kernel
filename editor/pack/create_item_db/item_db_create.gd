@tool
extends TabBar

@onready var candidate_item_list: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var editor_file_dialog: EditorFileDialog = $EditorFileDialog
@onready var itemdb_res: EditorResourcePicker = $VBoxContainer/itemdb_res

@onready var create_db_button: Button = $VBoxContainer/HBoxContainer/create_db
@onready var rebuild_db_button: Button = $VBoxContainer/HBoxContainer/rebuild_db
@onready var join_item_button: Button = $VBoxContainer/HBoxContainer/join_item

const UI_CANDIDATE_ITEM = preload("uid://de1hijm6rdeev")

var file_path: String = "":
	set(value):
		file_path = value

var selected_resource: ItemDB:
	set(value):
		selected_resource = value
		_set_itemdb()

func _ready() -> void:
	editor_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_set_itemdb()
	join_item_button.visible = false

func _set_itemdb():
	if selected_resource == null:
		create_db_button.visible = true
		rebuild_db_button.visible = false
		return
	create_db_button.visible = false
	rebuild_db_button.visible = true
	join_item_button.visible = true

func _read_candidate_list():
	if selected_resource != null:
		for i in selected_resource.item_library.values():
			var set_candidate_item = UI_CANDIDATE_ITEM.instantiate()
			candidate_item_list.add_child(set_candidate_item)
			set_candidate_item.set_resource(i)
			
func _clean_candidate_list():
	if candidate_item_list.get_children().is_empty():
		return
	
	for i in candidate_item_list.get_children():
		i.queue_free()

func _create_new_file():
	var create_db = ItemDB.new()
	var library: Dictionary = {}
	for i in candidate_item_list.get_children():
		if i.picker_resource == null:
			printt("[creating-db]", "No resource.", "[ SKIP ]")
		else:
			if library.has(i.picker_resource.item_name):
				i.is_mark_skip = true
				printt("[creating-db]", i.picker_resource.item_name, "[ SKIP ]")
			else:
				library[i.picker_resource.item_name] = i.picker_resource
				printt("[creating-db]", i.picker_resource.item_name)

	if file_path.is_empty():
		push_error("[creating-db] No save path selected.")
		return

	create_db.item_library = library

	var save_db := ResourceSaver.save(create_db, file_path)
	if save_db != OK:
		push_error("[creating-db] Failed to save '%s': %s (%d)" % [file_path, error_string(save_db), save_db])
		return
		
	EditorInterface.get_resource_filesystem().scan()
	print("[done]")
	
func _overwrite_file():
	if selected_resource == null:
		push_error("[rebuild-db] No ItemDB selected.")
		return
	
	var copy_library = selected_resource.item_library.duplicate()
	var new_library: Dictionary = {}
	for i in candidate_item_list.get_children():
		if i.picker_resource == null:
			i.is_mark_repeat = false
			printt("[rebuild-db]", "No resource.", "[ SKIP ]")
		else:
			if copy_library.has(i.picker_resource.item_name):
				i.is_mark_repeat = true
				new_library[i.picker_resource.item_name] = i.picker_resource
				printt("[rebuild-db]", i.picker_resource.item_name, "[ REPEAT ]")
			else:
				new_library[i.picker_resource.item_name] = i.picker_resource
				printt("[rebuild-db]", i.picker_resource.item_name)

	selected_resource.item_library = new_library

	var path := selected_resource.resource_path
	if path.is_empty():
		path = file_path
	if path.is_empty():
		push_error("[rebuild-db] No save path selected.")
		return

	var save_db := ResourceSaver.save(selected_resource, path)
	if save_db != OK:
		push_error("[rebuild-db] Failed to save '%s': %s (%d)" % [path, error_string(save_db), save_db])
		return
		
	EditorInterface.get_resource_filesystem().scan()
	print("[done]")


func _on_create_db_pressed() -> void:

	editor_file_dialog.popup_file_dialog()
	

func _on_rebuild_db_pressed() -> void:
	_overwrite_file()
	

func _on_join_item_pressed() -> void:
	var set_candidate_item = UI_CANDIDATE_ITEM.instantiate()
	candidate_item_list.add_child(set_candidate_item)

func _on_editor_file_selected(path: String) -> void:
	file_path = path
	_create_new_file()
	itemdb_res.edited_resource = load(path)
	selected_resource = load(path)
	printt("[creating-db]", "Saved:", file_path)


func _on_itemdb_resource_selected(resource: Resource) -> void:
	if resource == null:
		join_item_button.visible = false
		selected_resource = null
		_clean_candidate_list()
		return
	selected_resource = resource
	_read_candidate_list()

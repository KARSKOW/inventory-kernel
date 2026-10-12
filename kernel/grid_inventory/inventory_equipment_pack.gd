extends PanelContainer

class_name GridInventorySlot

signal mouse_entered_slot(slot)
signal mouse_exited_slot()

signal weapons_equip_status(data: GridInventoryItemData)

@export var slot_type: String

var slot_equiped_item: GridInventoryItem
var before_size_px: Vector2


func _ready() -> void:
	before_size_px = self.custom_minimum_size


func get_equipment_item() -> GridInventoryItem:
	if slot_equiped_item != null:
		return slot_equiped_item
	
	return null

func get_equipment_data() -> GridInventoryItemData:
	if slot_equiped_item != null:
		return slot_equiped_item.item_database
	return null

func clear_equipment_item() -> void:
	if get_child_count() <= 0:
		return
	get_child(-1).queue_free()

func _on_mouse_entered() -> void:
	mouse_entered_slot.emit(self)


func _on_mouse_exited() -> void:
	mouse_exited_slot.emit()


func _on_child_entered_tree(node: Node) -> void:
	if node is GridInventoryItem:
		slot_equiped_item = node
		weapons_equip_status.emit(node.item_database)
		self.custom_minimum_size = node.size

func _on_child_exiting_tree(_node: Node) -> void:
	slot_equiped_item = null
	weapons_equip_status.emit(null)
	self.custom_minimum_size = before_size_px

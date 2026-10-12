extends ColorRect

class_name GridInventorySelectionRect
func set_selection_rect(item_size: Vector2) -> void:
	size = item_size
	
func set_selection_position(px: Vector2):
	position = px

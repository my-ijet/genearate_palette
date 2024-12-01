extends ColorPicker

@onready var texture_rect: TextureRect = $"../TextureRect"
@onready var img: Image = texture_rect.img

func _physics_process(_delta: float) -> void:
	await get_tree().create_timer(.750).timeout
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var local_position := texture_rect.get_local_mouse_position()
		var rect_size := texture_rect.get_size()
		var img_size := Vector2(img.get_size())
		var ratio := rect_size / img_size
		var pixel_coord := local_position / ratio
		
		if pixel_coord.x >= img_size.x or pixel_coord.x < 0: return
		if pixel_coord.y >= img_size.y or pixel_coord.y < 0: return
		self.color = img.get_pixelv(pixel_coord)

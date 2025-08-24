extends TextureRect

@export var img: Image

@onready var home_path := OS.get_environment("USERPROFILE") if OS.has_feature("windows") else OS.get_environment("HOME")
@onready var path_line: LineEdit = $"../path_line"
@onready var image_name_line: LineEdit = $"../image_name_line"

@onready var hue_slider: HSlider = $"../hue_slider"
@onready var hue_slider_label: Label = $"../hue_slider/Label"
@onready var lights_slider: HSlider = $"../lights_slider"
@onready var lights_slider_label: Label = $"../lights_slider/Label"
@onready var saturation: HSlider = $'../saturation'
@onready var saturation_label: Label = $"../saturation/Label"
@onready var overlay_lightness: HSlider = $"../overlay_lightness"
@onready var overlay_lightness_label: Label = $"../overlay_lightness/Label"
@onready var overlay_on: CheckBox = $"../overlay_on"

@onready var hue_slider_label_text := hue_slider_label.text
@onready var lights_slider_label_text := lights_slider_label.text
@onready var saturation_label_text := saturation_label.text
@onready var overlay_lightness_label_text := overlay_lightness_label.text

var num_hues := 12
var num_lights := 9

var gray_v: PackedFloat64Array = []
var gray_reversed_v: PackedFloat64Array = []

var hue_v: PackedFloat64Array = []
var light_v: PackedFloat64Array = []


func _ready() -> void:
	path_line.text = home_path
	
	img = Image.create(num_lights * 2, num_hues, false, Image.FORMAT_RGB8)
	gen_values(); gen_image()

	hue_slider_label.text = hue_slider_label_text % num_hues
	lights_slider_label.text = lights_slider_label_text % num_lights
	saturation_label.text = saturation_label_text % saturation.value
	overlay_lightness_label.text = overlay_lightness_label_text % overlay_lightness.value

func resize_img(): img.resize(num_lights * 2, num_hues)

func gen_values():
	gray_v.clear(); hue_v.clear(); light_v.clear();
	
	gray_v.append(1)
	for x in range(1, num_lights):
		gray_v.append(1 - (x * (1.0 / (num_lights - 1))))
	gray_reversed_v = gray_v.duplicate()
	gray_reversed_v.reverse()
	gray_reversed_v[0] = 0.05
	gray_reversed_v[-1] = 0.95
	
	for y in range(0, num_hues):
		hue_v.append(1.0 / 12 + y * (1.0 / num_hues))
	
	for x in range(1, num_lights + 1):
		light_v.append(x * (1.0 / (num_lights + 1)))

func gen_image():
	var col: Color
	var col_overlay: Color
	var x_local: int
	
	for x in range(0, num_lights * 2):
		for y in range(0, num_hues):
			x_local = x % num_lights
			if x < num_lights:
				col = Color.from_ok_hsl(0, 0, gray_v[x_local])
			else:
				if x_local == num_lights: continue
				if overlay_on.button_pressed:
					# overlay blend mode in righ side
					col = Color.from_ok_hsl(0, 0, gray_reversed_v[x_local])
					col_overlay = Color.from_ok_hsl(hue_v[y], saturation.value, overlay_lightness.value)
					col = blend_overlay(col, col_overlay)
				else:
					col = Color.from_ok_hsl(hue_v[y], saturation.value, gray_reversed_v[x_local])
			img.set_pixel(x, y, col)
	
	self.texture = ImageTexture.create_from_image(img)

func blend_overlay(a: Color, b: Color) -> Color:
	var c := Color()
	if a.r < 0.5: c.r = 2 * a.r * b.r
	else: c.r = 1 - 2 * (1 - a.r) * (1 - b.r)
	if a.g < 0.5: c.g = 2 * a.g * b.g
	else: c.g = 1 - 2 * (1 - a.g) * (1 - b.g)
	if a.b < 0.5: c.b = 2 * a.b * b.b
	else: c.b = 1 - 2 * (1 - a.b) * (1 - b.b)
	
	return c


func _on_saturation_value_changed(_value: float) -> void:
	gen_image()
	saturation_label.text = saturation_label_text % saturation.value

func _on_overlay_lightness_value_changed(_value: float) -> void:
	gen_image()
	overlay_lightness_label.text = overlay_lightness_label_text % overlay_lightness.value

func _on_overlay_on_toggled(_toggled_on: bool) -> void:
	gen_image()

func _on_hue_slider_value_changed(value: float) -> void:
	var v := 3
	for x in range(1, roundi(value)): v += v
	num_hues = v
	resize_img(); gen_values(); gen_image()
	hue_slider_label.text = hue_slider_label_text % num_hues

func _on_lightness_slider_value_changed(value: float) -> void:
	var v := 2
	for x in range(1, roundi(value)): v += v - 1
	num_lights = v
	resize_img(); gen_values(); gen_image()
	lights_slider_label.text = lights_slider_label_text % num_lights


func _on_save_image_pressed() -> void:
	# Ensure the directory exists
	var path := path_line.text
	var d := DirAccess.open('res://')
	if not d.dir_exists(path):
		d.make_dir_recursive(path)
	
	var image_name := image_name_line.text
	if image_name == '': image_name = 'img'
	image_name = image_name.trim_suffix('.png')
	image_name = image_name.validate_filename()
	image_name_line.text = image_name
	
	var file_path_to_save = path + '/' + image_name + '.png'
	img.save_png(file_path_to_save)


func _on_edit_path_pressed() -> void:
	var dlg = FileDialog.new()
	self.add_child(dlg)
	dlg.access = FileDialog.ACCESS_FILESYSTEM
	dlg.current_dir = path_line.text
	dlg.current_file = image_name_line.text
	dlg.add_filter('*.png')
	dlg.set_size(Vector2(640, 512))
	dlg.popup_centered()
	await dlg.file_selected
	path_line.text = dlg.current_dir
	image_name_line.text = dlg.current_file.trim_suffix('.png')

extends Control

const SLIDE_DURATION := 0.35
const DISPLAY_DURATION := 3.0
const POPUP_W := 300
const POPUP_H := 72
const MARGIN := 14

var _callback: Callable
var _tween: Tween

@onready var _panel: PanelContainer = $PanelContainer
@onready var _icon: TextureRect = $PanelContainer/MarginContainer/HBox/Icon
@onready var _header: Label = $PanelContainer/MarginContainer/HBox/VBox/Header
@onready var _title: Label = $PanelContainer/MarginContainer/HBox/VBox/Title
@onready var _desc: Label = $PanelContainer/MarginContainer/HBox/VBox/Desc

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func show_achievement(data: Dictionary, callback: Callable) -> void:
	_callback = callback
	_header.text = "Achievement Unlocked!"
	_title.text = data.get("name", "Unknown")
	_desc.text = data.get("description", "")

	var icon_path: String = data.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_icon.texture = load(icon_path)
		_icon.show()
	else:
		_icon.hide()

	var vp_size := get_viewport_rect().size
	var off_x := -POPUP_W - MARGIN
	var on_x := float(MARGIN)
	var pos_y := vp_size.y - POPUP_H - MARGIN

	_panel.size = Vector2(POPUP_W, POPUP_H)
	_panel.position = Vector2(off_x, pos_y)
	show()

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "position:x", on_x, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(DISPLAY_DURATION)
	_tween.tween_property(_panel, "position:x", float(off_x), SLIDE_DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish)

func _finish() -> void:
	hide()
	if _callback.is_valid():
		_callback.call()

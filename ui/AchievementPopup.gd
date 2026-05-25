extends CanvasLayer

@onready var panel: PanelContainer = $AchievementPopup/PanelContainer
@onready var icon: TextureRect = $AchievementPopup/PanelContainer/MarginContainer/HBox/Icon
@onready var title: Label = $AchievementPopup/PanelContainer/MarginContainer/HBox/VBox/Title
@onready var desc: Label = $AchievementPopup/PanelContainer/MarginContainer/HBox/VBox/Desc

const POPUP_TIME := 3.0
const ANIM_TIME := 0.25
const MARGIN := 16

var done_callback: Callable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	get_viewport().size_changed.connect(_on_resize)


func show_achievement(data: Dictionary, callback: Callable) -> void:
	done_callback = callback

	title.text = data.get("name", "Achievement")
	desc.text = data.get("description", "")

	var icon_path: String = data.get("icon", "")

	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		icon.texture = null

	await get_tree().process_frame

	var popup_size: Vector2 = panel.size

	if popup_size.x < 100:
		popup_size = Vector2(300, 72)

	var target: Vector2 = _get_target_pos(popup_size)

	panel.position = Vector2(
		-popup_size.x - 20,
		target.y
	)

	visible = true

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		panel,
		"position",
		target,
		ANIM_TIME
	)

	await get_tree().create_timer(
		POPUP_TIME
	).timeout

	tween = create_tween()

	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		panel,
		"position",
		Vector2(
			-popup_size.x - 20,
			target.y
		),
		ANIM_TIME
	)

	await tween.finished

	visible = false

	if done_callback.is_valid():
		done_callback.call()


func _get_target_pos(size: Vector2) -> Vector2:
	var viewport: Vector2 = get_viewport().get_visible_rect().size

	return Vector2(
		MARGIN,
		viewport.y - size.y - MARGIN
	)


func _on_resize() -> void:
	if visible:
		panel.position = _get_target_pos(panel.size)

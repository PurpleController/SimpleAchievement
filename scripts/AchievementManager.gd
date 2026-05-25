extends Node

const SAVE_PATH := "user://achievements.save"
const ACHIEVEMENTS_PATH := "res://addons/SimpleAchievement/achievements.json"

var achievements: Dictionary = {}
var unlocked: Dictionary = {}
var progress: Dictionary = {}

var _queue: Array[String] = []
var _showing := false
var _popup: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_achievements()
	_load_data()
	_create_popup()


func register(
	id: String,
	name: String,
	description: String,
	icon := "",
	required: int = 1
):
	achievements[id] = {
		"id": id,
		"name": name,
		"description": description,
		"icon": icon,
		"required": required
	}


func unlock(id: String):

	if unlocked.has(id):
		return

	if not achievements.has(id):
		push_warning("Achievement '%s' not registered" % id)
		return

	unlocked[id] = true

	_save_data()

	_queue.append(id)

	if not _showing:
		_show_next()


func unlockachievement(id: String):
	unlock(id)


func progressachievement(
	id: String,
	add_amount: int
):

	if unlocked.has(id):
		return

	if not achievements.has(id):
		push_warning("Achievement '%s' not registered" % id)
		return

	var required: int = int(
		achievements[id].get(
			"required",
			1
		)
	)

	var current: int = int(
		progress.get(
			id,
			0
		)
	)

	current += add_amount

	progress[id] = current

	_save_data()

	if current >= required:
		unlock(id)


func getachievementprogress(
	id: String
) -> int:

	return int(
		progress.get(
			id,
			0
		)
	)


func is_unlocked(
	id: String
) -> bool:

	return unlocked.has(id)


func getall() -> Dictionary:

	var result: Dictionary = {}

	for id in achievements:

		result[id] = achievements[id].duplicate()

		result[id]["goal"] = int(
			achievements[id].get(
				"required",
				1
			)
		)

	return result


func getsavedata() -> Dictionary:

	var result: Dictionary = {}

	for id in achievements:

		result[id] = {
			"unlocked": unlocked.has(id),
			"progress": int(
				progress.get(
					id,
					0
				)
			)
		}

	return result


func reset():

	unlocked.clear()
	progress.clear()

	_save_data()


func _show_next():

	if _queue.is_empty():
		_showing = false
		return

	_showing = true

	var id: String = _queue.pop_front()

	if not is_instance_valid(_popup):
		_create_popup()

	_popup.show_achievement(
		achievements[id],
		Callable(
			self,
			"_popup_finished"
		)
	)


func _popup_finished():

	_show_next()


func _create_popup():

	if is_instance_valid(_popup):
		return

	var popup_scene = preload(
		"res://addons/SimpleAchievement/ui/AchievementPopup.tscn"
	)

	_popup = popup_scene.instantiate()

	get_tree().root.call_deferred(
		"add_child",
		_popup
	)

	_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	_popup.visible = false


func _load_achievements():

	if not FileAccess.file_exists(
		ACHIEVEMENTS_PATH
	):
		return

	var file = FileAccess.open(
		ACHIEVEMENTS_PATH,
		FileAccess.READ
	)

	if file == null:
		return

	var text: String = file.get_as_text()

	file.close()

	var json := JSON.new()

	if json.parse(text) != OK:
		return

	var data = json.data

	if data is Array:

		for achievement in data:

			register(

				str(
					achievement.get(
						"id",
						""
					)
				),

				str(
					achievement.get(
						"name",
						"Achievement"
					)
				),

				str(
					achievement.get(
						"description",
						""
					)
				),

				str(
					achievement.get(
						"icon",
						""
					)
				),

				int(
					achievement.get(
						"goal",
						1
					)
				)

			)


func _save_data():

	var file = FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		return

	file.store_var(
		{
			"unlocked": unlocked,
			"progress": progress
		}
	)

	file.close()


func _load_data():

	if not FileAccess.file_exists(
		SAVE_PATH
	):
		return

	var file = FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		return

	var data = file.get_var()

	if data is Dictionary:

		unlocked = data.get(
			"unlocked",
			{}
		)

		progress = data.get(
			"progress",
			{}
		)

	file.close()

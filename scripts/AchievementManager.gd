extends Node

const SAVE_PATH := "user://achievements.cfg"
const JSON_PATH := "res://addons/SimpleAchievement/achievements.json"
const POPUP_SCENE := "res://addons/SimpleAchievement/ui/AchievementPopup.tscn"

var _achievements: Dictionary = {}
var _save_data: Dictionary = {}
var _popup_queue: Array = []
var _popup_showing: bool = false
var _popup: Control = null

signal achievement_unlocked(id: String)
signal achievement_progress(id: String, current: int, goal: int)

func _ready() -> void:
	_load_achievements()
	_load_save()
	_create_popup()

func _load_achievements() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		push_warning("SimpleAchievement: achievements.json not found at " + JSON_PATH)
		return
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("SimpleAchievement: Failed to parse achievements.json")
		return
	for entry in json.get_data():
		_achievements[entry["id"]] = entry

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()
	if data is Dictionary:
		_save_data = data

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(_save_data)
	file.close()

## Unlock an achievement instantly
## Usage: AchievementManager.unlockachievement("my_id")
func unlockachievement(id: String) -> void:
	if not _achievements.has(id):
		push_warning("SimpleAchievement: Achievement '%s' not found." % id)
		return
	if isunlocked(id):
		return
	if not _save_data.has(id):
		_save_data[id] = {}
	_save_data[id]["unlocked"] = true
	_save_data[id]["progress"] = _achievements[id].get("goal", 1)
	_save()
	achievement_unlocked.emit(id)
	_queue_popup(id)

## Add progress to a tracked achievement
## Usage: AchievementManager.progressachievement("my_id", 1)
func progressachievement(id: String, amount: int = 1) -> void:
	if not _achievements.has(id):
		push_warning("SimpleAchievement: Achievement '%s' not found." % id)
		return
	if isunlocked(id):
		return
	var goal: int = _achievements[id].get("goal", 1)
	var current: int = getprogress(id)
	var new_progress := mini(current + amount, goal)
	if not _save_data.has(id):
		_save_data[id] = {}
	_save_data[id]["progress"] = new_progress
	achievement_progress.emit(id, new_progress, goal)
	if new_progress >= goal:
		_save_data[id]["unlocked"] = true
		_save()
		achievement_unlocked.emit(id)
		_queue_popup(id)
	else:
		_save()

func isunlocked(id: String) -> bool:
	return _save_data.get(id, {}).get("unlocked", false)

func getprogress(id: String) -> int:
	return _save_data.get(id, {}).get("progress", 0)

func getall() -> Dictionary:
	return _achievements

func getsavedata() -> Dictionary:
	return _save_data

func reset() -> void:
	_save_data = {}
	_save()

func _create_popup() -> void:
	if not ResourceLoader.exists(POPUP_SCENE):
		push_error("SimpleAchievement: AchievementPopup.tscn not found!")
		return
	_popup = load(POPUP_SCENE).instantiate()
	_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.call_deferred("add_child", _popup)

func _queue_popup(id: String) -> void:
	_popup_queue.append(id)
	if not _popup_showing:
		_show_next_popup()

func _show_next_popup() -> void:
	if _popup_queue.is_empty():
		_popup_showing = false
		return
	_popup_showing = true
	var id: String = _popup_queue.pop_front()
	_popup.show_achievement(_achievements[id], _on_popup_done)

func _on_popup_done() -> void:
	_show_next_popup()

@tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	var DockScript = preload("res://addons/github_classroom/github_classroom_dock.gd")
	dock = DockScript.new()
	dock.name = "GitHubClassroom"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree() -> void:
	remove_control_from_docks(dock)
	if dock:
		dock.queue_free()
		dock = null

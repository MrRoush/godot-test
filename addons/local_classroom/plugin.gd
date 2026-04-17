@tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	var DockScript = preload("res://addons/local_classroom/local_classroom_dock.gd")
	dock = DockScript.new()
	dock.name = "Local Classroom"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree() -> void:
	# Attempt auto-save on close if configured.
	if dock and dock.has_method("trigger_auto_push"):
		dock.trigger_auto_push(2)
	remove_control_from_docks(dock)
	if dock:
		dock.queue_free()
		dock = null


func _save_external_data() -> void:
	# Trigger auto-save on editor save if configured.
	if dock and dock.has_method("trigger_auto_push"):
		dock.trigger_auto_push(1)

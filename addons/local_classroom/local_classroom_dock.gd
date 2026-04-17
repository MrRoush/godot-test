@tool
extends Control

const _CLASSROOM_CONFIG_PATH := "res://addons/local_classroom/classroom_config.cfg"

const EXCLUDED_DIRS := [".godot", ".git"]
const EXCLUDED_FILES := [".DS_Store", "Thumbs.db", "ehthumbs.db", "Desktop.ini"]

const ROLE_STUDENT := 0
const ROLE_TEACHER := 1

const AUTO_SAVE_MANUAL := 0
const AUTO_SAVE_ON_SAVE := 1
const AUTO_SAVE_ON_CLOSE := 2

var _role_option: OptionButton
var _server_path_input: LineEdit
var _assignment_input: LineEdit
var _name_input: LineEdit
var _pin_input: LineEdit
var _teacher_pin_input: LineEdit
var _auto_save_option: OptionButton
var _save_button: Button
var _sign_out_button: Button
var _load_students_button: Button
var _repo_tree: Tree
var _pull_button: Button
var _push_button: Button
var _connected_label: Label
var _last_saved_label: Label
var _auto_save_mode_label: Label
var _clean_pull_button: Button
var _progress_bar: ProgressBar
var _status_label: RichTextLabel
var _advanced_toggle: CheckButton
var _advanced_nodes: Array = []
var _teacher_nodes: Array = []
var _pull_confirm_dialog: ConfirmationDialog
var _clean_pull_confirm_dialog: ConfirmationDialog
var _browse_assignments_button: Button
var _assignment_popup: PopupMenu

var _is_pushing := false
var _server_path_locked := false
var _assignment_locked := false
var _loaded_students: Array = []
var _teacher_authenticated := false


func _ready() -> void:
	_build_ui()
	_load_classroom_config()
	_load_settings()
	_name_input.text_changed.connect(func(_t: String) -> void: _update_connected_label())
	_assignment_input.text_changed.connect(func(_t: String) -> void: _update_connected_label())
	_role_option.item_selected.connect(_on_role_changed)
	_set_status("[color=gray]Ready. Configure your settings above to get started.[/color]")


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	_add_section_header(vbox, "Settings")

	_advanced_toggle = CheckButton.new()
	_advanced_toggle.text = "Show Advanced Options"
	_advanced_toggle.toggled.connect(_on_advanced_toggle_changed)
	vbox.add_child(_advanced_toggle)

	var role_label := _add_label(vbox, "Role:")
	_role_option = OptionButton.new()
	_role_option.add_item("Student", ROLE_STUDENT)
	_role_option.add_item("Teacher", ROLE_TEACHER)
	vbox.add_child(_role_option)
	_advanced_nodes.append_array([role_label, _role_option])

	var teacher_pin_label := _add_label(vbox, "Teacher PIN:")
	_teacher_pin_input = _add_line_edit(vbox, "Teacher PIN")
	_teacher_pin_input.secret = true
	_teacher_nodes.append_array([teacher_pin_label, _teacher_pin_input])

	var server_label := _add_label(vbox, "Server Path:")
	_server_path_input = _add_line_edit(vbox, "\\\\SERVER\\GodotClassroom or Z:\\GodotClassroom")
	_advanced_nodes.append_array([server_label, _server_path_input])

	var assignment_label := _add_label(vbox, "Assignment:")
	_assignment_input = _add_line_edit(vbox, "Assignment1")
	_advanced_nodes.append_array([assignment_label, _assignment_input])

	_add_label(vbox, "Your Name:")
	_name_input = _add_line_edit(vbox, "FirstName LastName")

	_add_label(vbox, "PIN:")
	_pin_input = _add_line_edit(vbox, "1234")
	_pin_input.secret = true

	_browse_assignments_button = Button.new()
	_browse_assignments_button.text = "📋 Browse Assignments"
	_browse_assignments_button.pressed.connect(_on_browse_assignments_pressed)
	vbox.add_child(_browse_assignments_button)

	var auto_save_label := _add_label(vbox, "Auto-Save:")
	_auto_save_option = OptionButton.new()
	_auto_save_option.add_item("Auto-Save on Save", AUTO_SAVE_ON_SAVE)
	_auto_save_option.add_item("Manual Only", AUTO_SAVE_MANUAL)
	_auto_save_option.add_item("Auto-Save on Close", AUTO_SAVE_ON_CLOSE)
	_auto_save_option.item_selected.connect(_on_auto_save_mode_changed)
	vbox.add_child(_auto_save_option)
	_advanced_nodes.append_array([auto_save_label, _auto_save_option])

	_save_button = Button.new()
	_save_button.text = "Save Settings"
	_save_button.pressed.connect(_on_save_pressed)
	vbox.add_child(_save_button)

	_sign_out_button = Button.new()
	_sign_out_button.text = "🔒 Sign Out / Clear Credentials"
	_sign_out_button.pressed.connect(_on_sign_out_pressed)
	vbox.add_child(_sign_out_button)

	vbox.add_child(HSeparator.new())

	var classroom_header := Label.new()
	classroom_header.text = "Classroom"
	classroom_header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(classroom_header)
	var classroom_divider := HSeparator.new()
	vbox.add_child(classroom_divider)
	_load_students_button = Button.new()
	_load_students_button.text = "Load Students"
	_load_students_button.pressed.connect(_on_load_students_pressed)
	vbox.add_child(_load_students_button)

	_repo_tree = Tree.new()
	_repo_tree.custom_minimum_size = Vector2(0, 120)
	_repo_tree.hide_root = true
	_repo_tree.item_selected.connect(_on_repo_tree_selected)
	vbox.add_child(_repo_tree)
	_teacher_nodes.append_array([classroom_header, classroom_divider, _load_students_button, _repo_tree])

	vbox.add_child(HSeparator.new())

	_add_section_header(vbox, "Sync")
	_connected_label = Label.new()
	_connected_label.text = "Not configured"
	_connected_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(_connected_label)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(row)

	_pull_button = Button.new()
	_pull_button.text = "⬇ Get Template (Pull)"
	_pull_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pull_button.pressed.connect(_on_pull_pressed)
	row.add_child(_pull_button)

	_push_button = Button.new()
	_push_button.text = "⬆ Save to Server (Push)"
	_push_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_push_button.pressed.connect(_on_push_pressed)
	row.add_child(_push_button)

	_last_saved_label = Label.new()
	_last_saved_label.text = "Last saved: never"
	_last_saved_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(_last_saved_label)

	_auto_save_mode_label = Label.new()
	vbox.add_child(_auto_save_mode_label)

	_clean_pull_button = Button.new()
	_clean_pull_button.text = "🗑️ Clean Pull (Replace All Files)"
	_clean_pull_button.pressed.connect(_on_clean_pull_pressed)
	vbox.add_child(_clean_pull_button)
	_advanced_nodes.append(_clean_pull_button)

	vbox.add_child(HSeparator.new())

	_add_section_header(vbox, "Status")
	_progress_bar = ProgressBar.new()
	_progress_bar.visible = false
	vbox.add_child(_progress_bar)

	_status_label = RichTextLabel.new()
	_status_label.bbcode_enabled = true
	_status_label.fit_content = true
	_status_label.custom_minimum_size = Vector2(0, 110)
	vbox.add_child(_status_label)

	_pull_confirm_dialog = ConfirmationDialog.new()
	_pull_confirm_dialog.title = "Pull Template Files?"
	_pull_confirm_dialog.dialog_text = "This will copy assignment template files into your local project.\n\nContinue?"
	_pull_confirm_dialog.ok_button_text = "Yes, Pull Template"
	_pull_confirm_dialog.confirmed.connect(_on_pull_confirmed)
	add_child(_pull_confirm_dialog)

	_clean_pull_confirm_dialog = ConfirmationDialog.new()
	_clean_pull_confirm_dialog.title = "Replace All Project Files?"
	_clean_pull_confirm_dialog.dialog_text = "This will DELETE local files (except addons/) and replace them with template files.\n\nContinue?"
	_clean_pull_confirm_dialog.ok_button_text = "Yes, Replace All Files"
	_clean_pull_confirm_dialog.confirmed.connect(_on_clean_pull_confirmed)
	add_child(_clean_pull_confirm_dialog)

	_assignment_popup = PopupMenu.new()
	_assignment_popup.id_pressed.connect(_on_assignment_selected)
	add_child(_assignment_popup)

	for node in _advanced_nodes:
		node.visible = false

	_on_role_changed(ROLE_STUDENT)
	_update_auto_save_mode_label()
	_update_connected_label()


func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
	parent.add_child(HSeparator.new())


func _add_label(parent: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return label


func _add_line_edit(parent: VBoxContainer, placeholder: String) -> LineEdit:
	var line := LineEdit.new()
	line.placeholder_text = placeholder
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(line)
	return line


func _get_os_username() -> String:
	var os_user := OS.get_environment("USERNAME")
	if os_user.is_empty():
		os_user = OS.get_environment("USER")
	return os_user


func _get_safe_os_username() -> String:
	var os_user := _get_os_username()
	if os_user.is_empty():
		os_user = "default"
	var safe_user := ""
	for ch in os_user:
		if (ch >= "0" and ch <= "9") or (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z") or ch == "_":
			safe_user += ch
		else:
			safe_user += "_"
	if safe_user.is_empty():
		safe_user = "default"
	return safe_user


func _get_config_path() -> String:
	var safe_user := _get_safe_os_username()
	var local_appdata := OS.get_environment("LOCALAPPDATA")
	if not local_appdata.is_empty():
		var dir_path := local_appdata.path_join("GodotLocalClassroom")
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)
		return dir_path.path_join("local_classroom_" + safe_user + ".cfg")
	return "user://local_classroom_" + safe_user + ".cfg"


func _obfuscate_pin(pin: String) -> String:
	var key := _get_os_username()
	if key.is_empty():
		key = "godot_local_classroom_key"
	var result := ""
	for i in range(pin.length()):
		result += "%02x" % (pin.unicode_at(i) ^ key.unicode_at(i % key.length()))
	return result


func _deobfuscate_pin(obfuscated: String) -> String:
	if obfuscated.is_empty():
		return ""
	var key := _get_os_username()
	if key.is_empty():
		key = "godot_local_classroom_key"
	var result := ""
	for i in range(0, obfuscated.length(), 2):
		var pair := obfuscated.substr(i, 2)
		if pair.length() < 2:
			break
		var value := pair.hex_to_int()
		var k := key.unicode_at((i / 2) % key.length())
		result += char(value ^ k)
	return result


func _load_classroom_config() -> void:
	if not FileAccess.file_exists(_CLASSROOM_CONFIG_PATH):
		return
	var config := ConfigFile.new()
	if config.load(_CLASSROOM_CONFIG_PATH) != OK:
		return
	var server_path := str(config.get_value("classroom", "server_path", "")).strip_edges()
	if not server_path.is_empty():
		_server_path_input.text = server_path
		_server_path_input.editable = false
		_server_path_locked = true
	var assignment_name := str(config.get_value("classroom", "assignment_name", "")).strip_edges()
	if not assignment_name.is_empty():
		_assignment_input.text = assignment_name
		_assignment_input.editable = false
		_assignment_locked = true
		_browse_assignments_button.visible = false


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("local_classroom", "student_name", _name_input.text)
	config.set_value("local_classroom", "pin_v2", _obfuscate_pin(_pin_input.text))
	if not _server_path_locked:
		config.set_value("local_classroom", "server_path", _server_path_input.text)
	if not _assignment_locked:
		config.set_value("local_classroom", "assignment_name", _assignment_input.text)
	config.set_value("local_classroom", "role", _role_option.selected)
	config.set_value("local_classroom", "auto_save", _auto_save_option.get_selected_id())
	config.set_value("local_classroom", "advanced_mode", _advanced_toggle.button_pressed)
	config.save(_get_config_path())


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(_get_config_path()) != OK:
		return
	_name_input.text = str(config.get_value("local_classroom", "student_name", ""))
	_pin_input.text = _deobfuscate_pin(str(config.get_value("local_classroom", "pin_v2", "")))
	if not _server_path_locked:
		_server_path_input.text = str(config.get_value("local_classroom", "server_path", ""))
	if not _assignment_locked:
		_assignment_input.text = str(config.get_value("local_classroom", "assignment_name", ""))
	_role_option.selected = int(config.get_value("local_classroom", "role", ROLE_STUDENT))
	var auto_save_id := int(config.get_value("local_classroom", "auto_save", AUTO_SAVE_ON_SAVE))
	for i in range(_auto_save_option.item_count):
		if _auto_save_option.get_item_id(i) == auto_save_id:
			_auto_save_option.selected = i
			break
	var advanced_mode := bool(config.get_value("local_classroom", "advanced_mode", false))
	_advanced_toggle.button_pressed = advanced_mode
	_apply_advanced_mode(advanced_mode)
	_on_role_changed(_role_option.selected)


func _on_save_pressed() -> void:
	_save_settings()
	_set_status("✅ [color=green]Settings saved![/color]")
	_update_connected_label()
	_update_auto_save_mode_label()


func _on_sign_out_pressed() -> void:
	_name_input.text = ""
	_pin_input.text = ""
	_teacher_pin_input.text = ""
	_teacher_authenticated = false
	_loaded_students.clear()
	_repo_tree.clear()
	_save_settings()
	_set_status("ℹ️ [color=yellow]Signed out. Enter your name and PIN to continue.[/color]")
	_update_connected_label()


func _on_browse_assignments_pressed() -> void:
	var server_path := _normalize_server_path(_server_path_input.text)
	if server_path.is_empty():
		_set_status("❌ [color=red]No server path configured. Ask your teacher to set up classroom_config.cfg, or enable Advanced Options to enter the server path.[/color]")
		return
	if not DirAccess.dir_exists_absolute(server_path):
		_set_status("❌ [color=red]Server path is not reachable: %s[/color]" % server_path)
		return
	var assignments := _list_assignments(server_path)
	if assignments.is_empty():
		_set_status("⚠️ [color=yellow]No assignments found on the server (folders with a _template subfolder).[/color]")
		return
	_assignment_popup.clear()
	for i in range(assignments.size()):
		_assignment_popup.add_item(str(assignments[i]), i)
	_assignment_popup.popup_centered()


func _on_assignment_selected(id: int) -> void:
	if _assignment_locked:
		return
	var text := _assignment_popup.get_item_text(id)
	_assignment_input.text = text
	_save_settings()
	_set_status("✅ [color=green]Assignment selected: %s[/color]" % text)
	_update_connected_label()


func _on_load_students_pressed() -> void:
	if _role_option.selected != ROLE_TEACHER:
		_set_status("❌ [color=red]Teacher role is required to load students.[/color]")
		return
	if not _verify_teacher_pin():
		return
	_set_buttons_enabled(false)
	await _do_load_students()
	_set_buttons_enabled(true)


func _on_repo_tree_selected() -> void:
	var selected := _repo_tree.get_selected()
	if selected == null:
		return
	var meta = selected.get_metadata(0)
	if meta is int and meta >= 0 and meta < _loaded_students.size():
		_set_status("✅ [color=green]Selected student: %s[/color]" % str(_loaded_students[meta].get("name", "")))


func _on_pull_pressed() -> void:
	if not _validate_server_assignment():
		return
	if _role_option.selected == ROLE_TEACHER:
		if not _verify_teacher_pin():
			return
		var selected := _repo_tree.get_selected()
		if selected != null:
			var meta = selected.get_metadata(0)
			if meta is int and meta >= 0 and meta < _loaded_students.size():
				_set_buttons_enabled(false)
				await _do_teacher_pull(str(_loaded_students[meta].get("name", "")))
				_set_buttons_enabled(true)
				return
	_pull_confirm_dialog.popup_centered()


func _on_pull_confirmed() -> void:
	_set_buttons_enabled(false)
	await _do_pull()
	_set_buttons_enabled(true)


func _on_push_pressed() -> void:
	if not _validate_server_assignment():
		return
	_set_buttons_enabled(false)
	_is_pushing = true
	await _do_push()
	_is_pushing = false
	_set_buttons_enabled(true)


func _on_clean_pull_pressed() -> void:
	if not _validate_server_assignment():
		return
	_clean_pull_confirm_dialog.popup_centered()


func _on_clean_pull_confirmed() -> void:
	_set_buttons_enabled(false)
	await _do_clean_pull()
	_set_buttons_enabled(true)


func _on_advanced_toggle_changed(pressed: bool) -> void:
	_apply_advanced_mode(pressed)
	var config := ConfigFile.new()
	config.load(_get_config_path())
	config.set_value("local_classroom", "advanced_mode", pressed)
	config.save(_get_config_path())


func _on_auto_save_mode_changed(_idx: int) -> void:
	_update_auto_save_mode_label()


func _on_role_changed(_idx: int) -> void:
	var show_teacher := _role_option.selected == ROLE_TEACHER
	if not show_teacher:
		_teacher_authenticated = false
	for node in _teacher_nodes:
		node.visible = show_teacher


func _set_status(bbcode: String) -> void:
	_status_label.clear()
	_status_label.append_text(bbcode)


func _set_buttons_enabled(enabled: bool) -> void:
	_pull_button.disabled = not enabled
	_push_button.disabled = not enabled
	_save_button.disabled = not enabled
	_sign_out_button.disabled = not enabled
	_load_students_button.disabled = not enabled


func _apply_advanced_mode(advanced: bool) -> void:
	for node in _advanced_nodes:
		node.visible = advanced


func _update_connected_label() -> void:
	var assignment := _assignment_input.text.strip_edges()
	var student := _name_input.text.strip_edges()
	if assignment.is_empty() or student.is_empty():
		_connected_label.text = "Not configured"
		_connected_label.add_theme_color_override("font_color", Color.GRAY)
		return
	_connected_label.text = "🟢 Assignment: %s | Student: %s" % [assignment, student]
	_connected_label.remove_theme_color_override("font_color")


func _update_last_saved_label() -> void:
	var dt := Time.get_datetime_dict_from_system()
	_last_saved_label.text = "Last saved: %04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]


func _update_auto_save_mode_label() -> void:
	match _auto_save_option.get_selected_id():
		AUTO_SAVE_MANUAL:
			_auto_save_mode_label.text = "Auto-save mode: Manual only"
		AUTO_SAVE_ON_SAVE:
			_auto_save_mode_label.text = "Auto-save mode: Auto-save on editor save ✓"
		AUTO_SAVE_ON_CLOSE:
			_auto_save_mode_label.text = "Auto-save mode: Auto-save on editor close ✓"


func _normalize_server_path(path: String) -> String:
	var trimmed := path.strip_edges()
	# Detect UNC paths (\\server\share) before converting slashes.
	var is_unc := trimmed.begins_with("\\\\") or trimmed.begins_with("//")
	# Normalize to forward slashes for Godot's DirAccess / FileAccess.
	trimmed = trimmed.replace("\\", "/")
	# Strip trailing slashes.
	while trimmed.length() > 1 and trimmed.ends_with("/"):
		trimmed = trimmed.substr(0, trimmed.length() - 1)
	# Restore the UNC double-slash prefix that Godot requires on Windows.
	if is_unc and not trimmed.begins_with("//"):
		trimmed = "/" + trimmed
	return trimmed


func _validate_server_assignment() -> bool:
	var server_path := _normalize_server_path(_server_path_input.text)
	if server_path.is_empty():
		_set_status("❌ [color=red]Please enter a server path.[/color]")
		return false
	if not DirAccess.dir_exists_absolute(server_path):
		_set_status("❌ [color=red]Server path is not reachable or does not exist: %s\nBoth UNC paths (\\\\SERVER\\Share) and mapped drives (Z:\\Folder) are supported.[/color]" % server_path)
		return false
	if _assignment_input.text.strip_edges().is_empty():
		_set_status("❌ [color=red]Please enter an assignment name.[/color]")
		return false
	return true


## Parses a simple INI-style file without using ConfigFile, so that Godot's
## engine never prints parse-error messages that could expose sensitive values
## such as the teacher PIN.  Supports [sections], key = value pairs, and
## ; or # comment lines.  Returns {"ok": bool, "sections": {name: {key: value}}}.
func _parse_ini_file(path: String) -> Dictionary:
	var result := {"ok": false, "sections": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var current_section := ""
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("["):
			var bracket_end := line.find("]")
			if bracket_end > 1:
				current_section = line.substr(1, bracket_end - 1).strip_edges()
				if not result["sections"].has(current_section):
					result["sections"][current_section] = {}
		elif "=" in line and not current_section.is_empty():
			var eq_idx := line.find("=")
			var key := line.substr(0, eq_idx).strip_edges()
			var value := line.substr(eq_idx + 1).strip_edges()
			result["sections"][current_section][key] = value
	file.close()
	result["ok"] = true
	return result


## Returns a sorted list of assignment folder names found directly inside
## server_path.  Only folders that contain a _template subfolder are included,
## since that is the marker that distinguishes an assignment from a stray dir.
func _list_assignments(server_path: String) -> Array:
	var results: Array = []
	var dir := DirAccess.open(server_path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir() and not entry.begins_with("."):
			var template_path := server_path.path_join(entry).path_join("_template")
			if DirAccess.dir_exists_absolute(template_path):
				results.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	results.sort()
	return results


func _verify_pin() -> bool:
	var student_name := _name_input.text.strip_edges()
	if student_name.is_empty():
		_set_status("❌ [color=red]Please enter your name[/color]")
		return false
	var entered_pin := _pin_input.text.strip_edges()
	if entered_pin.is_empty():
		_set_status("❌ [color=red]Please enter your PIN[/color]")
		return false

	var students_cfg_path := _normalize_server_path(_server_path_input.text).path_join("students.cfg")
	if not FileAccess.file_exists(students_cfg_path):
		_set_status("⚠️ [color=yellow]students.cfg was not found. Saving is still allowed.[/color]")
		return true

	var parsed := _parse_ini_file(students_cfg_path)
	if not parsed["ok"]:
		_set_status("❌ [color=red]Could not read students.cfg — check the file format (it must use Godot INI format with a [students] section).[/color]")
		return false
	var sections: Dictionary = parsed["sections"]
	if not sections.has("students"):
		_set_status("❌ [color=red]students.cfg is missing a [students] section.[/color]")
		return false

	for key in sections["students"]:
		if str(key).to_lower() == student_name.to_lower():
			if str(sections["students"][key]).strip_edges() == entered_pin:
				return true
			break
	_set_status("❌ [color=red]Wrong name or PIN — ask your teacher to check students.cfg[/color]")
	return false


func _verify_teacher_pin() -> bool:
	if _teacher_authenticated:
		return true
	if not _validate_server_assignment():
		return false

	var entered_pin := _teacher_pin_input.text.strip_edges()
	if entered_pin.is_empty():
		_set_status("❌ [color=red]Please enter the teacher PIN.[/color]")
		return false

	var students_cfg_path := _normalize_server_path(_server_path_input.text).path_join("students.cfg")
	if not FileAccess.file_exists(students_cfg_path):
		_set_status("❌ [color=red]students.cfg not found — cannot verify teacher PIN: %s[/color]" % students_cfg_path)
		return false

	var parsed := _parse_ini_file(students_cfg_path)
	if not parsed["ok"]:
		_set_status("❌ [color=red]Could not read students.cfg — check the file format (it must use Godot INI format with a [teacher] section).[/color]")
		return false
	var sections: Dictionary = parsed["sections"]
	if not sections.has("teacher"):
		_set_status("❌ [color=red]students.cfg is missing a [teacher] section with a PIN.[/color]")
		return false

	var expected_pin := str(sections["teacher"].get("pin", "")).strip_edges()
	if expected_pin.is_empty():
		_set_status("❌ [color=red]No teacher PIN is set in students.cfg.[/color]")
		return false

	if entered_pin != expected_pin:
		_set_status("❌ [color=red]Incorrect teacher PIN.[/color]")
		return false

	_teacher_authenticated = true
	return true


func _do_push() -> void:
	if not _verify_pin():
		return

	_set_status("⏳ [color=yellow]Saving backup ZIP to server...[/color]")
	_progress_bar.visible = true
	_progress_bar.value = 0

	var destination_dir := _normalize_server_path(_server_path_input.text).path_join(_assignment_input.text.strip_edges()).path_join(_name_input.text.strip_edges())
	var mk_err := DirAccess.make_dir_recursive_absolute(destination_dir)
	if mk_err != OK and not DirAccess.dir_exists_absolute(destination_dir):
		_progress_bar.visible = false
		_set_status("❌ [color=red]Could not create destination folder. Check permissions for: %s[/color]" % destination_dir)
		return

	var project_path := ProjectSettings.globalize_path("res://")
	var files := _scan_project_files(project_path, "")
	if files.is_empty():
		_progress_bar.visible = false
		_set_status("⚠️ [color=yellow]No project files found to save.[/color]")
		return

	var dt := Time.get_datetime_dict_from_system()
	var zip_name := "backup_%04d-%02d-%02d_%02d-%02d-%02d.zip" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
	var zip_path := destination_dir.path_join(zip_name)

	var zip := ZIPPacker.new()
	if zip.open(zip_path) != OK:
		_progress_bar.visible = false
		_set_status("❌ [color=red]ZIP creation failed: could not open %s[/color]" % zip_path)
		return

	for i in range(files.size()):
		var rel_path: String = files[i]
		var content := FileAccess.get_file_as_bytes(project_path.path_join(rel_path))
		if content.is_empty() and FileAccess.get_open_error() != OK:
			zip.close()
			_progress_bar.visible = false
			_set_status("❌ [color=red]ZIP creation failed while reading %s[/color]" % rel_path)
			return
		if zip.start_file(rel_path) != OK:
			zip.close()
			_progress_bar.visible = false
			_set_status("❌ [color=red]ZIP creation failed while adding %s[/color]" % rel_path)
			return
		if zip.write_file(content) != OK:
			zip.close()
			_progress_bar.visible = false
			_set_status("❌ [color=red]ZIP creation failed while writing %s[/color]" % rel_path)
			return
		zip.close_file()
		_progress_bar.value = float(i + 1) / float(files.size()) * 100.0

	zip.close()
	_progress_bar.visible = false
	_update_last_saved_label()
	_set_status("✅ [color=green]Saved backup to server: %s[/color]" % zip_path)


func _do_pull() -> void:
	_set_status("⏳ [color=yellow]Pulling template files from server...[/color]")
	_progress_bar.visible = true
	_progress_bar.value = 0

	var source_dir := _normalize_server_path(_server_path_input.text).path_join(_assignment_input.text.strip_edges()).path_join("_template")
	if not DirAccess.dir_exists_absolute(source_dir):
		_progress_bar.visible = false
		_set_status("❌ [color=red]Template folder not found: %s[/color]" % source_dir)
		return

	var files := _scan_absolute_files(source_dir, "")
	var project_path := ProjectSettings.globalize_path("res://")
	var errors := 0
	for i in range(files.size()):
		var rel_path: String = files[i]
		if _is_relative_path_excluded(rel_path):
			continue
		var target_path := project_path.path_join(rel_path)
		DirAccess.make_dir_recursive_absolute(target_path.get_base_dir())
		var bytes := FileAccess.get_file_as_bytes(source_dir.path_join(rel_path))
		if bytes.is_empty() and FileAccess.get_open_error() != OK:
			errors += 1
			continue
		var out := FileAccess.open(target_path, FileAccess.WRITE)
		if out == null:
			errors += 1
			continue
		out.store_buffer(bytes)
		out.close()
		_progress_bar.value = float(i + 1) / float(max(files.size(), 1)) * 100.0

	_progress_bar.visible = false
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
	if errors == 0:
		_set_status("✅ [color=green]Template pull complete.[/color]")
	else:
		_set_status("⚠️ [color=yellow]Template pull finished with %d error(s).[/color]" % errors)


func _do_load_students() -> void:
	_set_status("⏳ [color=yellow]Loading student folders...[/color]")
	_repo_tree.clear()
	_loaded_students.clear()

	var assignment_dir := _normalize_server_path(_server_path_input.text).path_join(_assignment_input.text.strip_edges())
	if not DirAccess.dir_exists_absolute(assignment_dir):
		_set_status("❌ [color=red]Assignment folder not found: %s[/color]" % assignment_dir)
		return
	var dir := DirAccess.open(assignment_dir)
	if dir == null:
		_set_status("❌ [color=red]Could not open assignment folder: %s[/color]" % assignment_dir)
		return

	var root := _repo_tree.create_item()
	var assignment_item := _repo_tree.create_item(root)
	assignment_item.set_text(0, _assignment_input.text.strip_edges())
	assignment_item.set_selectable(0, false)

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir() and entry != "_template":
			_loaded_students.append({"name": entry, "path": assignment_dir.path_join(entry)})
		entry = dir.get_next()
	dir.list_dir_end()

	_loaded_students.sort_custom(func(a, b): return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower())
	for i in range(_loaded_students.size()):
		var item := _repo_tree.create_item(assignment_item)
		item.set_text(0, str(_loaded_students[i].get("name", "")))
		item.set_metadata(0, i)

	if _loaded_students.is_empty():
		_set_status("⚠️ [color=yellow]No student folders found yet.[/color]")
	else:
		_set_status("✅ [color=green]Loaded %d student folder(s).[/color]" % _loaded_students.size())


func _do_teacher_pull(student_name: String) -> void:
	_set_status("⏳ [color=yellow]Loading latest backup for %s...[/color]" % student_name)
	_progress_bar.visible = true
	_progress_bar.value = 0

	var student_dir := _normalize_server_path(_server_path_input.text).path_join(_assignment_input.text.strip_edges()).path_join(student_name)
	if not DirAccess.dir_exists_absolute(student_dir):
		_progress_bar.visible = false
		_set_status("❌ [color=red]Student folder not found: %s[/color]" % student_dir)
		return

	var zip_files := _list_zip_files(student_dir)
	zip_files.sort()
	zip_files.reverse()
	if zip_files.is_empty():
		_progress_bar.visible = false
		_set_status("❌ [color=red]No backup ZIP files found for %s.[/color]" % student_name)
		return

	var zip_path := student_dir.path_join(zip_files[0])
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		_progress_bar.visible = false
		_set_status("❌ [color=red]Could not open ZIP: %s[/color]" % zip_path)
		return

	var files := reader.get_files()
	var project_path := ProjectSettings.globalize_path("res://")
	var errors := 0
	for i in range(files.size()):
		var rel_path: String = files[i]
		if not _is_safe_relative_path(rel_path) or _is_relative_path_excluded(rel_path):
			continue
		var data := reader.read_file(rel_path)
		if data.is_empty() and reader.get_error() != OK:
			errors += 1
			continue
		var out_path := project_path.path_join(rel_path)
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		var out := FileAccess.open(out_path, FileAccess.WRITE)
		if out == null:
			errors += 1
			continue
		out.store_buffer(data)
		out.close()
		_progress_bar.value = float(i + 1) / float(max(files.size(), 1)) * 100.0
	reader.close()

	_progress_bar.visible = false
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
	if errors == 0:
		_set_status("✅ [color=green]Loaded latest backup for %s.[/color]" % student_name)
	else:
		_set_status("⚠️ [color=yellow]Loaded backup for %s with %d error(s).[/color]" % [student_name, errors])


func _do_clean_pull() -> void:
	var project_path := ProjectSettings.globalize_path("res://")
	_delete_files_except_addons(project_path, "")
	await _do_pull()


func _delete_files_except_addons(base_path: String, relative_path: String) -> void:
	var full_dir := base_path if relative_path.is_empty() else base_path.path_join(relative_path)
	var dir := DirAccess.open(full_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var rel := entry if relative_path.is_empty() else relative_path.path_join(entry)
		if dir.current_is_dir():
			var is_root_addons := relative_path.is_empty() and entry == "addons"
			if not is_root_addons and not (entry in EXCLUDED_DIRS):
				_delete_files_except_addons(base_path, rel)
				DirAccess.remove_absolute(base_path.path_join(rel))
		else:
			if not (entry in EXCLUDED_FILES):
				DirAccess.remove_absolute(base_path.path_join(rel))
		entry = dir.get_next()
	dir.list_dir_end()


func _scan_project_files(base_path: String, relative_path: String) -> Array:
	var results: Array = []
	var full_dir := base_path if relative_path.is_empty() else base_path.path_join(relative_path)
	var dir := DirAccess.open(full_dir)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var rel := entry if relative_path.is_empty() else relative_path.path_join(entry)
		if dir.current_is_dir():
			if not (entry in EXCLUDED_DIRS):
				results.append_array(_scan_project_files(base_path, rel))
		else:
			if not (entry in EXCLUDED_FILES):
				results.append(rel)
		entry = dir.get_next()
	dir.list_dir_end()
	return results


func _scan_absolute_files(base_path: String, relative_path: String) -> Array:
	var results: Array = []
	var full_dir := base_path if relative_path.is_empty() else base_path.path_join(relative_path)
	var dir := DirAccess.open(full_dir)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var rel := entry if relative_path.is_empty() else relative_path.path_join(entry)
		if dir.current_is_dir():
			results.append_array(_scan_absolute_files(base_path, rel))
		else:
			results.append(rel)
		entry = dir.get_next()
	dir.list_dir_end()
	return results


func _list_zip_files(dir_path: String) -> Array:
	var results: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if not dir.current_is_dir() and entry.to_lower().ends_with(".zip"):
			results.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	return results


func _is_safe_relative_path(path: String) -> bool:
	var normalized := path.replace("\\", "/")
	if normalized.begins_with("/"):
		return false
	for part in normalized.split("/"):
		if part == "..":
			return false
	return true


func _is_relative_path_excluded(path: String) -> bool:
	var normalized := path.replace("\\", "/")
	for excluded_dir in EXCLUDED_DIRS:
		if normalized == excluded_dir or normalized.begins_with(excluded_dir + "/"):
			return true
	for excluded_file in EXCLUDED_FILES:
		if normalized.get_file() == excluded_file:
			return true
	return false


func trigger_auto_push(reason: int = AUTO_SAVE_ON_SAVE) -> void:
	if _is_pushing:
		return
	var mode := _auto_save_option.get_selected_id()
	if mode == AUTO_SAVE_MANUAL:
		return
	if reason == AUTO_SAVE_ON_SAVE and mode != AUTO_SAVE_ON_SAVE:
		return
	if reason == AUTO_SAVE_ON_CLOSE and mode != AUTO_SAVE_ON_CLOSE:
		return
	if not _validate_server_assignment():
		return
	_is_pushing = true
	_set_buttons_enabled(false)
	await _do_push()
	_set_buttons_enabled(true)
	_is_pushing = false

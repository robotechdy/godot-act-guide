@tool
extends EditorPlugin
## Deliberately uses two private UI anchors; see the skill's design reference.
## Moves the original mode button container, never copies tabs or scenes.

# One allowlist for runtime and tests. Hashes are official nine-character IDs.
# Adding a record requires the source review and editor tests in compatibility.md.
const SUPPORTED_BUILDS := [
	{"major": 4, "minor": 7, "patch": 0, "status": "stable", "build": "official", "hash": "5b4e0cb0f", "platform": "macOS"},
	{"major": 4, "minor": 7, "patch": 2, "status": "stable", "build": "official", "hash": "ed1daf0bf", "platform": "macOS"},
]
const GROUP_GAP := 64.0
var _requested := false
var _row: HBoxContainer
var _modes: HBoxContainer
var _origin: Node
var _next_sibling: Node
var _origin_index := -1
var _active := false
var _mode_size_flags := 0
var _mode_alignment := BoxContainer.ALIGNMENT_BEGIN
var _mode_minimum_size := Vector2.ZERO
var _scene_button_flags: Dictionary = {}
var _scene_views: Dictionary = {}
var _scene_id := 0
var _view_revision := 0
var _switch_pending := false
var _connections: Array[Dictionary] = []


func _enter_tree() -> void:
	_requested = true
	_apply.call_deferred()


func _exit_tree() -> void:
	_requested = false
	_restore()


static func supports(version: Dictionary, platform: String) -> bool:
	for build in SUPPORTED_BUILDS:
		if platform != build.platform or not str(version.get("hash", "")).begins_with(build.hash):
			continue
		var matches := true
		for field in ["major", "minor", "patch", "status", "build"]:
			if typeof(version.get(field)) != typeof(build[field]) or version[field] != build[field]:
				matches = false
		if matches:
			return true
	return false


func _listen(source: Object, signal_name: StringName, callback: Callable) -> void:
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)
		_connections.append({"source": weakref(source), "signal": signal_name, "callback": callback})


func _disconnect_all() -> void:
	# Keep the exact connections, including buttons removed by another plugin.
	for connection in _connections:
		var source: Object = connection.source.get_ref()
		if is_instance_valid(source) and source.is_connected(connection.signal, connection.callback):
			source.disconnect(connection.signal, connection.callback)
	_connections.clear()


func _find(node: Node, class_name_filter: String, node_name: String = "") -> Array[Node]:
	var matches: Array[Node] = []
	if node.get_class() == class_name_filter and (node_name.is_empty() or node.name == node_name):
		matches.append(node)
	for child in node.get_children():
		matches.append_array(_find(child, class_name_filter, node_name))
	return matches


func _probe(base: Node) -> Dictionary:
	var tabs := _find(base, "EditorSceneTabs")
	var modes := _find(base, "HBoxContainer", "EditorMainScreenButtons")
	if tabs.size() != 1 or modes.size() != 1:
		return {}
	var center := tabs[0].get_parent()
	var origin := modes[0].get_parent()
	# Validate relationships before making any changes. No numeric tree paths.
	if not center is VBoxContainer or origin.get_class() != "EditorTitleBar":
		return {}
	if center.get_child_count() != 2 or center.get_child(0) != tabs[0]:
		return {}
	if center.get_child(1).get_class() != "EditorMainScreen":
		return {}
	if modes[0].get_child_count() < 3:
		return {}
	for child in modes[0].get_children():
		if not child is Button:
			return {}
	for index in range(3):
		if modes[0].get_child(index).text != ["2D", "3D", "Script"][index]:
			return {}
	return {"center": center, "modes": modes[0], "origin": origin}


func _apply() -> void:
	if not _requested or _active:
		return
	if not supports(Engine.get_version_info(), OS.get_name()):
		push_warning("Scene Layout: unverified engine/platform; layout unchanged. See plugin.gd SUPPORTED_BUILDS and the skill's compatibility procedure.")
		return
	var layout := _probe(EditorInterface.get_base_control())
	if layout.is_empty():
		push_warning("Scene Layout: native UI structure differs or another layout plugin is active; layout unchanged.")
		return
	_modes = layout.modes
	_origin = layout.origin
	_origin_index = _modes.get_index()
	if _origin_index + 1 < _origin.get_child_count():
		_next_sibling = _origin.get_child(_origin_index + 1)
	_row = HBoxContainer.new()
	_row.name = "SceneLayoutViewRow"
	_row.tooltip_text = "2D/3D edit the current scene. Script, Game and Asset Store are shared across scenes."
	layout.center.add_child(_row)
	layout.center.move_child(_row, 1)
	_modes.reparent(_row, false)
	_active = true
	_group_buttons()
	_start_view_memory()


func _group_buttons() -> void:
	_mode_size_flags = _modes.size_flags_horizontal
	_mode_alignment = _modes.alignment
	_mode_minimum_size = _modes.custom_minimum_size
	_modes.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_modes.alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in _modes.get_children():
		if button.text in ["2D", "3D"]:
			_scene_button_flags[button] = button.size_flags_horizontal
			_listen(button, &"visibility_changed", _update_group_spacing)
	_listen(_modes, &"minimum_size_changed", _update_group_spacing)
	_update_group_spacing()


func _update_group_spacing() -> void:
	if not _active or not is_instance_valid(_modes):
		return
	var last_visible: Button
	for button in _scene_button_flags:
		if not is_instance_valid(button):
			continue
		button.size_flags_horizontal = _scene_button_flags[button]
		if button.visible:
			last_visible = button
	if last_visible != null:
		# Expand the layout slot, not the clickable button. Only the fixed extra
		# width below goes after 3D (or 2D when 3D is hidden).
		# Native code assumes every direct child is a Button, so add no spacers.
		last_visible.size_flags_horizontal = Control.SIZE_EXPAND
	var gap := GROUP_GAP * EditorInterface.get_editor_scale() if last_visible != null else 0.0
	var minimum := _mode_minimum_size
	minimum.x = maxf(minimum.x, _modes.get_minimum_size().x + gap)
	# get_minimum_size excludes our custom minimum. Guard the setter because
	# changing it can itself emit minimum_size_changed.
	if not _modes.custom_minimum_size.is_equal_approx(minimum):
		_modes.custom_minimum_size = minimum


func _ungroup_buttons() -> void:
	for button in _scene_button_flags:
		if is_instance_valid(button):
			button.size_flags_horizontal = _scene_button_flags[button]
	_scene_button_flags.clear()
	if is_instance_valid(_modes):
		_modes.size_flags_horizontal = _mode_size_flags
		_modes.alignment = _mode_alignment
		_modes.custom_minimum_size = _mode_minimum_size


func _current_scene_id() -> int:
	var root := EditorInterface.get_edited_scene_root()
	return root.get_instance_id() if is_instance_valid(root) else 0


func _current_view() -> String:
	if not is_instance_valid(_modes):
		return ""
	for button in _modes.get_children():
		if button is Button and button.button_pressed:
			return button.text
	return ""


func _start_view_memory() -> void:
	_scene_id = _current_scene_id()
	_remember_view(_current_view())
	_listen(self, &"main_screen_changed", _on_view_changed)
	_listen(self, &"scene_changed", _on_scene_changed)
	_listen(self, &"scene_closed", _on_scene_closed)
	for button in _modes.get_children():
		_listen(button, &"pressed", _on_view_pressed)


func _remember_view(view: String) -> void:
	if _scene_id != 0 and not view.is_empty():
		_scene_views[_scene_id] = view


func _on_view_changed(view: String) -> void:
	# Native auto-switch can fire before scene_changed, after the root has changed.
	# Never write that transient view into the scene we are leaving.
	if _active and not _switch_pending and _current_scene_id() == _scene_id:
		_remember_view(view)


func _on_view_pressed() -> void:
	if not _active:
		return
	# Explicit button clicks win over any queued restoration, including reselecting
	# an already-active view (which does not emit main_screen_changed).
	_view_revision += 1
	_switch_pending = false
	_scene_id = _current_scene_id()
	# A floating Game/Script window can immediately return the central editor to
	# another mode. Record the actual selection, not the requested button's name.
	_remember_view(_current_view())


func _on_scene_changed(_root: Node) -> void:
	if not _active:
		return
	_scene_id = _current_scene_id()
	_view_revision += 1
	_switch_pending = true
	_finish_scene_switch.call_deferred(_view_revision, _scene_id)


func _finish_scene_switch(revision: int, scene_id: int) -> void:
	# Finish the native editor's queued scene/inspector updates before selecting
	# another main screen. Same-frame scene changes can still have pending work.
	if not _active or not is_inside_tree():
		return
	await get_tree().process_frame
	if not _active or revision != _view_revision or scene_id != _current_scene_id():
		return
	if scene_id == 0:
		_switch_pending = false
		return
	var remembered: String = _scene_views.get(scene_id, "")
	if remembered.is_empty():
		# A new scene must not inherit a shared tool from the preceding scene.
		# Keep native spatial selection; otherwise start with its root's dimension.
		var native_view := _current_view()
		if native_view in ["2D", "3D"]:
			remembered = native_view
		else:
			remembered = "3D" if EditorInterface.get_edited_scene_root() is Node3D else "2D"
	# Shared contents do not imply shared tab selection. Restore Game/Script/etc.
	# just like 2D/3D; selecting Game does not start or restart the running game.
	if not _select_view(remembered):
		for fallback in ["2D", "3D"]:
			if _select_view(fallback):
				break
	_remember_view(_current_view())
	_switch_pending = false


func _select_view(view: String) -> bool:
	if not is_instance_valid(_modes):
		return false
	for button in _modes.get_children():
		if button is Button and button.text == view and button.is_visible_in_tree() and not button.disabled:
			EditorInterface.set_main_screen_editor(view)
			return true
	return false


func _on_scene_closed(_path: String) -> void:
	_prune_view_memory.call_deferred()


func _prune_view_memory() -> void:
	if not _active:
		return
	var open_ids: Array[int] = []
	for root in EditorInterface.get_open_scene_roots():
		if is_instance_valid(root):
			open_ids.append(root.get_instance_id())
	for id in _scene_views.keys():
		if id not in open_ids:
			_scene_views.erase(id)


func _stop_view_memory() -> void:
	_view_revision += 1
	_switch_pending = false
	_scene_views.clear()
	_scene_id = 0


func _restore() -> void:
	if not _active:
		return
	# Cancel callbacks before reparenting or changing layout properties.
	_active = false
	_disconnect_all()
	_stop_view_memory()
	_ungroup_buttons()
	# Do not steal a control that another plugin moved after activation.
	if is_instance_valid(_modes) and is_instance_valid(_origin) and _modes.get_parent() == _row:
		_modes.reparent(_origin, false)
		var index := mini(_origin_index, _origin.get_child_count() - 1)
		if is_instance_valid(_next_sibling) and _next_sibling.get_parent() == _origin:
			index = _next_sibling.get_index()
		_origin.move_child(_modes, index)
	# Never free native controls or foreign children, even during shutdown.
	if is_instance_valid(_row):
		if _row.get_child_count() != 0:
			push_warning("Scene Layout: modified UI cannot be fully restored; preserving occupied row. Disable conflicting layout plugins and restart the editor.")
		else:
			if _row.get_parent() != null:
				_row.get_parent().remove_child(_row)
			_row.queue_free()
	_row = null
	_modes = null
	_origin = null
	_next_sibling = null

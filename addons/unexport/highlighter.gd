class_name AuriHiderHighlighter

signal _on_cleanup

var _plugin_node: Node
var _current_code_edit: CodeEdit = null
var _rehighlight_timer := Timer.new()

func setup(plugin_node: Node) -> void:
	_plugin_node = plugin_node
	_plugin_node.add_child(_rehighlight_timer, false, Node.INTERNAL_MODE_FRONT)
	_rehighlight_timer.one_shot = true
	_rehighlight_timer.wait_time =\
		EditorInterface.get_editor_settings().get_setting("text_editor/completion/idle_parse_delay") + 0.001
	_rehighlight_timer.timeout.connect(_highlight_code_edit)
	
	var _handle_script_changed := _on_script_changed.unbind(1)
	EditorInterface.get_script_editor().editor_script_changed.connect(_handle_script_changed)
	_handle_script_changed.call(1)
	
	_on_cleanup.connect(func() -> void:
		EditorInterface.get_script_editor().editor_script_changed.disconnect(_handle_script_changed)
		_disconnect_current_code_edit()
	)


func _on_script_changed() -> void:
	var current_editor := EditorInterface.get_script_editor().get_current_editor()
	if not current_editor: return
	var code_edit := current_editor.get_base_editor() as CodeEdit
	if not code_edit: return
	if code_edit == _current_code_edit: return
	_disconnect_current_code_edit()
	_current_code_edit = code_edit
	_connect_current_code_edit()


func _connect_current_code_edit() -> void:
	if !_current_code_edit: return
	_current_code_edit.text_changed.connect(_on_text_changed)
	_on_text_changed()


func _disconnect_current_code_edit() -> void:
	if !_current_code_edit: return
	_current_code_edit.text_changed.disconnect(_on_text_changed)


func _on_text_changed() -> void:
	_highlight_code_edit()
	_rehighlight_timer.start()


func _highlight_code_edit() -> void:
	if !_current_code_edit: return
	for i in _current_code_edit.get_line_count():
		var line := _current_code_edit.get_line(i)
		if !line.begins_with("# @unexport ") and !line.begins_with("#@unexport "): continue
		_current_code_edit.set_line_background_color(i, Color(0.846, 0.458, 0.0, 0.115))

@tool
extends EditorPlugin

signal _on_cleanup()

var SETTINGS := preload("./settings.gd").new()
var inspector := preload("./inspector.gd").new()
var highlighter := preload("./highlighter.gd").new()

func _enter_tree() -> void:
	_setup_inspector() 
	_setup_highlighter()

	SETTINGS.setup()
	ProjectSettings.settings_changed.connect(_reload_settings)
	_reload_settings()

func _exit_tree() -> void: 
	_on_cleanup.emit()
	for connection in _on_cleanup.get_connections(): _on_cleanup.disconnect(connection.callable)
	ProjectSettings.settings_changed.disconnect(_reload_settings)


func _reload_settings() -> void:
	inspector.set_show_hint_button(SETTINGS.get_setting(SETTINGS.SETTING_SHOW_HINT_BUTTON))
	highlighter.set_enabled(SETTINGS.get_setting(SETTINGS.SETTING_HIGHLIGHT_LINES))
	var scanned_lines := SETTINGS.get_setting(SETTINGS.SETTING_NUM_LINES)
	highlighter.set_scanned_lines(scanned_lines)
	inspector.set_scanned_lines(scanned_lines)


func _setup_inspector() -> void:
	add_inspector_plugin(inspector)
	
	var _on_resource_saved := func(res: Resource) -> void: inspector._on_file_changed(res.resource_path)
	resource_saved.connect(_on_resource_saved)
	_on_cleanup.connect(func() -> void: 
		resource_saved.disconnect(_on_resource_saved)
		inspector._on_cleanup.emit()
		remove_inspector_plugin(inspector))


func _setup_highlighter() -> void:
	highlighter.setup(self)
	_on_cleanup.connect(func() -> void: highlighter._on_cleanup.emit())

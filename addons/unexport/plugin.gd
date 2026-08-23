@tool
extends EditorPlugin
class_name AuriHider

signal _on_cleanup()

var inspector_plugin := AuriHiderInspectorPlugin.new()
var highlighter := AuriHiderHighlighter.new()

func _enter_tree() -> void:
	_setup_inspector() 
	_setup_highlighter()


func _exit_tree() -> void: 
	_on_cleanup.emit()
	for connection in _on_cleanup.get_connections(): _on_cleanup.disconnect(connection.callable)


func _setup_inspector() -> void:
	add_inspector_plugin(inspector_plugin)
	_on_cleanup.connect(func() -> void: remove_inspector_plugin(inspector_plugin))


func _setup_highlighter() -> void:
	highlighter.setup(self)
	_on_cleanup.connect(func() -> void: highlighter._on_cleanup.emit())

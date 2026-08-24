@tool
extends EditorPlugin
class_name UnexportPlugin

const MAX_LINES_SEARCHED := 100

signal _on_cleanup()

var inspector := preload("./inspector.gd").new()
var highlighter := preload("./highlighter.gd").new()

func _enter_tree() -> void:
	_setup_inspector() 
	_setup_highlighter()


func _exit_tree() -> void: 
	_on_cleanup.emit()
	for connection in _on_cleanup.get_connections(): _on_cleanup.disconnect(connection.callable)


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

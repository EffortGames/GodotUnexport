extends EditorInspectorPlugin

signal _on_cleanup()

## Look up the script to find its list of hidden properties and groups.
## type HiddenProperty<Category, Property>: `Category:Property`
## type HiddenGroup<Category, Group>: `Category>Group`
##
## Record<Script, {
##   inherits: Script | null
##   hidden_properties: PackedStringArray<HiddenProperty>,
##   hidden_groups: PackedStringArray<HiddenGroup>,
##   hidden_categories: PackedStringArray,
##   categories_with_hidden: PackedStringArray
## }>
var hidden_properties_cache: Dictionary[Script, Dictionary] = {}

var hide_properties_regex = RegEx.create_from_string("^#\\s?@unexport\\s+(.+)$")

var current_category := ""
var current_group := ""
var is_current_category_hidden := false
var is_current_group_hidden := false
var gdscript_class_name_map: Dictionary[String, String]
var hidden_properties_label: Control
var label_properties_hidden := "[i]Some properties hidden by [b]@unexport[/b][/i]"
var label_properties_visible := "[i]Ignoring [b]@unexport[/b], all properties visible[/i]"
var temporarily_visible_categories: Dictionary[Script, PackedStringArray] = {}

var show_hint_button := true
var scanned_lines := 100


func _init() -> void:	
	# Setup Litte UI Component thingy
	var container := Button.new()
	container.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color("#0002")
	container.add_theme_stylebox_override("normal", stylebox)
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#0001")
	container.add_theme_stylebox_override("hover", stylebox)
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color("#0004")
	container.add_theme_stylebox_override("pressed", stylebox)
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hbox)
	
	var label := RichTextLabel.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = ""
	label.fit_content = true
	label.bbcode_enabled = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0, 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color.TRANSPARENT
	stylebox.content_margin_left = 7
	var scale := EditorInterface.get_editor_scale()
	label.add_theme_stylebox_override("normal", stylebox)
	label.add_theme_font_size_override("italics_font_size", roundi(11 * scale))
	label.add_theme_font_size_override("bold_italics_font_size", roundi(11 * scale))
	hbox.add_child(label)
	
	hidden_properties_label = container


func set_show_hint_button(show: bool) -> void:
	if show_hint_button == show: return
	show_hint_button = show
	_reload_editor()


func set_scanned_lines(lines: int) -> void:
	scanned_lines = lines


func _on_file_changed(path: String):
	var object := EditorInterface.get_inspector().get_edited_object()
	if !object: return
	var script := object.get_script()
	if !script: return
	if script.resource_path == path: _reload_editor()


func _append_unless_exists(array: PackedStringArray, token: String):
	if array.has(token): return
	array.append(token)


func _cache_script_hidden_properties(script: Script) -> void:
	if !script: return
		
	var source := script.get_source_code()
	var hidden_properties: Dictionary = {
		inherits = null,
		hidden_properties = PackedStringArray(),
		hidden_groups = PackedStringArray(),
		hidden_categories = PackedStringArray(),
		categories_with_hidden = PackedStringArray()
	}
	
	for line in source.split("\n").slice(0, scanned_lines):
		if !("@unexport" in line): continue
		var matched = hide_properties_regex.search(line)
		if !matched: continue
		var tokens: PackedStringArray = matched.get_string(1).split(" ", false)
		
		# Rejoin quoted tokens that were split due to internal spaces
		for i in tokens.size():
			if i >= tokens.size(): break
			while true:
				var num_quotes = tokens[i].count('"')
				if num_quotes % 2 == 0: break
				tokens[i] += " %s" % tokens[i + 1]
				tokens.remove_at(i + 1)
			tokens[i] = tokens[i].replace('"', "")
		
		for token in tokens:
			# Group Unexporter
			if token.contains(">"):
				var category := token.split(">", false, 2)[0]
				_append_unless_exists(hidden_properties.hidden_groups, token)
				_append_unless_exists(hidden_properties.categories_with_hidden, category)
			# Wildcard (Category) Unexporter
			elif token.contains("*"):
				var category := token.split(":", false, 2)[0]
				_append_unless_exists(hidden_properties.hidden_categories, category)
				_append_unless_exists(hidden_properties.categories_with_hidden, category)
			# Property Unexporter
			else:
				var category := token.split(":", false, 2)[0]
				_append_unless_exists(hidden_properties.hidden_properties, token)
				_append_unless_exists(hidden_properties.categories_with_hidden, category)
		
		var base := script.get_base_script()
		if base:
			hidden_properties.inherits = base
			_cache_script_hidden_properties(base)

	hidden_properties_cache.set(script, hidden_properties)


func _get_hidden_control(script: Script, category_name: String) -> Control:
	var is_visible := _is_category_temporarily_visible(script, category_name)
	var new_control := hidden_properties_label.duplicate(true)
	new_control.get_child(0).get_child(0).text = label_properties_hidden if !is_visible else label_properties_visible
	new_control.icon = EditorInterface.get_editor_theme().get_icon("GuiVisibilityVisible", "EditorIcons") if !is_visible else EditorInterface.get_editor_theme().get_icon("GuiVisibilityHidden", "EditorIcons")
	new_control.pressed.connect(func() -> void:
		if is_visible:
			temporarily_visible_categories.get(script).erase(category_name)
		else:
			if !temporarily_visible_categories.has(script): temporarily_visible_categories.set(script, PackedStringArray())
			temporarily_visible_categories.get(script).append(category_name)
		_reload_editor()
	)
	return new_control


func _repopulate_class_name_map() -> void:
	for cur_class in ProjectSettings.get_global_class_list():
		gdscript_class_name_map.set(cur_class.path.get_file(), cur_class.class)


func _resolve_category_name(category_name: String) -> String:
	if !category_name.ends_with(".gd"): return category_name
	var cached := gdscript_class_name_map.get(category_name)
	if !cached: 
		_repopulate_class_name_map()
		cached = gdscript_class_name_map.get(category_name)
	if cached: return cached
	return category_name

func _is_category_temporarily_visible(script: Script, category_name: String) -> bool:
	var visible_for_script := temporarily_visible_categories.get(script)
	if !visible_for_script: return false
	return visible_for_script.has(category_name)


## Expects property name in the form of "Category:Property"
func _is_property_hidden(script: Script, property_name: String) -> bool:
	if _is_category_temporarily_visible(script, property_name.split(":")[0]): return false
	var hidden_properties := hidden_properties_cache.get(script)
	if !hidden_properties: return false
	if hidden_properties.hidden_properties.has(property_name): return true
	if hidden_properties.inherits: return _is_property_hidden(hidden_properties.inherits, property_name)
	return false


## Expects group name in the form of "Category>Group" (no quotes even if spaces)
func _is_group_hidden(script: Script, group_name: String) -> bool:
	if _is_category_temporarily_visible(script, group_name.split(">")[0]): return false
	var hidden_properties := hidden_properties_cache.get(script)
	if !hidden_properties: return false
	if hidden_properties.hidden_groups.has(group_name): return true
	if group_name.contains("/") and _is_group_hidden(script, group_name.substr(0, group_name.rfind("/"))): return true
	if hidden_properties.inherits and _is_group_hidden(hidden_properties.inherits, group_name): return true
	return false


## Expects category name as string
func _is_category_hidden(script: Script, category_name: String) -> bool:
	if _is_category_temporarily_visible(script, category_name): return false
	var hidden_properties := hidden_properties_cache.get(script)
	if !hidden_properties: return false
	if hidden_properties.hidden_categories.has(category_name): return true
	if hidden_properties.inherits: return _is_category_hidden(hidden_properties.inherits, category_name)
	return false


func _category_has_hidden(script: Script, category_name: String) -> bool:
	var hidden_properties := hidden_properties_cache.get(script)
	if !hidden_properties: return false
	if hidden_properties.categories_with_hidden.has(category_name): return true
	if hidden_properties.inherits: return _category_has_hidden(hidden_properties.inherits, category_name)
	return false


func _can_handle(object: Object) -> bool:
	var script := object.get_script()
	if script == null: return false
	_cache_script_hidden_properties(script)
	return true


func _parse_category(object: Object, category: String) -> void:
	category = _resolve_category_name(category)
	current_group = ""
	current_category = category
	var script := object.get_script()
	is_current_group_hidden = false
	is_current_category_hidden = _is_category_hidden(script, category)
	if _category_has_hidden(script, category) and show_hint_button:
		add_custom_control(_get_hidden_control(script, category))
	#print("PARSING CATEGORY ", category, " FOR OBJECT ", object)


func _parse_group(object: Object, group: String) -> void:
	current_group = group
	is_current_group_hidden = _is_group_hidden(object.get_script(), "%s>%s" % [ current_category, group ])
	#print("PARSING GROUP ", group, " FOR OBJECT ", object)


func _parse_property(
	object: Object,
	_type: Variant.Type,
	property_name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	if is_current_category_hidden or is_current_group_hidden: return true
	else: return _is_property_hidden(object.get_script(), "%s:%s" % [ current_category, property_name ])


func _parse_end(_object: Object) -> void:
	var inspector := EditorInterface.get_inspector()
	for child in inspector.get_children(): _hide_empty_inspector_groups(child)


func _get_group_num_children(node: Node, group_name: String) -> int:
	if node.get_class().begins_with("EditorProperty"): return 1
	else:
		var children: int = 0
		for child in node.get_children(): children += _get_group_num_children(child, group_name)
		return children


func _hide_empty_inspector_groups(node: Node) -> void:
	for child in node.get_children(): _hide_empty_inspector_groups(child)
	if node.get_class() == "EditorInspectorSection":
		var num_children := _get_group_num_children(node, node.tooltip_text)
		node.visible = num_children > 0
	# Matches category headers, but we don't want to mess with that since those are where the ignoring labels go.
	# elif node.get_class() == "EditorInspectorCategory":


func _reload_editor() -> void:
	var object := EditorInterface.get_inspector().get_edited_object()
	EditorInterface.inspect_object.call_deferred(null)
	EditorInterface.inspect_object.call_deferred(object)

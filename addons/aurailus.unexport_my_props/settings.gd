const SETTINGS_PATH := "addons/unexport_my_props/"

const SETTING_SHOW_HINT_BUTTON := SETTINGS_PATH + "show_unexported_props_hint_button"
const SETTING_HIGHLIGHT_LINES := SETTINGS_PATH + "highlight_detected_#@unexport_lines"
const SETTING_NUM_LINES := SETTINGS_PATH + "number_of_lines_to_scan"

func setup() -> void:
	_add_setting(SETTING_SHOW_HINT_BUTTON, TYPE_BOOL, true)
	_add_setting(SETTING_HIGHLIGHT_LINES, TYPE_BOOL, true)
	_add_setting(SETTING_NUM_LINES, TYPE_INT, 100)


func get_setting(key: String, default: Variant = null) -> Variant:
	return ProjectSettings.get_setting(key, default)


func _add_setting(path: String, type: Variant.Type, default: Variant, description: String = "") -> void:
	if !ProjectSettings.has_setting(path): ProjectSettings.set_setting(path, default)
	ProjectSettings.set_initial_value(path, default)
	ProjectSettings.add_property_info({ name = path, type = type, hint_string = description })

# Unexport my Props!

**Unexport my Props!** lets scripts selectively hide exported properties from inherited scripts from the Godot Inspector. Properties can be hidden individually, or by group or category. This is useful when an exported property from a base script breaks a child script if set. For example, if you add your own `Label` node to a custom `Button` scene, you're likely not expecting a user to use the base `Button`'s `text` property to be set, and that might end up breaking your scene in unexpected and confusing ways!

## How to Use

1) Install and enable the plugin by downloading this repo, or via the Godot Asset Store.
2) In your scene's script, write a comment of this format: `#@unexport BaseClass:property` and save the file!
3) `BaseClass:property` should now be hidden from the inspector!

## Advanced Usage

`#@unexport` supports any number of space-separated parameters, of one of three forms:

- `Category:property` - Hides a specific property from a category (categories can be a class, like "Button", or your own `@export_category(CategoryName)`. `property` should be written how it appears in code. e.g. If you have `@export var icon_size`, you should write `icon_size`, **even if in the inspector** it displays as "Icon Size". If a category has spaces, you must wrap it in double-quotes (`"My Category"`).
- `Category>Group` - Hides all properties in a group. If the category or group have spaces, they must be wrapped in double-quotes. Note the use of `>` instead of `:` to identify groups instead of properties!
- `Category:*` - Hides all properties in a given category, including those in groups.

Subgroups can be specified by using a `/` character. For example, if you have the category "Category", a group within called "Group", and a subgroup called "Sub Group", you can hide the contents of "Sub Group" with `#@unexport Category>"Group/Sub Group"` (note the quotes surrounding the **entire** group expression).

Example using all three forms:

```gdscript
#@unexport Button:text Button>"Text Behavior" BaseButton:*
```

When a category has `#@unexport`ed properties, a small label will appear beneath the category label indicating that some properties are hidden. Clicking this label will temporarily show all properties, including `#@unexport`ed ones, for the session. You can click it again to hide them.

If a script inherits from another script, the parent script will also be scanned for `#@unexport` declarations.

## Configuring

Plugin configuration options are located in Project Settings under `Addons > Unexport My Props`. The default configuration should work for most use-cases, but see the options below if you want to customize its behaviour:

- `Show Unexported Props Hint Button` - If enabled (which is the default), any Category that has hidden exports will show a little bannner indicating this. The banner can be clicked to temporarily show the hidden exports. If disabled, this banner will not appear. WARNING: If disabled, there is no way to see hidden exports aside from re-enabling this or disabling the plugin!
- `Highlight Detected #@unexport Lines` - If enabled, any detected `#@unexport` annotations will be highlighted in orange.
- `Number of Lines to Scan` - The number of lines in a file to scan for `#@unexport` annotations. The default is 100, which should be sufficient for most scripts. You can increase this to an arbitrarily large number (e.g. 9999999) to scan the entire file, but be warned that this may have a performance impact on extremely large scripts.

## Limitations

- By default, only the first 100 lines of a given file are scanned for `#@unexport` declarations. This can be configured.
- If you have multiple categories with the same name (e.g. using `@export_category` on multiple classes), all of them will be hidden or unhidden at once. It is not possible to hide a category only for a specific class.
- `#@unexport` is a comment, not an annotation, as it is not currently possible to create custom annotations.

## Other Plugins

Check out my [Folder Jump](https://github.com/EffortGames/GodotFolderJump) plugin which improves Filesystem ergonomics by adding a "Jump Button" to folders which lets you quickly access the primary file in the directory, and my [Workspace Navigator](https://github.com/EffortGames/GodotWorkspaceNavigator) plugin which automatically focuses the correct workspace (2D, 3D, Script) when a file is opened, and provides a shortcut to jump straight to a scene's script from the filesystem!

## License

This project is licensed under GPLv3, see the license file for details. This does NOT mean that your project must be licensed under GPLv3, since the plugin does not write any code into your project that would be exported, nor does your project become a derivative work. You can use any license for your project that you like, no credit necessary. But if you find **Unexport my Props!** valuable, including a credit to **Auri Collings** would be much appreciated!

## Update History

### 1.0.2

- Added an option to hide the hidden properties banner.
- Added an option to change the number of lines scanned for `#@unexport` declarations.
- Added an option to toggle-off highlighting `#@unexport` lines.
- Added an options page in the Project Settings.
- Moved the repo to `EffortGames/GodotUnexportMyProps`
- Renamed the plugin from `unexport` to `aurailus.unexport_my_props`. Please make sure you uninstall the old plugin to avoid conflicts.

### 1.0.1

- Increased the number of lines scanned for #@unexport declarations to 100.
- Made the inspector reload automatically if the script that's being edited is attached to the inspected node. (Fixes needing to swap to a different node and then back to update hidden items.)
- Made empty groups not render in the inspector. (Fixes empty groups remaining visible when all items are hidden.)

### 1.0.0

- Initial Release

## Contributing

If you would like to contribute to this plugin, please open an issue or a pull request. I am happy to accept bug fixes and documentation improvements, however new features will only be considered if they do not substantially increase the maintenance complexity. Please make sure to follow the code style and conventions used in the plugin when contributing.

&nbsp;

**Copyright [Auri Collings](https://github.com/Aurailus) 2026. Made with ❤️.**

Thumbnail background pattern by [Hero Patterns](https://heropatterns.com/), licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

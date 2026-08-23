# Unexport my Props!

**Unexport my Props!** lets scenes selectively hide exported properties from inherited classes from the Godot Inspector. Properties can be hidden individually, or by group or category. This is useful when an exported property from a base class breaks a child class if set. For example, if you add your own `Label` node to a custom `Button` scene, you're likely not expecting a user to use the base `Button`'s `text` property to be set, and that might end up breaking your class in unexpected and confusing ways!

## How to Use

1) Install and enable the plugin by downloading this repo, or via the Godot Asset Store.
2) In your scene's Script file, include a comment of this format: `#@unexport BaseClass:property`
3) Swap the inspector to a different node and back again to update it.
4) `BaseClass:property` should now be hidden from the inspector!

## Advanced Usage

`#@unexport` supports any number of space-separated parameters, of one of three forms:

- `Category:property` - Hides a specific property from a category (Categories can be a class, like "Button", or your own `@export_category(CategoryName)`. `property` should be written how it appears in code. e.g. If you have `@export var icon_size`, you should write `icon_size`, **even if in the inspector** it displays as "Icon Size". If a category has spaces, you must wrap it in double-quotes (`"My Category"`).
- `Category>Group` - Hides all properties in a group. If the category or group have spaces, they must be wrapped in double-quotes. Note the use of `>` instead of `:` to identify groups instead of properties!
- `Category:*` - Hides all properties in a given category, including those in groups.

Subgroups can be specified by using a `/` character. For example, if you have the category "Category", a group within called "Group", and a subgroup called "Sub Group", you can hide the contents of "Sub Group" with `#@unexport Category>"Group/Sub Group"` (note the quotes surrounding the **entire** group expression).

Example using all three forms:
```
#@unexport Button:text Button>"Text Behavior" BaseButton:*
```

When a category has `#@unexport`ed properties, a small label will appear beneath the category label indicating that some properties are hidden. Clicking this label will temporarily show all properties, including `#@unexport`ed ones, for the session. You can click it again to hide them.

If a script inherits from another script, the parent script will also be scanned for `#@unexport` declarations.

## Limitations

- Only the first 30 lines of a given file are scanned for `#@unexport` declarations to save on processing time.
- Because of the way Godot InspectorPlugins work, groups and categories themselves can't be hidden. If you unexport all properties from a group or category, the label will remain, but it will have no members. This isn't possible to circumvent currently.
- If you have multiple categories with the same name (e.g. using `@export_category` on multiple classes), all of them will be hidden or unhidden at once. It is not possible currently hide a category only a specific class.
- `#@unexport` is a comment, not an annotation, as it is not currently possible to create custom annotations.

This project is licensed under GPLv3. This does NOT mean that your project must be licensed under GPLv3, since the plugin does not write any code into your project that would be exported, nor does your project become a derivative work. You can use any license for your project that you like, no credit necessary. But if you find **Unexport my Props!** valuable, including a credit to **Auri Collings** would be much appreciated!

## Contributing

If you would like to contribute to this library, please open an issue or a pull request. I am happy to accept bug fixes and documentation improvements, however new features will only be considered if they do not substantially increase the maintenance complexity. Please make sure to follow the code style and conventions used in the library when contributing.



**Copyright [Auri Collings](https://github.com/Aurailus) 2026. Made with ❤️.**

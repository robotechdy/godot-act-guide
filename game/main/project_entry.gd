class_name ProjectEntry
extends Resource
## One experiment or tutorial chapter, configured on the main scene.

@export var title: String = ""
@export_multiline var summary: String = ""
@export var scene: PackedScene

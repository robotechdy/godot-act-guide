extends Node3D
## Instance fields survive removal from the tree, but not destruction.

var enter_count: int = 0
var ready_count: int = 0


func _enter_tree() -> void:
	enter_count += 1
	print("%s #%d: enter_tree (%d)" % [name, get_instance_id(), enter_count])


func _ready() -> void:
	ready_count += 1
	print("%s #%d: ready (%d)" % [name, get_instance_id(), ready_count])


func _exit_tree() -> void:
	print("%s #%d: exit_tree" % [name, get_instance_id()])

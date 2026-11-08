extends Control

const ActorScene = preload("res://game/tutorials/01_scene_tree/actor.tscn")
@onready var instances: Node = $Instances
@onready var status: Label = $Margin/Rows/Status
@onready var tree_text: RichTextLabel = $Margin/Rows/TreeText
var detached: Node3D
var serial: int = 0
var last_action: String = "No instances yet. Create one to begin."


func _ready() -> void:
	$Margin/Rows/Actions/Create.pressed.connect(create_actor)
	$Margin/Rows/Actions/Detach.pressed.connect(detach_actor)
	$Margin/Rows/Actions/Reattach.pressed.connect(reattach_actor)
	$Margin/Rows/Actions/Destroy.pressed.connect(destroy_actor)
	refresh()


func create_actor() -> void:
	if instances.get_child_count() >= 6:
		last_action = "Keep this experiment small: destroy an actor before adding more."
		refresh()
		return
	var actor := ActorScene.instantiate()
	serial += 1
	actor.name = "Actor_%02d" % serial
	# instantiate() creates the subtree; add_child() enters the active tree.
	instances.add_child(actor)
	last_action = "Created %s from the same PackedScene." % actor.name
	refresh()


func detach_actor() -> void:
	if is_instance_valid(detached) or instances.get_child_count() == 0:
		return
	detached = instances.get_child(-1)
	instances.remove_child(detached)
	last_action = "Detached %s. The object is still alive." % detached.name
	refresh()


func reattach_actor() -> void:
	if not is_instance_valid(detached):
		return
	var actor := detached
	detached = null
	instances.add_child(actor)
	last_action = "Reattached %s: same ID, enter_tree again, ready still once." % actor.name
	refresh()


func destroy_actor() -> void:
	var actor: Node
	if is_instance_valid(detached):
		actor = detached
		detached = null
	elif instances.get_child_count() > 0:
		actor = instances.get_child(-1)
	else:
		return
	last_action = "Queued %s for destruction at the end of this frame." % actor.name
	actor.queue_free()
	refresh()
	# Refresh after deletion; do not keep an invalid object reference.
	await get_tree().process_frame
	refresh()


func refresh() -> void:
	var current := get_tree().current_scene
	var current_name := str(current.name) if current != null else "(test harness)"
	status.text = "%s
Runtime current_scene: %s | Actors in tree: %d | Detached: %s" % [last_action, current_name, instances.get_child_count(), str(is_instance_valid(detached))]
	var rows := PackedStringArray(["Active subtree: %s" % instances.get_path(), ""])
	append_node(instances, 0, rows)
	if is_instance_valid(detached):
		rows.append("
Detached subtree (alive, no longer in SceneTree):")
		append_node(detached, 0, rows)
	tree_text.text = "
".join(rows)


func append_node(node: Node, depth: int, rows: PackedStringArray) -> void:
	var owner_name := str(node.owner.name) if node.owner != null else "none"
	var detail := ""
	if node.get_script() == preload("res://game/tutorials/01_scene_tree/actor.gd"):
		detail = " | enter=%d ready=%d" % [node.enter_count, node.ready_count]
	rows.append("%s%s : %s | id=%d | owner=%s | inside_tree=%s%s" % ["  ".repeat(depth), node.name, node.get_class(), node.get_instance_id(), owner_name, str(node.is_inside_tree()), detail])
	for child in node.get_children():
		append_node(child, depth + 1, rows)


func _exit_tree() -> void:
	# Detached nodes are no longer children, so we must release them explicitly.
	if is_instance_valid(detached):
		detached.free()
		detached = null

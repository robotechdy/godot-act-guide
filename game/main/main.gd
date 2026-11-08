extends Node

@export var entries: Array[ProjectEntry] = []

@onready var content: Node = $Content
@onready var menu: Control = $Navigation/Menu
@onready var items: VBoxContainer = $Navigation/Menu/Scroll/Items
@onready var toolbar: Control = $Navigation/Toolbar
@onready var heading: Label = $Navigation/Toolbar/Buttons/Heading
var current_index: int = -1


func _ready() -> void:
	$Navigation/Toolbar/Buttons/Reset.pressed.connect(_reset)
	$Navigation/Toolbar/Buttons/Home.pressed.connect(_home)
	for index in entries.size():
		var entry := entries[index]
		if entry == null or entry.scene == null or entry.title.is_empty():
			push_error("Entry %d needs a title and a scene." % index)
			continue
		var button := Button.new()
		button.text = entry.title
		button.pressed.connect(_open.bind(index))
		items.add_child(button)
		var description := Label.new()
		description.text = entry.summary
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		items.add_child(description)
	if entries.is_empty():
		var notice := Label.new()
		notice.text = "Add experiments or chapters to Main.entries."
		items.add_child(notice)
	_home()


func _clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _open(index: int) -> void:
	_clear()
	current_index = index
	menu.hide()
	toolbar.show()
	heading.text = entries[index].title
	content.add_child(entries[index].scene.instantiate())


func _reset() -> void:
	if current_index >= 0:
		_open(current_index)


func _home() -> void:
	_clear()
	current_index = -1
	toolbar.hide()
	menu.show()

extends PanelContainer

const CounterState = preload("res://game/tutorials/02_scripts_and_composition/counter_state.gd")
@export var caption: String = "Counter"
@onready var state: CounterState = $State
@onready var value_label: Label = $Rows/Value


func _ready() -> void:
	$Rows/Title.text = caption
	$Rows/Identity.text = "Node instance: %d
State instance: %d" % [get_instance_id(), state.get_instance_id()]
	$Rows/Add.pressed.connect(state.increment)
	$Rows/Clear.pressed.connect(state.reset)
	state.changed.connect(update_value)
	update_value(state.value)


func update_value(value: int) -> void:
	value_label.text = str(value)

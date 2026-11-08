extends Node
## Node composition example; pure data could instead use RefCounted or Resource.

signal changed(value: int)
var value: int = 0


func increment() -> void:
	value += 1
	changed.emit(value)


func reset() -> void:
	value = 0
	changed.emit(value)

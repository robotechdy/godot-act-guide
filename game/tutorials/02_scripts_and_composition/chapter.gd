extends Control


func _ready() -> void:
	var a := $Margin/Rows/Counters/A
	var b := $Margin/Rows/Counters/B
	$Margin/Rows/Identity.text = "Same counter.gd resource: %s
Same Node instance: %s
Each Counter owns a separate State child. Buttons call State; its changed signal updates the label." % [str(a.get_script() == b.get_script()), str(a == b)]

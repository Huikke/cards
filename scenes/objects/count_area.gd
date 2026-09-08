extends Area2D

var count: int = 0

func _on_area_entered(_area: Area2D) -> void:
	count += 1
	update_label()


func _on_area_exited(_area: Area2D) -> void:
	count -= 1
	update_label()

func update_label():
	$Label.text = "Count: " + str(count)

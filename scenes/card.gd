extends Area2D

signal clicked
@export var value: int
@export var suit: String

func _on_input_event(viewport, event, shape_idx):
		if event is InputEventMouseButton and event.pressed:
			clicked.emit(self)

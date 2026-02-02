extends Node2D

signal card_entered
	

func _on_area_2d_area_entered(area):
	card_entered.emit(area)
	area.queue_free()

extends Node2D

var card_scene = preload("res://scenes/objects/card.tscn")
signal card_entered(Area2D, int)

func _ready():
	$Hands.change_card_overlap(40)

func _on_area_entered(object, area):
	if object is not Card:
		return
	var p: int
	if area == $AreaP1:
		p = 0
	elif area == $AreaP2:
		p = 1
	card_entered.emit(object, p)
	object.queue_free()

func _on_hands_card_selected(card_ui):
	var card_ow = card_scene.instantiate() # ow == Overworld
	card_ow.position = get_viewport().get_camera_2d().position
	card_ow.value = card_ui.value
	card_ow.suit = card_ui.suit

	$Objects.add_child(card_ow)
	card_ui.queue_free()

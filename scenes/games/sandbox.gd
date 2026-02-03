extends Node2D

var card_scene = preload("res://scenes/objects/card.tscn")
signal card_entered(Area2D, int)

func _on_area_entered(card, area):
	var p: int
	if area == $AreaP1:
		p = 0
	elif area == $AreaP2:
		p = 1
	card_entered.emit(card, p)
	card.queue_free()

func _on_hud_card_selected(card_ui):
	var card_ow = card_scene.instantiate() # ow == Overworld
	card_ow.position = get_viewport_rect().size / 2
	card_ow.value = card_ui.value
	card_ow.suit = card_ui.suit

	add_child(card_ow)
	card_ui.queue_free()

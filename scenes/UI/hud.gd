extends CanvasLayer


func _on_main_card_entered(incoming_card):
	var card = $HandLocation/PhysicalCard.duplicate()
	var url = str(incoming_card.value) + "_" + incoming_card.suit + ".svg"
	card.get_child(0).texture = load("res://graphics/cards/front/" + url)
	card.visible = true
	$HandLocation.add_child(card)

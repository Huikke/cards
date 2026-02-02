extends CanvasLayer



func _on_main_card_entered(card_i):
	var p = 1
	add_card_to_hand(card_i, p)

func _on_deck_deal_signal(card_i, p):
	add_card_to_hand(card_i, p)


func add_card_to_hand(card_i, p): # card_i = card_incoming, p = player
	var path = "res://assets/cards/front/"
	var hand = get_node("P" + str(p + 1) + "_Hand")
	var card_o = hand.get_child(0).duplicate()
	card_o.get_child(0).texture = load(path + str(card_i.value) + "_" + card_i.suit + ".svg")
	card_o.visible = true
	hand.add_child(card_o)

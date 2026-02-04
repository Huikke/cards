extends CanvasLayer

signal card_selected

func _ready():
	await get_tree().create_timer(0.3).timeout
	$P2_Hand/PhysicalCard/CardSprite.flip_h = true
	$P2_Hand/PhysicalCard/CardSprite.flip_v = true


func _on_card_to_hand(card_i, p): # card_i = card_incoming, p = player
	var path = "res://assets/cards/front/perfectionism/"
	var node_str = "P" + str(p + 1) + "_Hand"
	var hand = get_node(node_str)
	var card_o = hand.get_child(0).duplicate()
	card_o.visible = true

	if p == 0:
		card_o.get_child(0).texture = load(path + str(card_i.value) + "_" + card_i.suit + ".svg")
	else:
		card_o.get_child(0).texture = card_i.back_sprite
	card_o.value = card_i.value
	card_o.suit = card_i.suit
	card_o.pnum = p

	hand.add_child(card_o)
	hand.move_child(get_node(node_str + "/FrontCardPadding"), -1)

func _on_card_gui_input(event, card_ui):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		card_selected.emit(card_ui)


func change_card_overlap(custom_size):
	for hand in get_children():
		var first = true
		var invisible_card
		for card in hand.get_children():
			if card is PhysicalCard:
				card.custom_minimum_size.x = custom_size
			if first:
				invisible_card = card
				first = false
			if card is CardPadding:
				# -4 is BoxContainer leftover space
				var free_space = invisible_card.get_child(0).size.x - custom_size - 4
				if free_space > 0:
					card.visible = true
					card.custom_minimum_size.x = free_space
				else:
					card.visible = false

func _on_card_size_slider_changed(value):
	change_card_overlap(value)

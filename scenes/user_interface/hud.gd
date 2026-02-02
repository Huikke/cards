extends CanvasLayer

signal card_selected

func _ready():
	await get_tree().create_timer(0.3).timeout
	$P2_Hand/PhysicalCard/TextureRect.flip_h = true
	$P2_Hand/PhysicalCard/TextureRect.flip_v = true

func _on_main_card_entered(card_i):
	var p = 1
	add_card_to_hand(card_i, p)

func _on_deck_deal_signal(card_i, p):
	add_card_to_hand(card_i, p)


func add_card_to_hand(card_i, p): # card_i = card_incoming, p = player
	var path = "res://assets/cards/front/"
	var hand = get_node("P" + str(p + 1) + "_Hand")
	var card_o = hand.get_child(0).duplicate()
	card_o.visible = true
	
	if p == 0:
		card_o.get_child(0).texture = load(path + str(card_i.value) + "_" + card_i.suit + ".svg")
	else:
		card_o.get_child(0).texture = card_i.back_sprite
	card_o.value = card_i.value
	card_o.suit = card_i.suit

	hand.add_child(card_o)


func _on_card_gui_input(event, ui_card):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		card_selected.emit(ui_card)

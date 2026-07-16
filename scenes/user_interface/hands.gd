extends CanvasLayer

signal card_selected

var texture_path = "res://assets/cards/front/perfectionism/"

func _ready():
	await get_tree().create_timer(0.3).timeout


func _on_card_to_hand(card_i, p): # card_i = card_incoming, p = player
	var node_str = "P" + str(p) + "_Hand"
	var hand_content = get_node(node_str).get_child(0)
	var card_o = hand_content.get_child(0).duplicate()
	card_o.visible = true

	if p == 0:
		card_o.get_child(0).texture = load(texture_path + str(card_i.value) + "_" + card_i.suit + ".svg")
		card_o.face_up = true
	else:
		card_o.get_child(0).texture = card_i.back_sprite
		card_o.face_up = false
	card_o.value = card_i.value
	card_o.suit = card_i.suit
	card_o.pnum = p # Prevents playing other people's cards
	card_o.back_sprite = card_i.back_sprite

	hand_content.add_child(card_o)
	hand_content.move_child(get_node(node_str + "/HandContainer/FrontCardPadding"), -1)

func _on_card_gui_input(event, card_ui):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		card_selected.emit(card_ui)

func get_hand_content(player: int):
	var node_str = "P" + str(player) + "_Hand"
	var hand = get_node(node_str).get_child(0).get_children()
	var hand_list = []
	for card in hand:
		if card is PhysicalCard and card.value != 0:
			hand_list.append([card.value, card.suit])
	return hand_list

func change_card_overlap(custom_size):
	for hand in get_children():
		var first = true
		var invisible_card
		for card in hand.get_child(0).get_children():
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

func flip_hand(player: int):
	var node_str = "P" + str(player) + "_Hand/HandContainer"
	var hand_cards = get_node(node_str).get_children()
	for card in hand_cards:
		if card is CardPadding:
			pass
		elif card.visible == true:
			if card.face_up == false:
				card.get_child(0).texture = load(texture_path + str(card.value) + "_" + card.suit + ".svg")
				card.face_up = true
			elif card.face_up == true:
				card.get_child(0).texture = card.back_sprite
				card.face_up = false

# Sandbox only
func _on_card_size_slider_changed(value):
	change_card_overlap(value)

# Sandbox only
func _on_flipper_pressed():
	flip_hand(0)

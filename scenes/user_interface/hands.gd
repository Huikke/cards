extends CanvasLayer

signal card_selected

var texture_path = "res://assets/cards/front/perfectionism/"
var player_cards_face_up_list: Array[bool]
var ui_card = preload("res://scenes/user_interface/ui_card.tscn").instantiate()
var card_size = Vector2(120, 168)

var seat_setup: Array
@onready var SEAT_SETUPS = [
	[],
	[$H00],
	[$H00, $H20],
	[$H00, $H10, $H20],
	[$H00, $H10, $H20, $H30],
	[$H01, $H02, $H10, $H20, $H30],
	[$H01, $H02, $H10, $H21, $H22, $H30],
	[$H01, $H02, $H11, $H12, $H21, $H22, $H30],
	[$H01, $H02, $H11, $H12, $H21, $H22, $H31, $H32]
]

func _ready():
	set_seat_size(4)

func set_seat_size(size):
	seat_setup = SEAT_SETUPS[size]
	player_cards_face_up_list.resize(len(seat_setup))
	player_cards_face_up_list.fill(false)
	if !Global.mp_enabled:
		player_cards_face_up_list[0] = true


func _on_card_to_hand(card_i, player: int) -> void:
	var hand_content = seat_setup[player].get_child(0)

	var card_o = ui_card.duplicate()
	card_o.value = card_i.value
	card_o.suit = card_i.suit
	card_o.pnum = player # Prevents playing other people's cards
	card_o.back_sprite = card_i.back_sprite
	if player_cards_face_up_list[player]:
		card_o.get_child(0).texture = load(texture_path + str(card_i.value) + "_" + card_i.suit + ".svg")
		card_o.face_up = true
	else:
		card_o.get_child(0).texture = load(card_o.back_sprite)
		card_o.face_up = false
	card_o.gui_input.connect(_on_card_gui_input.bind(card_o))

	# Card Animation
	var card_sprite = card_o.get_node("CardSprite")
	var tween = create_tween()
	card_sprite.position += Vector2(0, 84)
	tween.tween_property(card_sprite, "position", card_sprite.position - Vector2(0, 84), 0.2)

	hand_content.add_child(card_o)
	hand_content.move_child(seat_setup[player].get_node("HandContainer/CardPadding"), -1)

func _on_card_gui_input(event, card_ui):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		card_selected.emit(card_ui)

func get_hand_content(player: int):
	var hand = seat_setup[player].get_child(0).get_children()
	var hand_list = []
	for card in hand:
		if card is UiCard and card.value != 0:
			hand_list.append([card.value, card.suit])
	return hand_list

func change_card_overlap(custom_size):
	# Changes size for future cards
	ui_card.custom_minimum_size.x = custom_size

	# Changes size for current cards
	for hand in get_children():
		for card in hand.get_child(0).get_children():
			if card is UiCard:
				card.custom_minimum_size.x = custom_size
			if card.name == "CardPadding":
				# -4 is BoxContainer leftover space
				var free_space = card_size.x - custom_size - 4
				if free_space > 0:
					card.visible = true
					card.custom_minimum_size.x = free_space
				else:
					card.visible = false

func face_dir_default(player, is_face_up):
	player_cards_face_up_list[player] = is_face_up

func flip_hand(player: int):
	var hand_cards = seat_setup[player].get_node("HandContainer").get_children()
	for card in hand_cards:
		if card.name == "CardPadding":
			pass
		elif card is UiCard:
			if card.face_up == false:
				card.get_child(0).texture = load(texture_path + str(card.value) + "_" + card.suit + ".svg")
				card.face_up = true
			elif card.face_up == true:
				card.get_child(0).texture = load(card.back_sprite)
				card.face_up = false

@rpc("authority")
func clear_hand(player):
	if Global.mp_enabled and multiplayer.is_server():
		clear_hand.rpc(player)
	var hand = seat_setup[player].get_child(0).get_children()
	for card in hand:
		if card is UiCard:
			card.queue_free()

func clear_hands():
	for player in range(2):
		clear_hand(player)

func change_hand_heads_up_text(player, text):
	seat_setup[player].get_node("PlayerHeadsUpLabel").text = text

# Sandbox only
func _on_card_size_slider_changed(value):
	change_card_overlap(value)

# Sandbox only
func _on_flipper_pressed():
	for i in range(4):
		flip_hand(i)

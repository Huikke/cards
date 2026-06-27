extends Node2D

var pk_logic = poker_logic.new()

var table_cards = []
var phase = 0

var card_placement: Vector2

func _ready():
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	$Hands.change_card_overlap(120)
	$Deck.deck_shuffle()
	await get_tree().create_timer(0.3).timeout
	for card in range(2): # Card amount
		for player in range(4): # Player amount
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(player)
	
	for card in range(5):
		await get_tree().create_timer(0.25).timeout
		$Deck.deal("table")
	
	GlobalSignal.fold.connect(_on_fold)
	GlobalSignal.call.connect(_on_call)
	GlobalSignal.raise.connect(_on_raise)
	
	pk_logic.player_turn.connect(_on_player_turn)
	pk_logic.next_phase.connect(_on_next_phase)
	pk_logic.game_begin()

func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	table_cards.append(card)

func _on_player_turn():
	$ButtonsLayer.visible = true

func _on_next_phase():
	phase += 1
	if phase == 1:
		table_cards[0].flip_card()
		table_cards[1].flip_card()
		table_cards[2].flip_card()
	if phase == 2:
		table_cards[3].flip_card()
	if phase == 3:
		table_cards[4].flip_card()
	if phase == 4:
		showdown()
		return
	# var starting_player = (Global.starting_player + 2) % 4
	pk_logic.round_manager(Global.starting_player)

func _on_fold(player):
	$Hands.get_node("P" + str(player) + "_Hand/Indicator").color = Color("Red")
	if player == 0:
		pk_logic.round_manager(1)

func _on_call(player):
	$Hands.get_node("P" + str(player) + "_Hand/Indicator").color = Color("Lime_Green")
	if player == 0:
		pk_logic.round_manager(1)

func _on_raise(player):
	$Hands.get_hand_content()
	$Hands.get_node("P" + str(player) + "_Hand/Indicator").color = Color("Blue")

func showdown():
	for player in range(0,4):
		if player not in Global.folded:
			# WIP
			$Hands.get_hand_content()
			pass

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

	game_begin()

func game_begin():
	var starting_player = randi_range(0, 3)
	print("starting player: ", starting_player)
	Global.starting_player = starting_player
	Global.current_turn = 0
	game_loop(starting_player)

func game_loop(player: int):
	while true:
		await get_tree().create_timer(0.5).timeout
		var escape = pk_logic.turn(player)
		if escape == 0:
			player_turn()
			break
		elif escape == -1:
			await get_tree().create_timer(1).timeout
			next_phase()
			break
		elif escape == -2:
			pass
		player = (player + 1) % 4


func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	table_cards.append(card)

func player_turn():
	$ButtonsLayer.visible = true

func next_phase():
	phase += 1
	if phase == 1:
		table_cards[0].flip_card()
		table_cards[1].flip_card()
		table_cards[2].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 2"
		color_reset()
	elif phase == 2:
		table_cards[3].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 3"
		color_reset()
	elif phase == 3:
		table_cards[4].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 4"
		color_reset()
	elif phase == 4:
		$ExtraLayer/RoundLabel.text = "Showdown"
		showdown()
		return
	else:
		$ExtraLayer/RoundLabel.text = "Error"
		print("overtime!")
	# var starting_player = (Global.starting_player + 2) % 4
	game_loop(Global.starting_player)
	

func _on_fold(player):
	$Hands.get_node("P" + str(player) + "_Hand/Indicator").color = Color("Red")
	if player == 0:
		game_loop(1) # Change needed in mp

func _on_call(player):
	$Hands.get_node("P" + str(player) + "_Hand/Indicator").color = Color("Lime_Green")
	if player == 0:
		game_loop(1) # Change needed in mp

func _on_raise(player):
	$Hands.get_hand_content()
	$Hands.get_node("P" + str(player) + "_Hand/Indicator").color = Color("Blue")

func color_reset():
	for i in range(4):
		$Hands.get_node("P" + str(i) + "_Hand/Indicator").color = Color("Gray")


func showdown():
	for player in range(0,4):
		if player not in Global.folded:
			$Hands.flip_hand(player)

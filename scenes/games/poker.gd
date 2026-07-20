extends Node2D

var pk_logic = poker_logic.new()

var table_cards_physical = []
var table_cards_data = []
var phase = 0

var card_placement: Vector2

var hand_types = ["Folded", "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"]

var min_bet = 400
var current_bet = 0
var pot = 0

func _ready():
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	$Hands.change_card_overlap(120)
	
	GlobalSignal.fold.connect(_on_fold)
	GlobalSignal.call.connect(_on_call)
	GlobalSignal.raise.connect(_on_raise)

	var starting_player = randi_range(0, 3)

	game_begin(starting_player, 4)

func game_begin(starting_player, player_amount):
	current_bet = min_bet
	$Deck.deck_shuffle()
	await get_tree().create_timer(0.3).timeout
	for card in range(2): # Card amount
		for player in range(player_amount): # Player amount
			player = (starting_player + player) % player_amount
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(player)

	for card in range(5):
		await get_tree().create_timer(0.2).timeout
		$Deck.deal("table")

	var blind_halfer = 2
	for player in range(2):
		player = (starting_player + player) % player_amount
		await get_tree().create_timer(0.2).timeout
		@warning_ignore("integer_division")
		pot += $Hands.get_node("P" + str(player) + "_Hand").bet(min_bet/blind_halfer)
		$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/PanelContainer/MarginContainer/CurrencyLabel").text = str($Hands.get_node("P" + str(player) + "_Hand").money) + " €"
		update_pot()
		blind_halfer = 1

	print("starting player: ", starting_player)
	Global.starting_player = starting_player
	Global.current_turn = 0
	game_loop((starting_player + 2) % player_amount)

func game_loop(player: int):
	while true:
		await get_tree().create_timer(0.3).timeout
		var escape = pk_logic.turn(player)
		if len(Global.folded) == 3:
			uncontested_win()
			break
		elif escape == 0:
			player_turn()
			break
		elif escape == -1:
			await get_tree().create_timer(0.5).timeout
			next_phase()
			break
		elif escape == -2:
			pass
		player = (player + 1) % 4


func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	table_cards_physical.append(card)
	table_cards_data.append([card.value, card.suit])

func player_turn():
	$ButtonsLayer.visible = true

func next_phase():
	phase += 1
	if phase == 1:
		table_cards_physical[0].flip_card()
		table_cards_physical[1].flip_card()
		table_cards_physical[2].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 2"
		indicator_reset()
	elif phase == 2:
		table_cards_physical[3].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 3"
		indicator_reset()
	elif phase == 3:
		table_cards_physical[4].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 4"
		indicator_reset()
	elif phase == 4:
		$ExtraLayer/RoundLabel.text = "Showdown"
		showdown()
		return
	else:
		$ExtraLayer/RoundLabel.text = "Error"
		push_error("Round overflow")
	# var starting_player = (Global.starting_player + 2) % 4
	game_loop(Global.starting_player)
	

func _on_fold(player):
	$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/MarginContainer/Indicator").color = Color("Red")
	$Hands.get_node("P" + str(player) + "_Hand/LabelPanel/PlayerLabel").text = "Fold"

	if player == 0:
		game_loop(1) # Change needed in mp

func _on_call(player):
	var indicator = $Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/MarginContainer/Indicator")

	if indicator.color != Color("Lime_Green"):
		indicator.color = Color("Lime_Green")
	else:
		indicator.modulate *= 1.5

	$Hands.get_node("P" + str(player) + "_Hand/LabelPanel/PlayerLabel").text = "Call"

	pot += $Hands.get_node("P" + str(player) + "_Hand").bet(current_bet)
	$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/PanelContainer/MarginContainer/CurrencyLabel").text = str($Hands.get_node("P" + str(player) + "_Hand").money) + " €"
	update_pot()

	if player == 0:
		game_loop(1) # Change needed in mp

func _on_raise(player):
	$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/MarginContainer/Indicator").color = Color("Blue")
	$Hands.get_node("P" + str(player) + "_Hand/LabelPanel/PlayerLabel").text = "Raise"

	current_bet += min_bet
	Global.current_turn = 1

	pot += $Hands.get_node("P" + str(player) + "_Hand").bet(current_bet)
	$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/PanelContainer/MarginContainer/CurrencyLabel").text = str($Hands.get_node("P" + str(player) + "_Hand").money) + " €"
	update_pot()

	if player == 0:
		game_loop(1) # Change needed in mp

func indicator_reset():
	for player in range(4):
		if player not in Global.folded:
			$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/MarginContainer/Indicator").color = Color("Gray")
			$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/MarginContainer/Indicator").modulate = Color(1, 1, 1)
			$Hands.get_node("P" + str(player) + "_Hand/LabelPanel/PlayerLabel").text = ""


func update_pot():
	$ExtraLayer/PotLabel.text = "Pot: " + str(pot) + " €"


func showdown():
	var poker_hand_list = []

	for player in range(4):
		if player not in Global.folded:
			if player != 0: # Change needed in mp
				$Hands.flip_hand(player)
			var hand_and_river = $Hands.get_hand_content(player) + table_cards_data
			var poker_hand = pk_logic.check_hand(hand_and_river)
			$Hands.get_node("P" + str(player) + "_Hand/LabelPanel/PlayerLabel").text = hand_types[poker_hand[0]]
			poker_hand_list.append(poker_hand)
			print(poker_hand)
		else:
			poker_hand_list.append([0, null])

	var winners = []
	var best_hand
	var player = 0
	for poker_hand in poker_hand_list:
		if winners.is_empty():
			best_hand = poker_hand
			winners.append(player)
		else:
			var result = pk_logic.compare_hand(best_hand, poker_hand)
			if result == 2:
				best_hand = poker_hand
				winners.clear()
				winners.append(player)
			elif result == 0:
				winners.append(player)
		player += 1
	
	if len(winners) == 1:
		await get_tree().create_timer(1).timeout
		$ExtraLayer/RoundLabel.text = "Player " + str(winners[0] + 1) + " Wins!"
		$Hands.get_node("P" + str(winners[0]) + "_Hand").win(pot)
		$Hands.get_node("P" + str(winners[0]) + "_Hand/HBoxContainer/PanelContainer/MarginContainer/CurrencyLabel").text = str($Hands.get_node("P" + str(winners[0]) + "_Hand").money) + " €"
	else:
		# WIP
		$ExtraLayer/RoundLabel.text = "It's a Tie!"

func uncontested_win():
	for player in range(4):
		if player not in Global.folded:
			$ExtraLayer/RoundLabel.text = "Player " + str(player + 1) + " Wins!"
			$Hands.get_node("P" + str(player) + "_Hand").win(pot)
			$Hands.get_node("P" + str(player) + "_Hand/HBoxContainer/PanelContainer/MarginContainer/CurrencyLabel").text = str($Hands.get_node("P" + str(player) + "_Hand").money) + " €"

extends Node2D

var pk_logic = poker_logic.new()

var table_cards_physical = []
var table_cards_data = []
var current_turn: int
var phase = 0

var starting_player: int
var player_count: int
var in_game_list = [0, 1, 2, 3]
var fold_list = []
var all_in_list = []

var card_placement: Vector2

var hand_types = ["Folded", "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"]

var min_bet = 400
var round_bet = 400
var pot = [0, 0, 0, 0]
var side_pot_bool = false
var pots = []

var raise_amount = min_bet

var start_mode = "manual"
var intermission = 0
var new_game_ready = false

func _ready():
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	$Hands.change_card_overlap(120)

	$ExtraLayer/RoundLabel.text = ""

	GlobalSignal.hand_deal.connect($Hands._on_card_to_hand)
	GlobalSignal.table_deal.connect(_on_deck_table_deal)

	GlobalSignal.fold.connect(_on_fold)
	GlobalSignal.call.connect(_on_call)
	GlobalSignal.raise.connect(_on_raise)
	GlobalSignal.raise_slider_value_changed.connect(_on_raise_slider_value_changed)

	starting_player = randi_range(0, 3)
	player_count = 4

	game_begin()

func game_begin():
	$Deck.deck_shuffle()

	await get_tree().create_timer(0.3).timeout
	for card in range(2): # Card amount
		for player in range(player_count): # Player amount
			player = (starting_player + player) % player_count
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(player)

	for card in range(5):
		await get_tree().create_timer(0.2).timeout
		$Deck.deal("table")

	var blind_halfer = 2
	for i in range(2):
		var player = (starting_player + i) % player_count
		await get_tree().create_timer(0.2).timeout
		@warning_ignore("integer_division")
		var bet_result =  $Hands.get_node("HandP" + str(player)).bet(min_bet/blind_halfer)
		pot[player] += bet_result[0]
		if bet_result[1] == true:
			all_in_list.append(player)
		balance_display_update(player)
		blind_halfer = 1

	current_turn = 0
	$ExtraLayer/RoundLabel.text = "Round 1"
	game_loop((starting_player + 2) % player_count)

func game_loop(player: int):
	while true:
		print("Current turn " + str(current_turn))
		current_turn += 1

		if len(fold_list) == len(in_game_list) - 1:
			uncontested_win()
			$Countdown.start()
			break
		if current_turn == 5:
			print("next round")
			current_turn = 0
			await get_tree().create_timer(0.5).timeout
			next_phase()
			break
		if player in fold_list or player in all_in_list:
			player = (player + 1) % 4
			continue

		await get_tree().create_timer(0.3).timeout
		var escape = pk_logic.turn(player)

		if escape == 0:
			player_turn()
			break
		else:
			player = (player + 1) % 4

func next_phase():
	phase += 1
	if phase == 1:
		table_cards_physical[0].flip_card()
		table_cards_physical[1].flip_card()
		table_cards_physical[2].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 2"
		indicator_reset()
		round_bet_reset()
		round_end_process()
	elif phase == 2:
		table_cards_physical[3].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 3"
		indicator_reset()
		round_bet_reset()
		round_end_process()
	elif phase == 3:
		table_cards_physical[4].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 4"
		indicator_reset()
		round_bet_reset()
		round_end_process()
	elif phase == 4:
		$ExtraLayer/RoundLabel.text = "Showdown"
		showdown()
		$Countdown.start()
		return
	else:
		$ExtraLayer/RoundLabel.text = "Error"
		push_error("Round overflow")

	if len(fold_list) + len(all_in_list) >= player_count - 1:
		next_phase()
	else:
		game_loop(starting_player)

func round_end_process():
	if len(fold_list) + len(all_in_list) >= player_count - 1:
		var temp_pot = pot.duplicate()
		temp_pot.sort()
		temp_pot.reverse()
		if temp_pot[0] != temp_pot[1]:
			var player = pot.find(temp_pot[0])
			$Hands.get_node("HandP" + str(player)).win(temp_pot[0] - temp_pot[1])
			pot[player] = temp_pot[1]
			balance_display_update(player)

	side_pot_detector()


func player_turn():
	$ButtonsLayer.visible = true
	$ButtonsLayer/ButtonsContainer/RaiseSlider.value = min_bet
	$ButtonsLayer/ButtonsContainer/RaiseSlider.max_value = $Hands.get_node("HandP" + "0").balance - round_bet + $Hands.get_node("HandP" + "0").round_bet

func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	table_cards_physical.append(card)
	table_cards_data.append([card.value, card.suit])

func _on_fold(player):
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Red")
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Fold"
	fold_list.append(player)

	if player == 0:
		raise_amount = min_bet
		game_loop(1) # Change needed in mp

func _on_call(player):
	var bet_result = $Hands.get_node("HandP" + str(player)).bet(round_bet)
	pot[player] += bet_result[0]
	if bet_result[1] == true:
		all_in_list.append(player)

	# Display updates
	var indicator = $ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator")
	if indicator.color != Color("Lime_Green"):
		indicator.color = Color("Lime_Green")
	else:
		indicator.modulate *= 1.5
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Call"
	balance_display_update(player)

	if player == 0:
		raise_amount = min_bet
		game_loop(1) # Change needed in mp

func _on_raise(player):
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Blue")
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Raise"

	round_bet += raise_amount
	current_turn = 1

	var bet_result = $Hands.get_node("HandP" + str(player)).bet(round_bet)
	pot[player] += bet_result[0]
	if bet_result[1] == true:
		all_in_list.append(player)
	balance_display_update(player)

	if player == 0:
		raise_amount = min_bet
		game_loop(1) # Change needed in mp

func _on_raise_slider_value_changed(value):
	raise_amount = int(value)

func indicator_reset():
	for player in range(4):
		if player not in fold_list:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Gray")
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").modulate = Color(1, 1, 1)
			$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = ""


func round_bet_reset():
	round_bet = 0

	for player in range(4):
		$Hands.get_node("HandP" + str(player)).round_bet = 0

func pot_sum():
	return pot.reduce(func(accum, number): return accum + number, 0)

func side_pot_detector():
	var pot_sizes = []
	var player = 0
	for p in pot:
		# THIS IGNORES THE BIGGEST BET GETS MONEY RETURNED BACK
		# TO HIM TO MATCH THE SECOND BIGGEST BET
		if p < pot.max() and player not in fold_list:
			pot_sizes.append(p)
		player += 1
	if len(pot_sizes) >= 1:
		side_pot_bool = true
		pot_sizes.append(pot.max())
		pot_sizes.sort()
		side_pot_display(pot_sizes)

func side_pot_display(pot_sizes):
	pots.clear()
	var prev_pot = 0
	for pot_size in pot_sizes:
		var temp_pot = 0
		for p in pot:
			if p >= pot_size:
				temp_pot += pot_size
			else:
				temp_pot += pot_size - p
		temp_pot -= prev_pot
		prev_pot = temp_pot
		pots.append(temp_pot)

func balance_display_update(player = null):
	if player != null:
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"

	if side_pot_bool == false:
		$ExtraLayer/PotLabel.text = "Pot: " + str(pot_sum()) + " €"
	else:
		var pot_label_text = ""
		for p in pots:
			if pot_label_text == "":
				pot_label_text = "Main Pot: " + str(p) + " €"
			else:
				pot_label_text += "\nSide Pot: " + str(p) + " €"
		pot_label_text += "\nTotal Pot: " + str(pot_sum()) + " €"
		$ExtraLayer/PotLabel.text = pot_label_text

func showdown():
	var poker_hand_list = []

	for player in range(4):
		if player not in fold_list:
			if player != 0: # Change needed in mp
				$Hands.flip_hand(player)

			var hand_and_river = $Hands.get_hand_content(player) + table_cards_data
			var poker_hand = pk_logic.check_hand(hand_and_river)

			poker_hand.append(player)

			$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = hand_types[poker_hand[0]]

			poker_hand_list.append(poker_hand)
			print(poker_hand)
		else:
			poker_hand_list.append([0, null, player])

	var placement = []
	for poker_hand in poker_hand_list:
		if placement.is_empty():
			placement.append([poker_hand])
		else:
			var i = 0
			for entry in placement:
				var result = pk_logic.compare_hand(entry[0], poker_hand)
				if result == 2:
					placement.insert(i, [poker_hand])
					break
				elif result == 0:
					placement[i].append(poker_hand)
				i += 1
				if result == 1 and len(placement) == i:
					placement.append([poker_hand])


	await get_tree().create_timer(1).timeout
	if len(placement[0]) == 1:
		var player = placement[0][0][2]
		$ExtraLayer/RoundLabel.text = "Player " + str(player + 1) + " Wins!"
		$Hands.get_node("HandP" + str(player)).win(pot_sum())
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"
	else:
		var winners = placement[0].map(func(hand): return hand[2])
		$ExtraLayer/RoundLabel.text = "It's a tie! Winners: " + str(winners)
		for player in winners:
			$Hands.get_node("HandP" + str(player)).win(pot_sum() / len(winners))
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"


func uncontested_win():
	for player in range(4):
		if player not in fold_list:
			$ExtraLayer/RoundLabel.text = "Player " + str(player + 1) + " Wins!"
			$Hands.get_node("HandP" + str(player)).win(pot_sum())
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"


func game_reset():
	fold_list.clear()
	all_in_list.clear()
	$Deck.reset_deck()
	$Hands.clear_hands()
	for card in table_cards_physical:
		card.queue_free()

	table_cards_physical.clear()
	table_cards_data.clear()
	phase = 0
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	pot = [0, 0, 0, 0]
	round_bet_reset()
	round_bet = min_bet
	side_pot_bool = false

	balance_display_update()
	indicator_reset()
	$ExtraLayer/RoundLabel.text = ""

	starting_player = (starting_player + 1) % player_count


func _on_countdown_timeout():
	if start_mode == "manual":
		if intermission >= 3:
			$ExtraLayer/RoundLabel.text = "Press anywhere to continue..."
			$Countdown.stop()
			intermission = 0
			new_game_ready = true
			return
	elif start_mode == "automatic":
		var break_secs = 8
		if intermission >= 3 and intermission <= break_secs:
			$ExtraLayer/RoundLabel.text = "Next round starts in " + str(break_secs - intermission)
		elif intermission > break_secs:
			$Countdown.stop()
			intermission = 0
			game_reset()
			game_begin()
			return
	intermission += 1

func _unhandled_input(event):
	# Click to start next hand
	if event is InputEventMouseButton and event.button_index == 1 and new_game_ready:
		new_game_ready = false
		game_reset()
		game_begin()

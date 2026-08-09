extends Node2D

var pk_logic = poker_logic.new()
var llm_gemini = poker_ai_llm_online.new("gemini-3.5-flash-lite")

var table_cards_physical = []
var table_cards_data = []
var current_turn: int
var phase = 0 # Better known as "round"

var starting_slot: int
var player_count: int
var players_list = [0, 1, 2, 3]
var players_balance = [0, 0, 0, 0]
var fold_list = []
var all_in_list = []

var card_placement: Vector2

var hand_types = ["Folded", "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"]
var round_names = ["Pre-Round", "Pre-Flop", "Flop", "Turn", "River", "Showdown", "Post-Round"]
var player_role_names = ["Small Blind", "Big Blind", "Under the Gun", "Dealer"]

var min_bet = 200
var round_bet = 200
var pot_p = [0, 0, 0, 0]
var side_pot_bool = false
var pots = []

# For visuals only
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

	player_count = len(players_list)
	starting_slot = randi_range(0, player_count-1)
	
	add_child(llm_gemini)

	# Cheat
	#$Hands.get_node("HandP0").balance = 4000
	#$Hands.get_node("HandP1").balance = 2000
	#$Hands.get_node("HandP2").balance = 1000
	#$Hands.get_node("HandP3").balance = 3000
	players_balance_update(-1)

	game_begin()

func game_begin():
	$Deck.deck_shuffle()

	await get_tree().create_timer(0.3).timeout
	for i in range(player_count):
		$Hands.get_node("HandP" + str(players_list[(starting_slot + i) % player_count]) + "/LabelPanel/PlayerLabel").text = player_role_names[i]
	for card in range(2):
		for i in range(player_count):
			var player = players_list[(starting_slot + i) % player_count]
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(player)

	var blind_halfer = 2
	for i in range(2):
		var player = players_list[(starting_slot + i) % player_count]
		await get_tree().create_timer(0.2).timeout
		var bet_result = $Hands.get_node("HandP" + str(player)).bet(min_bet/blind_halfer)
		players_balance_update(player)
		balance_display_update(player)
		balance_change_animation(player, -bet_result[0])
		pot_p[player] += bet_result[0]
		if bet_result[1] == true:
			all_in_list.append(player)		
		blind_halfer = 1

	current_turn = 0
	$ExtraLayer/RoundLabel.text = round_names[1]
	game_loop(players_list[(starting_slot + 2) % player_count])

func game_loop(player: int):
	while true:
		current_turn += 1

		if len(fold_list) == len(players_list) - 1:
			uncontested_win()
			$Countdown.start()
			break
		if current_turn == player_count + 1:
			current_turn = 0
			await get_tree().create_timer(1).timeout
			next_phase()
			break
		if player in fold_list or player in all_in_list:
			player = players_list[(players_list.find(player) + 1) % player_count]
			continue

		await get_tree().create_timer(0.4).timeout
		if player == 0: # Needs change in mp
			player_turn()
			break
		elif player == 1 or player == 3 or player == 2:
			pk_logic.ai_turn(player)
			player = players_list[(players_list.find(player) + 1) % player_count]
		elif player == 2:
			llm_gemini.test()
			player = players_list[(players_list.find(player) + 1) % player_count]

# Better known as "next_round"
func next_phase():
	phase += 1
	if phase == 1:
		for i in range(3):
			await get_tree().create_timer(0.2).timeout
			$Deck.deal("table")
		$ExtraLayer/RoundLabel.text = round_names[2]
		indicator_reset()
		round_bet_reset()
		round_end_process()
	elif phase == 2:
		$Deck.deal("table")
		$ExtraLayer/RoundLabel.text = round_names[3]
		indicator_reset()
		round_bet_reset()
		round_end_process()
	elif phase == 3:
		$Deck.deal("table")
		$ExtraLayer/RoundLabel.text = round_names[4]
		indicator_reset()
		round_bet_reset()
		round_end_process()
	elif phase == 4:
		$ExtraLayer/RoundLabel.text = round_names[5]
		round_end_process()
		showdown()
		return
	else:
		$ExtraLayer/RoundLabel.text = "Error"
		push_error("Round overflow")

	if len(fold_list) + len(all_in_list) >= player_count - 1:
		next_phase()
	else:
		game_loop(players_list[starting_slot])

func round_end_process():
	# Return overbet amount back to player
	if len(fold_list) + len(all_in_list) >= player_count - 1:
		var temp_pot_p = pot_p.duplicate()
		temp_pot_p.sort()
		temp_pot_p.reverse()
		if temp_pot_p[0] != temp_pot_p[1]:
			var player = pot_p.find(temp_pot_p[0])
			$Hands.get_node("HandP" + str(player)).win(temp_pot_p[0] - temp_pot_p[1])
			pot_p[player] = temp_pot_p[1]
			players_balance_update(player)
			balance_display_update(player)
			balance_change_animation(player, temp_pot_p[1])

	side_pot_handler()


func player_turn():
	$ButtonsLayer.visible = true
	var player = 0

	if $Hands.get_node("HandP" + str(player)).get_round_bet() != round_bet:
		$ButtonsLayer/ButtonsContainer/Call.text = "Call"
	else:
		$ButtonsLayer/ButtonsContainer/Call.text = "Check"

	if round_bet != 0:
		$ButtonsLayer.bet_or_raise = "Raise"
	else:
		$ButtonsLayer.bet_or_raise = "Bet"

	$ButtonsLayer/ButtonsContainer/RaiseSlider.value = min_bet
	$ButtonsLayer/ButtonsContainer/RaiseSlider.max_value = $Hands.get_node("HandP" + "0").balance - round_bet + $Hands.get_node("HandP" + "0").round_bet

func _on_fold(player):
	move_display_update(0, player)
	fold_list.append(player)

	if player == 0: # Change needed in mp
		raise_amount = min_bet
		game_loop(players_list[(players_list.find(player) + 1) % player_count])

func _on_call(player):
	move_display_update(1, player)
	var bet_result = $Hands.get_node("HandP" + str(player)).bet(round_bet)
	players_balance_update(player)
	balance_display_update(player)
	balance_change_animation(player, -bet_result[0])
	pot_p[player] += bet_result[0]
	if bet_result[1] == true:
		all_in_list.append(player)	

	if player == 0: # Change needed in mp
		raise_amount = min_bet
		game_loop(players_list[(players_list.find(player) + 1) % player_count])

func _on_raise(player):
	move_display_update(2, player)

	if $Hands.get_node("HandP" + str(player)).balance < raise_amount:
		round_bet += $Hands.get_node("HandP" + str(player)).balance
	else:
		round_bet += raise_amount
	current_turn = 1

	var bet_result = $Hands.get_node("HandP" + str(player)).bet(round_bet)
	pot_p[player] += bet_result[0]
	players_balance_update(player)
	balance_display_update(player)
	balance_change_animation(player, -bet_result[0])
	if bet_result[1] == true:
		all_in_list.append(player)

	if player == 0: # Change needed in mp
		raise_amount = min_bet
		game_loop(players_list[(players_list.find(player) + 1) % player_count])

func _on_raise_slider_value_changed(value):
	raise_amount = int(value)

func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	table_cards_physical.append(card)
	table_cards_data.append([card.value, card.suit])

	await get_tree().create_timer(0.6).timeout
	card.flip_card()

func players_balance_update(player):
	if player != -1:
		players_balance[player] = $Hands.get_node("HandP" + str(player)).get_balance()
	else:
		for p in players_list:
			players_balance[p] = $Hands.get_node("HandP" + str(p)).get_balance()

func pot_sum():
	return pot_p.reduce(func(accum, number): return accum + number, 0)

func round_bet_reset():
	round_bet = 0

	for player in players_list:
		$Hands.get_node("HandP" + str(player)).round_bet = 0

func side_pot_handler():
	pots.clear()
	var pot_sizes = [pot_p.max()]
	for player in players_list:
		if player in all_in_list and pot_p[player] not in pot_sizes:
			pot_sizes.append(pot_p[player])
	pot_sizes.sort()
	if len(pot_sizes) == 1:
		side_pot_bool = false
		pots.append(pot_sum())
	else:
		side_pot_bool = true
		var prev_pot = 0
		for pot_size in pot_sizes:
			var temp_pot = 0
			var pot_participants = []
			for player in players_list:
				if pot_p[player] >= pot_size:
					temp_pot += pot_size - prev_pot
					pot_participants.append(player)
			prev_pot = pot_size
			pots.append([temp_pot, pot_participants])
		balance_display_update()


func uncontested_win():
	for player in players_list:
		if player not in fold_list:
			$ExtraLayer/RoundLabel.text = "Player " + str(player + 1) + " Wins!"
			$Hands.get_node("HandP" + str(player)).win(pot_sum())
			players_balance_update(player)
			balance_change_animation(player, pot_sum())
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"

func showdown():
	var poker_hand_list = []
	
	# Get players' poker hands
	for player in players_list:
		if player not in fold_list:
			if player != 0: # Change needed in mp
				$Hands.flip_hand(player)

			poker_hand_list.append(get_player_hand(player))
		else:
			poker_hand_list.append([0, null, player])

	# Rank players' poker hands
	var placements = []
	rank_hands(poker_hand_list, placements)

	# Distribute the pot
	await get_tree().create_timer(1).timeout
	pot_distribution(placements)

	# Remove players that ran out of chips
	for player in players_list.duplicate():
		if $Hands.get_node("HandP" + str(player)).balance == 0:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Black")
			$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = ""
			players_list.erase(player)
			player_count -= 1
			if player_count == 3:
				player_role_names.erase("Under the Gun")
			if player_count == 2:
				player_role_names.erase("Dealer")

	# Game ends, when there is only one remaining player
	if len(players_list) == 1:
		game_end()
	else:
		$Countdown.start()

func get_player_hand(player: int) -> Array:
	var hand_and_river = $Hands.get_hand_content(player) + table_cards_data
	var poker_hand = pk_logic.check_hand(hand_and_river)

	poker_hand.append(player)

	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = hand_types[poker_hand[0]]

	return poker_hand

func rank_hands(poker_hand_list: Array, placements: Array) -> void:
	for poker_hand in poker_hand_list:
		if placements.is_empty():
			placements.append([poker_hand])
		else:
			var i = 0
			for entry in placements:
				var result = pk_logic.compare_hand(entry[0], poker_hand)
				if result == 2:
					placements.insert(i, [poker_hand])
					break
				elif result == 0:
					placements[i].append(poker_hand)
				i += 1
				if result == 1 and len(placements) == i:
					placements.append([poker_hand])

func pot_distribution(placements: Array) -> void:
	for placement in placements:
		if len(placement) == 1:
			var player = placement[0][2]
			$ExtraLayer/RoundLabel.text = "Player " + str(player + 1) + " Wins!"
			if side_pot_bool == false:
				$Hands.get_node("HandP" + str(player)).win(pot_sum())
				players_balance_update(player)
				balance_change_animation(player, pot_sum())
				$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"
				break
			else:
				for pot in pots:
					if player in pot[1]:
						$Hands.get_node("HandP" + str(player)).win(pot[0])
						players_balance_update(player)
						balance_change_animation(player, pot[0])
						pot[0] = 0
				if pots.reduce(func(accum, pot): return accum + pot[0], 0) == 0:
					balance_display_update(-1)
					break
		else:
			var winners = placement.map(func(hand): return hand[2])
			$ExtraLayer/RoundLabel.text = "It's a tie! Winners: " + str(winners)
			if side_pot_bool == false:
				for player in winners:
					$Hands.get_node("HandP" + str(player)).win(pot_sum() / len(winners))
					players_balance_update(player)
					balance_change_animation(player, pot_sum() / len(winners))
					$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).get_balance()) + " €"
				break
			else:
				for pot in pots:
					var pot_getter = winners.reduce(func(accum, winner): return accum + 1 if winner in pot[1] else accum, 0)
					var pot_claimed = false
					for winner in winners:
						if winner in pot[1]:
							$Hands.get_node("HandP" + str(winner)).win(pot[0] / pot_getter)
							players_balance_update(winner)
							balance_change_animation(winner, pot[0] / pot_getter)
							pot_claimed = true
					if pot_claimed:
						pot[0] = 0

				if pots.reduce(func(accum, pot): return accum + pot[0], 0) == 0:
					balance_display_update(-1)
					break

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
	pot_p = [0, 0, 0, 0]
	round_bet_reset()
	round_bet = min_bet
	side_pot_bool = false

	balance_display_update()
	indicator_reset()
	$ExtraLayer/RoundLabel.text = ""

	starting_slot = (starting_slot + 1) % player_count


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

func game_end():
	$ExtraLayer/RoundLabel.text = "The winner is Player " + str(players_list[0] + 1) + "!"


## Purely cosmetic functions

func indicator_reset():
	for player in players_list:
		if player not in fold_list:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Gray")
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").modulate = Color(1, 1, 1)
			$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = ""
		if player in all_in_list:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Dark_Green")

func balance_display_update(player = null):
	# Player
	if player == -1:
		for p in range(4):
			$ExtraLayer.get_node("StatsP" + str(p) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(p)).balance) + " €"
	elif player != null:
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).balance) + " €"

	# Pot
	if side_pot_bool == false:
		$ExtraLayer/PotLabel.text = "Pot: " + str(pot_sum()) + " €"
	else:
		var pot_label_text = ""
		for p in pots:
			if pot_label_text == "":
				pot_label_text = "Main Pot: " + str(p[0]) + " €"
			else:
				pot_label_text += "\nSide Pot: " + str(p[0]) + " €"
		pot_label_text += "\nTotal Pot: " + str(pot_sum()) + " €"
		$ExtraLayer/PotLabel.text = pot_label_text

func move_display_update(move: int, player: int):
	var move_text: String
	var indicator = $ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator")

	if move == 0:
		move_text = "Fold"
		indicator.color = Color("Red")
	elif move == 1:
		if $Hands.get_node("HandP" + str(player)).get_round_bet() != round_bet:
			move_text = "Call"
		else:
			move_text = "Check"
		if indicator.color == Color("Lime_Green"):
			indicator.modulate *= 1.5
		else:
			indicator.color = Color("Lime_Green")
	elif move == 2:
		if round_bet != 0:
			move_text = "Raise"
		else:
			move_text = "Bet"
		indicator.color = Color("Blue")

	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = move_text

func balance_change_animation(player, amount):
	var the_node = get_node("ExtraLayer/StatsP" + str(player) + "/BCMC")

	if amount == 0:
		return
	elif amount > 0:
		the_node.get_child(0).text = "+" + str(amount) + " €"
	else:
		the_node.get_child(0).text = str(amount) + " €"

	the_node.visible = true
	the_node.position = get_node("ExtraLayer/StatsP" + str(player) + "/HBC").position

	var yd = -66
	if player == 2 or player == 3:
		yd *= -1

	var tween = create_tween()
	tween.tween_property(the_node, "modulate:a", 1, 0.2)
	tween.parallel().tween_property(the_node, "position", the_node.position + Vector2(0, yd), 0.3)
	# Causes visual bug
	tween.tween_property(the_node, "modulate:a", 0, 0.2).set_delay(2)

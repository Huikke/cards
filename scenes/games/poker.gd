extends Node2D

var pk_logic = PokerLogic.new()
var players_mode = Global.player_poker_modes
var players_mode_class = [null, null, null, null]

var community_cards_physical = []
var community_cards_data = []
var current_turn: int
var phase = 1 # Better known as "round"

var starting_slot: int
var player_count: int
var players_list = [0, 1, 2, 3]
var players_balance = [0, 0, 0, 0]
var players_round_bet = [0, 0, 0, 0]
var players_roles = []
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
var game_log = []

var start_mode = "manual"
var intermission = 0
var new_game_ready = false

func _ready():
	print(players_mode)
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	$Hands.change_card_overlap(120)

	$ExtraLayer/RoundLabel.text = ""

	GlobalSignal.hand_deal.connect($Hands._on_card_to_hand)
	GlobalSignal.table_deal.connect(_on_deck_table_deal)

	GlobalSignal.fold.connect(_on_fold)
	GlobalSignal.call.connect(_on_call)
	GlobalSignal.raise.connect(_on_raise)

	player_count = len(players_list)
	starting_slot = randi_range(0, player_count-1)
	
	for i in range(4):
		if players_mode[i] == 2:
			players_mode_class[i] = PokerAiLLM.new("gemini-3.5-flash-lite")
			add_child(players_mode_class[i])

	players_balance = [10000, 10000, 10000, 10000]

	game_begin()

func game_begin():
	$Deck.deck_shuffle()

	await get_tree().create_timer(0.3).timeout
	for i in range(player_count):
		$Hands.get_node("HandP" + str(players_list[(starting_slot + i) % player_count]) + "/LabelPanel/PlayerLabel").text = player_role_names[i]
		players_roles.append("Player " + str(players_list[(starting_slot + i) % player_count] + 1) + ": " + player_role_names[i])
	for card in range(2):
		for i in range(player_count):
			var player = players_list[(starting_slot + i) % player_count]
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(player)

	var blind_halfer = 2
	for i in range(2):
		var player = players_list[(starting_slot + i) % player_count]
		await get_tree().create_timer(0.2).timeout
		player_bet(player, min_bet/blind_halfer)
		logger("blind", player, min_bet/blind_halfer)
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
		if players_mode[player] == 0: # Needs change in mp
			player_turn()
		elif players_mode[player] == 1:
			pk_logic.ai_random(player)
		elif players_mode[player] == 2:
			var hand = " ".join($Hands.get_hand_content(player).map(cards_data_to_str))
			players_mode_class[player].ai_move(player, hand, players_roles, players_balance, pot_sum(), game_log)
		break

# Better known as "next_round"
func next_phase():
	phase += 1
	if phase == 2:
		for i in range(3):
			await get_tree().create_timer(0.2).timeout
			$Deck.deal("table")
		$ExtraLayer/RoundLabel.text = round_names[phase]
		logger("phase")
		indicator_reset()
		round_end_process()
	elif phase == 3:
		$Deck.deal("table")
		$ExtraLayer/RoundLabel.text = round_names[phase]
		logger("phase")
		indicator_reset()
		round_end_process()
	elif phase == 4:
		$Deck.deal("table")
		$ExtraLayer/RoundLabel.text = round_names[phase]
		logger("phase")
		indicator_reset()
		round_end_process()
	elif phase == 5:
		$ExtraLayer/RoundLabel.text = round_names[phase]
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
	# Reset round_bet
	round_bet = 0
	players_round_bet = [0, 0, 0, 0]

	# Return overbet amount back to player
	if len(fold_list) + len(all_in_list) >= player_count - 1:
		var temp_pot_p = pot_p.duplicate()
		temp_pot_p.sort()
		temp_pot_p.reverse()
		if temp_pot_p[0] != temp_pot_p[1]:
			var player = pot_p.find(temp_pot_p[0])
			var return_amount = temp_pot_p[0] - temp_pot_p[1]
			player_award(player, return_amount)
			pot_p[player] -= return_amount

	side_pot_handler()


func player_turn():
	$ButtonsLayer.visible = true
	var p = 0

	if players_round_bet[p] != round_bet:
		$ButtonsLayer/ButtonsContainer/Call.text = "Call"
	else:
		$ButtonsLayer/ButtonsContainer/Call.text = "Check"

	if round_bet != 0:
		$ButtonsLayer.raise_text = "Raise"
	else:
		$ButtonsLayer.raise_text = "Bet"
	$ButtonsLayer.update_raise_text()

	$ButtonsLayer/ButtonsContainer/RaiseSlider.value = min_bet
	$ButtonsLayer/ButtonsContainer/RaiseSlider.max_value = players_balance[p] - round_bet + players_round_bet[p]

func player_bet(p: int, amount: int):
	var difference = amount - players_round_bet[p]

	if players_balance[p] - difference <= 0:
		difference = players_balance[p]
		all_in_list.append(p)
	players_balance[p] -= difference
	players_round_bet[p] += difference
	pot_p[p] += difference

	# Visuals
	balance_display_update(p)
	balance_change_animation(p, -difference)

	return difference

func player_award(p: int, amount: int):
	players_balance[p] += amount

	# Visuals
	balance_display_update(p)
	balance_change_animation(p, amount)

func _on_fold(player):
	move_display_update(0, player)
	fold_list.append(player)
	logger("fold", player)

	game_loop(players_list[(players_list.find(player) + 1) % player_count])

func _on_call(player):
	move_display_update(1, player)
	var difference = player_bet(player, round_bet)
	logger("call", player, difference)

	game_loop(players_list[(players_list.find(player) + 1) % player_count])

func _on_raise(player, amount):
	move_display_update(2, player)

	if players_balance[player] < amount:
		round_bet += players_balance[player]
	else:
		round_bet += amount
	current_turn = 1

	player_bet(player, round_bet)
	logger("raise", player, amount)

	game_loop(players_list[(players_list.find(player) + 1) % player_count])


func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	community_cards_physical.append(card)
	community_cards_data.append([card.value, card.suit])

	await get_tree().create_timer(0.6).timeout
	card.flip_card()

func pot_sum():
	return pot_p.reduce(func(accum, number): return accum + number, 0)

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
			player_award(player, pot_sum())

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
		if players_balance[player] == 0:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Black")
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
	var hand_and_river = $Hands.get_hand_content(player) + community_cards_data
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
				player_award(player, pot_sum())
				logger("win", player, pot_sum())
				break
			else:
				for pot in pots:
					if player in pot[1]:
						player_award(player, pot[0])
						logger("win", player, pot_sum())
						pot[0] = 0
				if pots.reduce(func(accum, pot): return accum + pot[0], 0) == 0:
					balance_display_update(-1)
					break
		else:
			var winners = placement.map(func(hand): return hand[2])
			$ExtraLayer/RoundLabel.text = "It's a tie! Winners: " + str(winners)
			if side_pot_bool == false:
				for player in winners:
					player_award(player, pot_sum() / len(winners))
					logger("win", player, pot_sum())
				break
			else:
				for pot in pots:
					var pot_getter = winners.reduce(func(accum, player): return accum + 1 if player in pot[1] else accum, 0)
					var pot_claimed = false
					for player in winners:
						if player in pot[1]:
							player_award(player, pot[0] / pot_getter)
							logger("win", player, pot_sum())
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
	for card in community_cards_physical:
		card.queue_free()

	community_cards_physical.clear()
	community_cards_data.clear()
	players_roles.clear()
	game_log.clear()
	$ExtraLayer/GameLog.text = ""
	phase = 1
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	pot_p = [0, 0, 0, 0]
	players_round_bet = [0, 0, 0, 0]
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


## Mostly cosmetic functions
func logger(action: String, p: int = -1, amount: int = -1) -> void:
	if action == "fold":
		game_log.append("Player " + str(p + 1) + " folds")
	elif action == "call" and amount != 0:
		game_log.append("Player " + str(p + 1) + " calls " + str(amount) + " €")
	elif action == "call" and amount == 0:
		game_log.append("Player " + str(p + 1) + " checks")
	elif action == "raise" and amount != round_bet:
		game_log.append("Player " + str(p + 1) + " raises " + str(amount) + " €")
	elif action == "raise" and amount == round_bet:
		game_log.append("Player " + str(p + 1) + " bets " + str(amount) + " €")
	elif action == "blind" and amount != round_bet:
		game_log.append("Player " + str(p + 1) + " posts small blind " + str(amount) + " €")
	elif action == "blind" and amount == round_bet:
		game_log.append("Player " + str(p + 1) + " posts big blind " + str(amount) + " €")
	elif action == "phase":
		var mapped_c_cards = community_cards_data.map(cards_data_to_str)
		game_log.append(round_names[phase] + ": " + " ".join(mapped_c_cards))
	elif action == "win":
		game_log.append("Player " + str(p + 1) + " wins " + str(amount) + " €")
	$ExtraLayer/GameLog.text += game_log[-1] + "\n"

func cards_data_to_str(card):
	if card[0] == 11:
		return "J" + card[1][0]
	elif card[0] == 12:
		return "Q" + card[1][0]
	elif card[0] == 13:
		return "K" + card[1][0]
	elif card[0] == 1:
		return "A" + card[1][0]
	else:
		return str(card[0]) + card[1][0]

func indicator_reset():
	for player in players_list:
		if player not in fold_list:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Gray")
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").modulate = Color(1, 1, 1)
		if player in all_in_list:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Dark_Green")
	# Rework when adding more players
	for player in range(4):
		$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = ""

func balance_display_update(player = null):
	# Player
	if player == -1:
		for p in range(4):
			$ExtraLayer.get_node("StatsP" + str(p) + "/HBC/PC/MC/CurrencyLabel").text = str(players_balance[p]) + " €"
	elif player != null:
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str(players_balance[player]) + " €"

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
		if players_round_bet[player] != round_bet:
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

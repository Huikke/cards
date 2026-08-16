extends Node2D

# Constants
const HAND_TYPES: Array[String] = ["Folded", "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"]
const ROUND_NAMES: Array[String] = ["Pre-Round", "Pre-Flop", "Flop", "Turn", "River", "Showdown", "Post-Round"]
var POKER_POSITIONS: Array[String] = ["Button", "Small Blind", "Big Blind", "Under the Gun"]

# Pre-Game variables
var players_agent: Array = Global.player_poker_modes
var starting_player_count: int
var player_agent_ai: Array = [] # AI Object goes here
var starting_balance = 10000
var starting_bet = 200

# Round (Phase) and Game (Hand) specific variables
var starting_slot: int
var min_bet: int
var current_turn: int = 0
var round_bet: int
var phase: int = 1 # Better known as "round"
var community_cards_physical: Array = []
var community_cards_data: Array = []

# Player variables
var players_live: Array[int]
var player_count: int
var players_balance: Array[int] = []
var players_round_bet: Array[int] = []
var players_game_bet: Array[int] = []
var players_roles = []
var fold_list = []
var all_in_list = []

# Side Pot specific variables
var side_pot_bool = false
var pots = []

# Other
@onready var card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
var start_mode = "manual"
var intermission = 0
var new_game_ready = false
var game_log = []

# ==============================================================================
# LIFECYCLE & INITIALIZATION
# ==============================================================================

func _ready():
	starting_player_count = len(players_agent)

	# Visuals
	$Hands.change_card_overlap(120)
	label_update("Main", "")
	# Player's card is up
	for i in range(starting_player_count):
		if players_agent[i] == 0:
			$Hands.player_cards_face_up_list[i] = true
		else:
			$Hands.player_cards_face_up_list[i] = false

	# Connect Signals
	GlobalSignal.hand_deal.connect($Hands._on_card_to_hand)
	GlobalSignal.table_deal.connect(_on_deck_table_deal)
	GlobalSignal.fold.connect(_on_fold)
	GlobalSignal.call.connect(_on_call)
	GlobalSignal.raise.connect(_on_raise)

	# Game starting values (starting player is random)
	for i in range(starting_player_count):
		players_live.append(i)
	players_round_bet.resize(starting_player_count)
	players_game_bet.resize(starting_player_count)
	players_balance.resize(starting_player_count)
	players_balance.fill(starting_balance)
	starting_slot = randi_range(0, player_count-1)
	min_bet = starting_bet
	player_count = len(players_live)

	# Initiate ai_agents
	for i in range(len(players_agent)):
		if players_agent[i] == 2:
			player_agent_ai.append(PokerAiLLM.new("gemini-3.5-flash-lite"))
			add_child(player_agent_ai[i])
		elif players_agent[i] == 3:
			player_agent_ai.append(PokerAiLLM.new("ai/llama3.2"))
			add_child(player_agent_ai[i])
		else:
			player_agent_ai.append(null)


	balance_display_update(-1)
	# Start the game
	if !Global.mp_enabled or multiplayer.is_server():
		$ExtraLayer/GameLog.visible = true
		game_begin()

# ==============================================================================
# CORE GAME FLOW
# ==============================================================================

func game_begin():
	# Shuffle Deck
	$Objects/Deck.deck_shuffle()

	await get_tree().create_timer(0.3).timeout
	# Assigning roles to players
	if player_count != 2:
		for i in range(player_count):
			assign_player_position(i, POKER_POSITIONS[i])
	else:
		assign_player_position(1, POKER_POSITIONS[0] + " / " + POKER_POSITIONS[1])
		assign_player_position(2, POKER_POSITIONS[2])
	# Deal cards to players
	for card in range(2):
		for i in range(player_count):
			var player = players_live[(starting_slot + i) % player_count]
			await get_tree().create_timer(0.2).timeout
			$Objects/Deck.deal("player", player)

	# Post blinds
	var blind_halfer = 2
	for i in range(2):
		var player = players_live[(starting_slot + i) % player_count]
		await get_tree().create_timer(0.2).timeout
		player_bet(player, min_bet/blind_halfer)
		if i == 0:
			logger("small blind", player, players_game_bet[player])
		elif i == 1:
			logger("big blind", player, players_game_bet[player])
		blind_halfer = 1
	round_bet = min_bet

	# Preflop begins
	label_update("Main", ROUND_NAMES[1])
	game_loop(players_live[(starting_slot + 2) % player_count])

func game_loop(player: int) -> void:
	current_turn += 1
	
	# Player wins, if everyone else has folded
	if len(fold_list) == player_count - 1:
		uncontested_win()
		$Countdown.start()
		return

	# Advance to the next round
	if current_turn == player_count + 1:
		current_turn = 0
		await get_tree().create_timer(1).timeout
		next_phase()
		return

	# Skip players who cannot act (folded / all-in)
	if player in fold_list or player in all_in_list:
		game_loop(players_live[(players_live.find(player) + 1) % player_count])
		return

	# Player action based on agent type
	indicator_color_update(player, Color("Orange"))
	if players_agent[player] == 0:
		player_turn(player)
	elif players_agent[player] == 1:
		await get_tree().create_timer(0.5).timeout
		PokerAiRandom.ai_random(player)
	elif players_agent[player] == 2 or players_agent[player] == 3:
		var hand = " ".join($Hands.get_hand_content(player).map(cards_data_to_str))
		player_agent_ai[player].ai_move(player, hand, players_roles, players_balance, pot_sum(), game_log)

# Better known as "next_round"
func next_phase():
	# Advance to the next round
	phase += 1
	if phase == 2:
		for i in range(3):
			await get_tree().create_timer(0.2).timeout
			$Objects/Deck.deal("table")
		label_update("Main", ROUND_NAMES[phase])
		logger("phase")
		indicator_reset()
		round_end_process()
	elif phase == 3:
		$Objects/Deck.deal("table")
		label_update("Main", ROUND_NAMES[phase])
		logger("phase")
		indicator_reset()
		round_end_process()
	elif phase == 4:
		$Objects/Deck.deal("table")
		label_update("Main", ROUND_NAMES[phase])
		logger("phase")
		indicator_reset()
		round_end_process()
	elif phase == 5:
		label_update("Main", ROUND_NAMES[phase])
		round_end_process()
		showdown()
		return
	else:
		label_update("Main", "Error")
		push_error("Round overflow")

	# Fast forward streets if conditions are right
	# or start the next round
	if len(fold_list) + len(all_in_list) >= player_count - 1:
		await get_tree().create_timer(1.5).timeout
		next_phase()
	else:
		game_loop(players_live[starting_slot])

## Cleans up per-round bets, calculates side pots, and refunds uncalled overbets.
func round_end_process():
	# Reset round_bet
	round_bet = 0
	players_round_bet.fill(0)

	# Refund uncalled bets amount back to player
	if len(fold_list) + len(all_in_list) >= player_count - 1:
		var temp_players_game_bet = players_game_bet.duplicate()
		temp_players_game_bet.sort()
		temp_players_game_bet.reverse()
		if temp_players_game_bet[0] != temp_players_game_bet[1]:
			var player = players_game_bet.find(temp_players_game_bet[0])
			var return_amount = temp_players_game_bet[0] - temp_players_game_bet[1]
			player_award(player, return_amount)
			players_game_bet[player] -= return_amount

	side_pot_handler()

# ==============================================================================
# BETTING & POT MANAGEMENT
# ==============================================================================

func player_turn(player):
	$ButtonsLayer.set_player(player)
	$ButtonsLayer.visible = true

	if players_round_bet[player] != round_bet:
		$ButtonsLayer/ButtonsContainer/Call.text = "Call"
	else:
		$ButtonsLayer/ButtonsContainer/Call.text = "Check"

	if round_bet != 0:
		$ButtonsLayer.raise_text = "Raise"
	else:
		$ButtonsLayer.raise_text = "Bet"

	# If player has less than min_bet, lower the raise/bet limit
	if players_balance[player] < min_bet + round_bet - players_round_bet[player]:
		var amount = players_balance[player] - round_bet + players_round_bet[player]
		if amount < 0:
			amount = 0
		$ButtonsLayer/ButtonsContainer/RaiseSlider.min_value = amount
		$ButtonsLayer/ButtonsContainer/RaiseSlider.value = amount
		$ButtonsLayer.raise_text = "All In"
	else:
		$ButtonsLayer/ButtonsContainer/RaiseSlider.min_value = min_bet
		$ButtonsLayer/ButtonsContainer/RaiseSlider.value = min_bet
	# Set bet limit to player's available balance
	$ButtonsLayer/ButtonsContainer/RaiseSlider.max_value = players_balance[player] - round_bet + players_round_bet[player]

	$ButtonsLayer.update_raise_text()

func player_bet(p: int, amount: int):
	var difference = amount - players_round_bet[p]

	if players_balance[p] - difference <= 0:
		difference = players_balance[p]
		all_in_list.append(p)
	players_balance[p] -= difference
	players_round_bet[p] += difference
	players_game_bet[p] += difference

	# Visuals
	balance_display_update(p)
	balance_change_animation(p, -difference)

	return difference

func player_award(p: int, amount: int):
	players_balance[p] += amount

	# Visuals
	balance_display_update(p)
	balance_change_animation(p, amount)


func pot_sum():
	return players_game_bet.reduce(func(accum, number): return accum + number, 0)

func side_pot_handler():
	pots.clear()
	var pot_sizes = [players_game_bet.max()]
	for player in players_live:
		if player in all_in_list and players_game_bet[player] not in pot_sizes:
			pot_sizes.append(players_game_bet[player])
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
			for player in players_live:
				if players_game_bet[player] >= pot_size:
					temp_pot += pot_size - prev_pot
					pot_participants.append(player)
			prev_pot = pot_size
			pots.append([temp_pot, pot_participants])
		balance_display_update()

# ==============================================================================
# PLAYER ACTIONS (SIGNAL HANDLERS)
# ==============================================================================

func _on_fold(player):
	move_display_update(0, player)
	fold_list.append(player)
	logger("fold", player)

	game_loop(players_live[(players_live.find(player) + 1) % player_count])

func _on_call(player):
	move_display_update(1, player)
	var difference = player_bet(player, round_bet)
	logger("call", player, difference)

	game_loop(players_live[(players_live.find(player) + 1) % player_count])

func _on_raise(player, amount):
	move_display_update(2, player, amount)

	# If player does not have enough money to raise/bet, move it to calling
	if players_balance[player] <= round_bet - players_round_bet[player] + amount:
		_on_call(player)
		return

	round_bet += amount
	current_turn = 1

	player_bet(player, round_bet)
	logger("raise", player, amount)

	game_loop(players_live[(players_live.find(player) + 1) % player_count])


func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	community_cards_physical.append(card)
	community_cards_data.append([card.value, card.suit])

	await get_tree().create_timer(0.6).timeout
	card.flip_card()

# ==============================================================================
# SHOWDOWN & SCORING
# ==============================================================================

func uncontested_win():
	for player in players_live:
		if player not in fold_list:
			label_update("Main", "Player " + str(player + 1) + " Wins!")
			player_award(player, pot_sum())

func showdown():
	var poker_hand_list = []

	# Get players' poker hands
	for player in players_live:
		if player not in fold_list:
			if players_agent[player] != 0:
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
	for player in players_live.duplicate():
		if players_balance[player] == 0:
			indicator_color_update(player, Color("Black"))
			players_live.erase(player)
			player_count -= 1

	# Game ends, when there is only one remaining player
	if len(players_live) == 1:
		game_end()
	else:
		$Countdown.start()

func get_player_hand(player: int) -> Array:
	var hand_and_river = $Hands.get_hand_content(player) + community_cards_data
	var poker_hand = PokerLogic.check_hand(hand_and_river)

	poker_hand.append(player)

	label_update("PlayerHeadsUp", HAND_TYPES[poker_hand[0]], player)

	return poker_hand

func rank_hands(poker_hand_list: Array, placements: Array) -> void:
	for poker_hand in poker_hand_list:
		if placements.is_empty():
			placements.append([poker_hand])
		else:
			var i = 0
			for entry in placements:
				var result = PokerLogic.compare_hand(entry[0], poker_hand)
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
			label_update("Main", "Player " + str(player + 1) + " Wins!")
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
			label_update("Main", "It's a tie! Winners: " + str(winners))
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

# ==============================================================================
# STATE RESET & TRANSITIONS
# ==============================================================================

func game_reset():
	fold_list.clear()
	all_in_list.clear()
	$Objects/Deck.reset_deck()
	$Hands.clear_hands()
	for card in community_cards_physical:
		card.destroy()

	community_cards_physical.clear()
	community_cards_data.clear()
	players_roles.clear()
	game_log.clear()
	$ExtraLayer/GameLog.text = ""
	current_turn = 0
	phase = 1
	card_placement_reset()
	players_game_bet.fill(0)
	players_round_bet.fill(0)
	side_pot_bool = false

	balance_display_update()
	indicator_reset()
	label_update("Main", "")

	starting_slot = (starting_slot + 1) % player_count


func _on_countdown_timeout():
	if start_mode == "manual":
		if intermission >= 3:
			label_update("Main", "Press anywhere to continue...")
			$Countdown.stop()
			intermission = 0
			new_game_ready = true
			return
	elif start_mode == "automatic":
		var break_secs = 8
		if intermission >= 3 and intermission <= break_secs:
			label_update("Main", "Next round starts in " + str(break_secs - intermission))
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
	label_update("Main", "The winner is Player " + str(players_live[0] + 1) + "!")

# ==============================================================================
# Logging & Visuals
# ==============================================================================

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
	elif action == "small blind":
		game_log.append("Player " + str(p + 1) + " posts small blind " + str(amount) + " €")
	elif action == "big blind":
		game_log.append("Player " + str(p + 1) + " posts big blind " + str(amount) + " €")
	elif action == "phase":
		var mapped_c_cards = community_cards_data.map(cards_data_to_str)
		game_log.append(ROUND_NAMES[phase] + ": " + " ".join(mapped_c_cards))
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

func assign_player_position(i: int, role: String) -> void:
	label_update("PlayerHeadsUp", role, players_live[(starting_slot + i - 1) % player_count])
	players_roles.append("Player " + str(players_live[(starting_slot + i - 1) % player_count] + 1) + ": " + role)

func indicator_reset():
	for player in players_live:
		if player not in fold_list:
			indicator_color_update(player, Color("Gray"))
		if player in all_in_list:
			indicator_color_update(player, Color("Dark_Green"))
	# For clearing players, who have been eliminated
	for player in range(starting_player_count):
		label_update("PlayerHeadsUp", "", player)

func balance_display_update(player = null):
	# Player
	if player == -1:
		for p in range(starting_player_count):
			label_update("PlayerBalance", str(players_balance[player]), p)
	elif player != null:
		label_update("PlayerBalance", str(players_balance[player]), player)

	# Pot
	if side_pot_bool == false:
		label_update("Pot", "Pot: " + str(pot_sum()) + " €")
	else:
		var pot_label_text = ""
		for p in pots:
			if pot_label_text == "":
				pot_label_text = "Main Pot: " + str(p[0]) + " €"
			else:
				pot_label_text += "\nSide Pot: " + str(p[0]) + " €"
		pot_label_text += "\nTotal Pot: " + str(pot_sum()) + " €"
		label_update("Pot", pot_label_text)

func move_display_update(move: int, player: int, amount: int = 0):
	var move_text: String

	if move == 0:
		move_text = "Fold"
		indicator_color_update(player, Color("Red"))
	elif move == 1:
		if players_balance[player] <= round_bet - players_round_bet[player]:
			move_text = "All In"
		elif players_round_bet[player] != round_bet:
			move_text = "Call"
		else:
			move_text = "Check"
		indicator_color_update(player, Color("Lime_Green"))
	elif move == 2:
		if players_balance[player] <= round_bet - players_round_bet[player] + amount:
			move_text = "All In"
		elif round_bet != 0:
			move_text = "Raise"
		else:
			move_text = "Bet"
		indicator_color_update(player, Color("Blue"))

	label_update("PlayerHeadsUp", move_text, player)

@rpc("authority")
func label_update(label_name: String, text: String, number: int = -1) -> void:
	if Global.mp_enabled and multiplayer.is_server():
		label_update.rpc(label_name, text, number)

	if label_name == "Main":
		$ExtraLayer/MainLabel.text = text
	elif label_name == "Pot":
		$ExtraLayer/PotLabel.text = text
	elif label_name == "PlayerBalance":
		$ExtraLayer.get_node("StatsP" + str(number) + "/HBC/PC/MC/CurrencyLabel").text = text + " €"
	elif label_name == "PlayerHeadsUp":
		$Hands.get_node("HandP" + str(number) + "/PlayerHeadsUpLabel").text = text

@rpc("authority")
func indicator_color_update(player: int, color: Color) -> void:
	if Global.mp_enabled and multiplayer.is_server():
		indicator_color_update.rpc(player, color)
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = color

@rpc("authority")
func card_placement_reset():
	if Global.mp_enabled and multiplayer.is_server():
		card_placement_reset.rpc()
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)

@rpc("authority")
func balance_change_animation(player, amount) -> void:
	if Global.mp_enabled and multiplayer.is_server():
		balance_change_animation.rpc(player, amount)
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

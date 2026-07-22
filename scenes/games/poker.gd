extends Node2D

var pk_logic = poker_logic.new()
#var deck_scene = preload("res://scenes/objects/deck.tscn")

var table_cards_physical = []
var table_cards_data = []
var phase = 0

var card_placement: Vector2

var hand_types = ["Folded", "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"]

var min_bet = 400
var round_bet = 400
var pot = 0
var raise_amount = min_bet

var intermission = 0

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

	var starting_player = randi_range(0, 3)

	game_begin(starting_player, 4)

func game_begin(starting_player, player_amount):
	#var deck = deck_scene.instantiate()
	#deck.position = Vector2(343, 0)
	#add_child(deck)
	#deck.deck_shuffle()
	$Deck.deck_shuffle()

	await get_tree().create_timer(0.3).timeout
	for card in range(2): # Card amount
		for player in range(player_amount): # Player amount
			player = (starting_player + player) % player_amount
			await get_tree().create_timer(0.2).timeout
			#deck.deal_player(player)
			$Deck.deal_player(player)

	for card in range(5):
		await get_tree().create_timer(0.2).timeout
		#deck.deal("table")
		$Deck.deal("table")

	var blind_halfer = 2
	for player in range(2):
		player = (starting_player + player) % player_amount
		await get_tree().create_timer(0.2).timeout
		@warning_ignore("integer_division")
		pot += $Hands.get_node("HandP" + str(player)).bet(min_bet/blind_halfer)
		money_display_update(player)
		blind_halfer = 1

	print("starting player: ", starting_player)
	Global.starting_player = starting_player
	Global.current_turn = 0
	$ExtraLayer/RoundLabel.text = "Round 1"
	game_loop((starting_player + 2) % player_amount)

func game_loop(player: int):
	while true:
		await get_tree().create_timer(0.3).timeout
		var escape = pk_logic.turn(player)
		if len(Global.fold_list) == 3:
			uncontested_win()
			game_reset()
			break
		elif escape == 0:
			player_turn()
			break
		elif escape == -1:
			await get_tree().create_timer(0.5).timeout
			next_phase()
			break
		else: # Either -2 or 1, 2, 3 (AI_players)
			player = (player + 1) % 4


func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)
	table_cards_physical.append(card)
	table_cards_data.append([card.value, card.suit])

func player_turn():
	$ButtonsLayer.visible = true
	$ButtonsLayer/ButtonsContainer/RaiseSlider.value = min_bet
	$ButtonsLayer/ButtonsContainer/RaiseSlider.max_value = $Hands.get_node("HandP" + "0").money - round_bet + $Hands.get_node("HandP" + "0").round_bet

func next_phase():
	phase += 1
	if phase == 1:
		table_cards_physical[0].flip_card()
		table_cards_physical[1].flip_card()
		table_cards_physical[2].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 2"
		indicator_reset()
		round_bet_reset()
	elif phase == 2:
		table_cards_physical[3].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 3"
		indicator_reset()
		round_bet_reset()
	elif phase == 3:
		table_cards_physical[4].flip_card()
		$ExtraLayer/RoundLabel.text = "Round 4"
		indicator_reset()
		round_bet_reset()
	elif phase == 4:
		$ExtraLayer/RoundLabel.text = "Showdown"
		showdown()
		$Countdown.start()
		return
	else:
		$ExtraLayer/RoundLabel.text = "Error"
		push_error("Round overflow")
	game_loop(Global.starting_player)


func _on_fold(player):
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Red")
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Fold"

	if player == 0:
		raise_amount = min_bet
		game_loop(1) # Change needed in mp

func _on_call(player):
	pot += $Hands.get_node("HandP" + str(player)).bet(round_bet)

	# Display updates
	var indicator = $ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator")
	if indicator.color != Color("Lime_Green"):
		indicator.color = Color("Lime_Green")
	else:
		indicator.modulate *= 1.5
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Call"
	money_display_update(player)

	if player == 0:
		raise_amount = min_bet
		game_loop(1) # Change needed in mp

func _on_raise(player):
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Blue")
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Raise"

	round_bet += raise_amount
	Global.current_turn = 1

	pot += $Hands.get_node("HandP" + str(player)).bet(round_bet)
	money_display_update(player)

	if player == 0:
		raise_amount = min_bet
		game_loop(1) # Change needed in mp

func _on_raise_slider_value_changed(value):
	raise_amount = int(value)

func indicator_reset():
	for player in range(4):
		if player not in Global.fold_list:
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Gray")
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").modulate = Color(1, 1, 1)
			$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = ""


func round_bet_reset():
	round_bet = 0

	for player in range(4):
		$Hands.get_node("HandP" + str(player)).round_bet = 0

func money_display_update(player = null):
	if player != null:
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).money) + " €"
	$ExtraLayer/PotLabel.text = "Pot: " + str(pot) + " €"


func showdown():
	var poker_hand_list = []

	for player in range(4):
		if player not in Global.fold_list:
			if player != 0: # Change needed in mp
				$Hands.flip_hand(player)
			var hand_and_river = $Hands.get_hand_content(player) + table_cards_data
			var poker_hand = pk_logic.check_hand(hand_and_river)
			$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = hand_types[poker_hand[0]]
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
		$Hands.get_node("HandP" + str(winners[0])).win(pot)
		$ExtraLayer.get_node("StatsP" + str(winners[0]) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(winners[0])).money) + " €"
	else:
		# WIP
		$ExtraLayer/RoundLabel.text = "It's a Tie!"

func uncontested_win():
	for player in range(4):
		if player not in Global.fold_list:
			$ExtraLayer/RoundLabel.text = "Player " + str(player + 1) + " Wins!"
			$Hands.get_node("HandP" + str(player)).win(pot)
			$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(player)).money) + " €"


func game_reset():
	pot = 0
	round_bet = min_bet

	Global.fold_list.clear()

	money_display_update()
	indicator_reset()
	

func _on_countdown_timeout():
	print(intermission)
	var break_secs = 6	
	if intermission >= 3 and intermission <= break_secs:
		$ExtraLayer/RoundLabel.text = "Next round starts in " + str(break_secs - intermission)
		intermission += 1
	elif intermission > break_secs:
		intermission = 0
		$Countdown.stop()
		game_reset()
	else:
		intermission += 1

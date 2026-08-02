extends Node2D

var kuhn_deck = [[11, "heart"], [12, "heart"], [13, "heart"]]
var players = [0, 2]
var starting_slot = 1

var turn = 0
var bet_bool = false
var pot = 0

var new_game_ready = false

func _ready():
	$Hands.change_card_overlap(120)
	GlobalSignal.hand_deal.connect($Hands._on_card_to_hand)

	$ButtonsLayer/ButtonsContainer/RaiseSlider.visible = false
	$ButtonsLayer/ButtonsContainer/Raise.text = "Bet"
	$ExtraLayer/RoundLabel.text = "Betting Round"

	$Hands.get_node("HandP0").set_balance(5)
	$Hands.get_node("HandP2").set_balance(5)

	GlobalSignal.fold.connect(_on_fold)
	GlobalSignal.call.connect(_on_call)
	GlobalSignal.raise.connect(_on_raise)

	game_begin()

func game_begin():
	$Deck.logic.custom_deck(kuhn_deck.duplicate())
	$Deck.deck_shuffle()
	await get_tree().create_timer(0.3).timeout
	for player in players:
		await get_tree().create_timer(0.2).timeout
		$Deck.deal_player(player)
		pot += $Hands.get_node("HandP" + str(player)).bet_simple(1)

	balance_display_update()
	betting_phase(players[starting_slot])

func betting_phase(player):
	if turn == 2:
		showdown_phase()
	else:
		if player == 0:
			$ButtonsLayer.visible = true
			return
		elif player == 2:
			var choice = randi_range(0, 1)
			if bet_bool:
				if $Hands.get_hand_content(player)[0][0] == 13:
					GlobalSignal.call.emit(player)
				elif choice == 1 and $Hands.get_hand_content(player)[0][0] != 11:
					GlobalSignal.call.emit(player)
				else:
					GlobalSignal.fold.emit(player)
					return
			else:
				if choice == 0:
					GlobalSignal.call.emit(player)
				elif choice == 1:
					GlobalSignal.raise.emit(player)

			balance_display_update()
			betting_phase(0)

func showdown_phase():
	$Hands.flip_hand(2)
	if $Hands.get_hand_content(0)[0][0] > $Hands.get_hand_content(2)[0][0]:
		$Hands.get_node("HandP" + str(0)).win(pot)
		$ExtraLayer/RoundLabel.text = "Showdown Round, Player 1 wins!"
	else:
		$Hands.get_node("HandP" + str(2)).win(pot)
		$ExtraLayer/RoundLabel.text = "Showdown Round, Player 2 wins!"

	balance_display_update()
	if $Hands.get_node("HandP" + str(0)).get_balance() < 0:
		game_end(2)
	elif $Hands.get_node("HandP" + str(2)).get_balance() < 0:
		game_end(0)
	else:
		new_game_ready = true

func uncontested_win(player):
	$Hands.get_node("HandP" + str(player)).win(pot)

	balance_display_update()
	if $Hands.get_node("HandP" + str(0)).get_balance() == 0:
		game_end(2)
	elif $Hands.get_node("HandP" + str(2)).get_balance() == 0:
		game_end(0)
	else:
		new_game_ready = true

func game_reset():
	$Deck.reset_deck()
	$Hands.flip_hand(2)
	$Hands.clear_hands()

	pot = 0
	turn = 0
	bet_bool = false

	for player in players:
		$Hands.get_node("HandP" + str(player)).round_bet = 0
	starting_slot = (starting_slot + 1) % 2

	balance_display_update()
	indicator_reset()
	$ExtraLayer/RoundLabel.text = "Betting Round"

func game_end(winner):
	$ExtraLayer/RoundLabel.text = "The winner is Player " + str(winner) + "!"

func _on_fold(player):
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Red")
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Fold"

	if player == 0:
		uncontested_win(2)
	else:
		uncontested_win(0)

func _on_call(player):
	if bet_bool == true:
		pot += $Hands.get_node("HandP" + str(player)).bet_simple(1)

	# Display updates
	var indicator = $ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator")
	if indicator.color != Color("Lime_Green"):
		indicator.color = Color("Lime_Green")
	else:
		indicator.modulate *= 1.5
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Call"
	
	turn += 1
	if player == 0:
		betting_phase(2)


func _on_raise(player):
	if bet_bool:
		_on_call(player)
		return
	$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Blue")
	$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = "Raise"

	pot += $Hands.get_node("HandP" + str(player)).bet_simple(1)
	bet_bool = true

	turn = 1
	if player == 0:
		betting_phase(2)


func balance_display_update():
	for p in players:
		$ExtraLayer.get_node("StatsP" + str(p) + "/HBC/PC/MC/CurrencyLabel").text = str($Hands.get_node("HandP" + str(p)).get_balance()) + " €"

	$ExtraLayer/PotLabel.text = "Pot: " + str(pot) + " €"

func indicator_reset():
	for player in players:
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").color = Color("Gray")
		$ExtraLayer.get_node("StatsP" + str(player) + "/HBC/Indicator").modulate = Color(1, 1, 1)
		$Hands.get_node("HandP" + str(player) + "/LabelPanel/PlayerLabel").text = ""

func _unhandled_input(event):
	# Click to start next hand
	if event is InputEventMouseButton and event.button_index == 1 and new_game_ready:
		new_game_ready = false
		game_reset()
		game_begin()

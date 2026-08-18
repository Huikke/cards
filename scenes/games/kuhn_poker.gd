extends Node2D

var kuhn_deck = [[11, "heart"], [12, "heart"], [13, "heart"]]
var players = [0, 1]
var players_balance = [10, 10]
var starting_slot = 1

var turn = 0
var bet_bool = false
var pot = 0

@onready var _main_label = $ExtraLayer/MainLabel
@onready var _pot_label = $ExtraLayer/PotLabel

var new_game_ready = false

func _ready():
	$Hands.set_seat_size(2)
	$Hands.change_card_overlap(120)
	$Hands.seat_setup[1].get_node("PokerStats").set_player_name("Player 2") # Quick and dirty
	GlobalSignal.hand_deal.connect($Hands._on_card_to_hand)

	$ButtonsLayer/ButtonsContainer/RaiseSlider.visible = false
	$ButtonsLayer/ButtonsContainer/Raise.text = "Bet"
	label_update("Main", "Betting Round")

	players_balance = [5, 5]

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
		$Deck.deal("player", player)
		pot += 1
		players_balance[player] -= 1

	balance_display_update()
	betting_phase(players[starting_slot])

func betting_phase(player):
	if turn == 2:
		showdown_phase()
	else:
		if player == 0:
			$ButtonsLayer.visible = true
			return
		elif player == 1:
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
	$Hands.flip_hand(1)
	if $Hands.get_hand_content(0)[0][0] > $Hands.get_hand_content(1)[0][0]:
		players_balance[0] += pot
		label_update("Main", "Showdown Round, Player 1 wins!")
	else:
		players_balance[1] += pot
		label_update("Main", "Showdown Round, Player 2 wins!")

	balance_display_update()
	if players_balance[0] <= 0:
		game_end(1)
	elif players_balance[1] <= 0:
		game_end(0)
	else:
		new_game_ready = true

func uncontested_win(player):
	players_balance[player] += pot

	balance_display_update()
	if players_balance[0] <= 0:
		game_end(1)
	elif players_balance[1] <= 0:
		game_end(0)
	else:
		new_game_ready = true

func game_reset():
	$Deck.reset_deck()
	$Hands.flip_hand(1)
	$Hands.clear_hands()

	pot = 0
	turn = 0
	bet_bool = false

	starting_slot = (starting_slot + 1) % 2

	balance_display_update()
	indicator_reset()
	label_update("Main", "Betting Round")

func game_end(winner):
	label_update("Main", "The winner is Player " + str(winner+1) + "!")

func _on_fold(player):
	indicator_color_update(player, Color("Red"))
	label_update("PlayerHeadsUp", "Fold", player)

	if player == 0:
		uncontested_win(1)
	else:
		uncontested_win(0)

func _on_call(player):
	if bet_bool == true:
		pot += 1
		players_balance[player] -= 1

	# Display updates
	indicator_color_update(player, Color("Lime_Green"))
	label_update("PlayerHeadsUp", "Call", player)

	turn += 1
	if player == 0:
		betting_phase(1)


func _on_raise(player, _amount = 1):
	if bet_bool:
		_on_call(player)
		return
	indicator_color_update(player, Color("Blue"))
	label_update("PlayerHeadsUp", "Raise", player)

	pot += 1
	players_balance[player] -= 1
	bet_bool = true

	turn = 1
	if player == 0:
		betting_phase(1)


func balance_display_update():
	for p in players:
		label_update("PlayerBalance", str(players_balance[p]), p)

	label_update("Pot", str("Pot: " + str(pot) + " €"))

@rpc("authority")
func label_update(label_name: String, text: String, number: int = -1) -> void:
	if label_name == "Main":
		_main_label.text = text
	elif label_name == "Pot":
		_pot_label.text = text
	elif label_name == "PlayerBalance":
		$Hands.seat_setup[number].get_node("PokerStats").set_balance(text)
	elif label_name == "PlayerHeadsUp":
		$Hands.seat_setup[number].get_node("PokerStats").set_heads_up(text)

func indicator_color_update(player: int, color: Color) -> void:
	$Hands.seat_setup[player].get_node("PokerStats").set_indicator_color(color)

func indicator_reset():
	for player in players:
		indicator_color_update(player, Color("Gray"))
		$Hands.change_hand_heads_up_text(player, "")

func _unhandled_input(event):
	# Click to start next hand
	if event is InputEventMouseButton and event.button_index == 1 and new_game_ready:
		new_game_ready = false
		game_reset()
		game_begin()

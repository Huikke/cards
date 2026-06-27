class_name poker_logic

signal player_turn
signal next_phase

func game_begin():
	var starting_player = randi_range(0, 3)
	print("starting player: ", starting_player)
	Global.starting_player = starting_player
	Global.current_turn = 0
	round_manager(starting_player)

func round_manager(player: int):
	while true:
		print("Current turn " + str(Global.current_turn))
		Global.current_turn += 1
		if Global.current_turn == 5:
			round_end()
			return
		if player in Global.folded:
			pass
		elif player == 0:
			player_turn.emit()
			return
		else:
			ai_turn(player)

		player = (player + 1) % 4

func round_end():
	print("next round")
	Global.current_turn = 0
	next_phase.emit()

func ai_turn(player: int):
	var choice = randi_range(0, 5)
	print(player, ": ", choice)
	if choice == 0:
		GlobalSignal.fold.emit(player)
		Global.folded.append(player)
	else:
		GlobalSignal.call.emit(player)

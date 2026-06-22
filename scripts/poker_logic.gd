class_name poker_logic

signal player_turn
signal next_phase

func game_begin():
	var starting_player = randi_range(0, 3)
	print("starting player: ", starting_player)
	Global.starting_player = starting_player
	round_manager(starting_player, -1)

func round_manager(starting_player: int, turn_passed: int):
	var player = starting_player
	turn_passed += 1
	for turn in range(turn_passed, 4):
		if player in Global.folded:
			player = (player + 1) % 4
			continue

		if player == 0:
			player_turn.emit(turn)
			return

		# When AI folds, it return's it's player number, which then gets
		# appended to folded array
		var ai_decision = ai_turn(player)
		if ai_decision != -1:
			Global.folded.append(player)

		if player == 3:
			player = 0
		else:
			player += 1
	
	# If for loop ends without returning, the round ends
	round_end()

func round_end():
	next_phase.emit()

func ai_turn(player: int):
	var choice = randi_range(0, 5)
	print(player, ": ", choice)
	if choice == 0:
		return player
	else:
		return -1 # working as false

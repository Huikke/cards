class_name poker_logic

func turn(player: int):
	print("Current turn " + str(Global.current_turn))
	Global.current_turn += 1
	if Global.current_turn == 5:
		round_end()
		return -1
	if player in Global.folded:
		return -2
	elif player == 0:
		return player
	else:
		ai_turn(player)

func round_end():
	print("next round")
	Global.current_turn = 0

func ai_turn(player: int):
	var choice = randi_range(0, 5)
	print(player, ": ", choice)
	if choice == 0:
		GlobalSignal.fold.emit(player)
		Global.folded.append(player)
	else:
		GlobalSignal.call.emit(player)

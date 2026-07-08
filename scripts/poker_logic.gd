class_name poker_logic

func turn(player: int):
	print("Current turn " + str(Global.current_turn))
	Global.current_turn += 1
	if Global.current_turn == 5:
		print("next round")
		Global.current_turn = 0
		return -1
	if player in Global.folded:
		return -2
	elif player == 0:
		return player
	else:
		ai_turn(player)

func ai_turn(player: int):
	var choice = randi_range(0, 20)
	print(player, ": ", choice)
	if choice == 0:
		GlobalSignal.fold.emit(player)
		Global.folded.append(player)
	else:
		GlobalSignal.call.emit(player)

func check_hand(cards: Array):
	var flush = false
	var straight = false

	var suit_count = {"spade": 0, "heart": 0, "club": 0, "diamond": 0}
	var ranks = []
	for i in range(0, len(cards)):
		match cards[i][1]:
			"spade":
				suit_count["spade"] += 1
			"heart":
				suit_count["heart"] += 1
			"club":
				suit_count["club"] += 1
			"diamond":
				suit_count["diamond"] += 1
		ranks.append(cards[i][0])

	ranks.sort()
	var rank_helper = 0
	var straight_count = 0
	var stack_size = 0
	var stack_amount = 0
	var rank_dict = {}
	print(ranks)
	for rank in ranks:
		# Straight
		if rank_helper == 0 or rank_helper - rank == -1:
			straight_count += 1
			rank_helper = rank
			# Process Ace
			if rank_helper == 13 and ranks[0] == 1:
				straight_count += 1
			# Break on Straight
			if straight_count >= 5:
				straight = true
				break
		elif rank_helper - rank == 0:
			pass
		else:
			straight_count = 0
			rank_helper = 0
		
		# Stack
		if rank_dict.has(rank):
			rank_dict[rank] += 1
		else:
			rank_dict[rank] = 1

	for suit in suit_count:
		if suit_count[suit] >= 5:
			flush = true

	# Stack
	for rank in rank_dict:
		if rank_dict[rank] == 1:
			continue
		elif rank_dict[rank] == 2 and stack_amount == 0:
			stack_size = 2
			stack_amount = 1
		elif rank_dict[rank] == 3 and stack_amount == 0:
			stack_size = 3
			stack_amount = 1
		elif rank_dict[rank] == 2 and stack_amount == 1:
			stack_amount = 2
		elif rank_dict[rank] == 3 and stack_amount == 1:
			stack_size = 3
			stack_amount = 2
		else:
			print("Error! (Or more likely there's 3 pairs)")


	print(str(straight) + " " + str(straight_count))
	print(str(flush) + " " + str(suit_count))
	print(str(stack_size) + ", " + str(stack_amount))

	if flush and straight: # This is not ready
		return "Straight Flush"
	if stack_size == 4:
		return "Four of a Kind"
	if stack_size == 3 and stack_amount == 2:
		return "Full House"
	elif flush:
		return "Flush"
	elif straight:
		return "Straight"
	elif stack_size == 3 and stack_amount == 1:
		return "Three of a Kind"
	elif stack_size == 2 and stack_amount == 2:
		return "Two Pair"
	elif stack_size == 2 and stack_amount == 1:
		return "Pair"
	else:
		return "High Card"

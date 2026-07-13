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
	if choice == 0:
		GlobalSignal.fold.emit(player)
		Global.folded.append(player)
	else:
		GlobalSignal.call.emit(player)

func check_hand(cards: Array):
	var rank_helper = 0
	var straight_count = 0

	# Ace is the best
	for card in cards:
		if card[0] == 1:
			card[0] = 14
			# Ace is being recognised as 1 in straight as well
			rank_helper = 1
			straight_count = 1

	cards.sort()

	var flush = ""
	var straight = 0

	var suit_values = {"spade": [], "heart": [], "club": [], "diamond": []}

	var stack_size = 0
	var stack_amount = 0
	var rank_values = {}

	for card in cards:
		var rank = card[0]
		var suit = card[1]

		# Suit
		match suit:
			"spade":
				suit_values["spade"].append(rank)
			"heart":
				suit_values["heart"].append(rank)
			"club":
				suit_values["club"].append(rank)
			"diamond":
				suit_values["diamond"].append(rank)

		# Line
		if rank_helper == 0 or rank_helper - rank == -1:
			straight_count += 1
			rank_helper = rank
			if straight_count >= 5:
				straight = rank
		elif rank_helper - rank == 0:
			pass
		else:
			straight_count = 1
			rank_helper = rank
		
		# Stack
		if rank_values.has(rank):
			rank_values[rank] += 1
		else:
			rank_values[rank] = 1

	for suit in suit_values:
		if len(suit_values[suit]) >= 5:
			if len(suit_values[suit]) >= 6:
				if len(suit_values[suit]) == 7:
					suit_values[suit].pop_front()
				suit_values[suit].pop_front()
			flush = suit

	# Stack
	var stacks = []
	for rank in rank_values.keys():
		if rank_values[rank] == 1:
			rank_values.erase(rank)
		else:
			stacks.append([rank_values[rank], rank])
	print(stacks)
	if len(stacks) >= 2:
		stacks.sort()
		var count = 0
		for stack in stacks:
			count += stack[0]
		if count > 5:
			if stacks[0][0] == 2:
				stacks.pop_front()
			elif stacks[0][0] == 3:
				stacks[0][0] = 2
	print(stacks)


	if flush and straight: # This is not ready
		return "Straight Flush"
	if len(stacks) == 1 and stacks[0][0] == 4:
		return  ["Four of a Kind", stacks]
	if len(stacks) == 2 and stacks[1][0] == 3:
		return ["Full House", stacks]
	elif flush != "":
		return ["Flush", suit_values[flush]]
	elif straight != 0:
		return ["Straight", straight]
	elif len(stacks) == 1 and stacks[0][0] == 3:
		return ["Three of a Kind", stacks]
	elif len(stacks) == 2 and stacks[1][0] == 2:
		return ["Two Pair", stacks]
	elif len(stacks) == 1 and stacks[0][0] == 2:
		return ["Pair", stacks]
	else:
		return "High Card"

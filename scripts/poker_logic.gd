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

	cards.sort()
	cards.reverse()

	var flush = ""
	var straight = 0
	# For Flush
	var suit_values = {"spade": [], "heart": [], "club": [], "diamond": []}
	# For Stack
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
		if rank_helper - rank == 0 or straight_count == 5:
			pass
		elif rank_helper == 0 or rank_helper - rank == 1:
			straight_count += 1
			rank_helper = rank
			if straight_count == 5:
				straight = rank + 4
			elif straight_count == 4 and rank == 2 and cards[0][0] == 14:
				straight_count += 1
				straight = rank + 3
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
					suit_values[suit].pop_back()
				suit_values[suit].pop_back()
			flush = suit

	# Stack
	var stacks = []
	var singles = []
	for rank in rank_values:
		if rank_values[rank] == 1:
			singles.append([rank_values[rank], rank])
		else:
			stacks.append([rank_values[rank], rank])

	stacks.sort()
	stacks.reverse()

	if len(stacks) >= 2:
		var count = 0
		for stack in stacks:
			count += stack[0]
		if count > 5:
			if stacks[-1][0] == 2:
				stacks[-1][0] = 1
				singles.append(stacks.pop_back())
				singles.sort()
				singles.reverse()
			elif stacks[-1][0] == 3:
				stacks[-1][0] = 2


	# Final Judgment
	if flush and straight: # This is not ready
		return "Straight Flush"
	if len(stacks) == 1 and stacks[0][0] == 4:
		return  ["Four of a Kind", stacks]
	if len(stacks) == 2 and stacks[0][0] == 3:
		return ["Full House", stacks]
	elif flush != "":
		return ["Flush", suit_values[flush]]
	elif straight != 0:
		return ["Straight", straight]
	elif len(stacks) == 1 and stacks[0][0] == 3:
		return ["Three of a Kind", stacks]
	elif len(stacks) == 2 and stacks[0][0] == 2:
		return ["Two Pair", stacks]
	elif len(stacks) == 1 and stacks[0][0] == 2:
		return ["Pair", stacks]
	else:
		singles.resize(5)
		return ["High Card", singles]

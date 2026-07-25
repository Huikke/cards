class_name poker_logic

func turn(player: int):
	if player == 0: # Needs change in mp
		return player
	else:
		ai_turn(player)
		return player

func ai_turn(player: int):
	var choice = randi_range(0, 20)
	if choice == 0:
		GlobalSignal.fold.emit(player)
	elif choice >= 1 and choice <= 2:
		GlobalSignal.raise.emit(player)
	else:
		GlobalSignal.call.emit(player)

func check_hand(cards: Array):
	# Ace is the best
	for card in cards:
		if card[0] == 1:
			card[0] = 14

	cards.sort()
	cards.reverse()

	# For Straight Flush
	var straight_flush = false
	var straight_flush_hand = []
	# For Flush
	var flush = ""
	var suit_values = {"spade": [], "heart": [], "club": [], "diamond": []}
	# For Straight
	var straight = false
	var straight_hand = []
	var prev_rank = 0
	# For Stack
	var stacks_dict = {}
	var stack_size_list = [0, 0, 0, 0]
	var stack_hand = []

	for card in cards:
		var rank = card[0]
		var suit = card[1]

		# Suit
		match suit:
			"spade":
				suit_values["spade"].append(card)
			"heart":
				suit_values["heart"].append(card)
			"club":
				suit_values["club"].append(card)
			"diamond":
				suit_values["diamond"].append(card)

		# Line
		var results = straight_calculator(card, prev_rank, straight_hand, cards[0])
		if results != null:
			prev_rank = results[0]
			straight = results[1]

		# Stack
		if stacks_dict.has(rank):
			stacks_dict[rank].append(card)
		else:
			stacks_dict[rank] = [card]


	# Suit
	for suit in suit_values:
		if len(suit_values[suit]) >= 5:
			var prev_card = 0
			for card in suit_values[suit]:
				var results = straight_calculator(card, prev_card, straight_flush_hand, suit_values[suit][0])
				if results != null:
					prev_card = results[0]
					straight_flush = results[1]
			flush = suit

	# Stacks
	var stacks_dict2 = {}
	for rank in stacks_dict:
		if stacks_dict2.has(len(stacks_dict[rank])):
			stacks_dict2[len(stacks_dict[rank])].append(stacks_dict[rank])
		else:
			stacks_dict2[len(stacks_dict[rank])] = [stacks_dict[rank]]
		stack_size_list[len(stacks_dict[rank])-1] += 1

	var total_size = 0
	for size in range(4, 0, -1):
		if stack_size_list[size-1] == 0:
			continue
		for stack in stacks_dict2[size]:
			total_size += size
			if total_size <= 5:
				for card in stack:
					stack_hand.append(card)
			elif size == 3:
				total_size -= size
				var new_stack = [stack[0], stack[1]]
				if stacks_dict2.has(2):
					stacks_dict2[2].append(new_stack)
					stacks_dict2[2].sort()
					stacks_dict2[2].reverse()
					stack_size_list[size-2] += 1
				else:
					stacks_dict2[2] = [new_stack]
					stack_size_list[size-2] += 1
			elif size == 2:
				total_size -= size
				var new_stack = [stack[0]]
				if stacks_dict2.has(1):
					stacks_dict2[1].append(new_stack)
					stacks_dict2[1].sort()
					stacks_dict2[1].reverse()
					stack_size_list[size-2] += 1
				else:
					stacks_dict2[1] = [new_stack]
					stack_size_list[size-2] += 1


	# Final Judgment
	if straight_flush:
		return [9, straight_flush_hand]
	if stack_size_list[3] >= 1:
		return  [8, stack_hand]
	if stack_size_list[2] >= 1 and stack_size_list[1] >= 1 or stack_size_list[2] >= 2:
		return [7, stack_hand]
	elif flush != "":
		suit_values[flush].resize(5)
		return [6, suit_values[flush]]
	elif straight:
		return [5, straight_hand]
	elif stack_size_list[2] == 1:
		return [4, stack_hand]
	elif stack_size_list[1] >= 2:
		return [3, stack_hand]
	elif stack_size_list[1] == 1:
		return [2, stack_hand]
	else:
		return [1, stack_hand]

func straight_calculator(card, prev_rank, straight_hand, first_card):
	var rank = card[0]
	if prev_rank - rank == 0 or len(straight_hand) == 5:
		pass
	elif prev_rank == 0 or prev_rank - rank == 1:
		straight_hand.append(card)
		prev_rank = rank
		if len(straight_hand) == 5:
			return [prev_rank, true]
		elif len(straight_hand) == 4 and rank == 2 and first_card[0] == 14:
			straight_hand.append(first_card)
			return [prev_rank, true]
		return [prev_rank, false]
	else:
		straight_hand.clear()
		straight_hand.append(card)
		prev_rank = rank
		return [prev_rank, false]

func compare_hand(hand1, hand2):
	if hand1[0] > hand2[0]:
		return 1
	elif hand1[0] < hand2[0]:
		return 2
	elif hand1[0] == 0 and hand2[0] == 0:
		return 0

	for i in range(0, 5):
		if hand1[1][i][0] > hand2[1][i][0]:
			return 1
		elif hand1[1][i][0] < hand2[1][i][0]:
			return 2
	return 0

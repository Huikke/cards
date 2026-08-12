extends Node2D

var pk_logic = PokerLogic.new()

func _ready():
	var hand = []

	# Straight
	hand = [[13, "club"], [1, "diamond"], [2, "heart"], [13, "heart"], [11, "club"], [12, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))
	hand = [[11, "spade"], [9, "diamond"], [8, "heart"], [13, "heart"], [11, "club"], [7, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))
	hand = [[3, "spade"], [4, "diamond"], [2, "heart"], [7, "heart"], [11, "club"], [1, "diamond"], [5, "club"]]
	print(pk_logic.check_hand(hand))

	# Flush
	hand = [[13, "diamond"], [9, "diamond"], [2, "diamond"], [3, "diamond"], [6, "diamond"], [10, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))
	
	# Stacks
	# Pair
	hand = [[13, "spade"], [4, "diamond"], [8, "club"], [4, "heart"], [5, "club"], [7, "diamond"], [3, "heart"]]
	print(pk_logic.check_hand(hand))
	# Four of Kind
	hand = [[5, "spade"], [13, "diamond"], [13, "club"], [13, "heart"], [5, "club"], [13, "spade"], [3, "heart"]]
	print(pk_logic.check_hand(hand))
	# Two Pair
	hand = [[13, "spade"], [3, "diamond"], [13, "club"], [3, "heart"], [4, "club"], [7, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))
	# Full House
	hand = [[13, "spade"], [10, "diamond"], [13, "club"], [13, "heart"], [12, "club"], [12, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))
	# Full House 2
	hand = [[6, "spade"], [9, "diamond"], [6, "club"], [6, "heart"], [9, "club"], [9, "heart"], [10, "club"]]
	print(pk_logic.check_hand(hand))

	# High Card
	hand = [[13, "spade"], [4, "diamond"], [8, "club"], [1, "heart"], [5, "club"], [7, "diamond"], [3, "heart"]]
	print(pk_logic.check_hand(hand))
	
	# Straight Flush
	hand = [[10, "diamond"], [1, "diamond"], [2, "diamond"], [13, "diamond"], [11, "diamond"], [12, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))

	# Fake Straight Flush
	hand = [[10, "diamond"], [1, "diamond"], [2, "diamond"], [13, "diamond"], [11, "diamond"], [12, "club"], [10, "club"]]
	print(pk_logic.check_hand(hand))

	# Straight Flush
	hand = [[4, "diamond"], [1, "diamond"], [2, "diamond"], [3, "diamond"], [11, "diamond"], [5, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))

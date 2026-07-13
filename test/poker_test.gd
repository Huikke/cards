extends Node2D

var pk_logic = poker_logic.new()

func _ready():
	var hand = [[10, "spade"], [1, "diamond"], [2, "heart"], [13, "heart"], [6, "club"], [12, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))
	hand = [[13, "spade"], [1, "diamond"], [2, "heart"], [13, "heart"], [11, "club"], [12, "diamond"], [10, "club"]]
	print(pk_logic.check_hand(hand))

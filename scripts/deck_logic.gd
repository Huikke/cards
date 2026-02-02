class_name deck_logic

var deck = []

func _init():
	new_deck()

func new_deck():
	var suits = ["spade", "heart", "club", "diamond"]
	for i in range(1, 14):
		for suit in suits:
			deck.append([i, suit])

func shuffle():
	deck.shuffle()

class_name DeckLogic

var deck = []

func _init():
	full_deck()

func full_deck():
	var suits = ["spade", "heart", "club", "diamond"]
	for i in range(1, 14):
		for suit in suits:
			deck.append([i, suit])

func custom_deck(cards: Array):
	deck = cards

func shuffle():
	deck.shuffle()

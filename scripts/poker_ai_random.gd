extends RefCounted
class_name PokerAiRandom

static func ai_random(player: int):
	var choice = randi_range(0, 20)
	if choice in range(0, 2):
		GlobalSignal.fold.emit(player)
	elif choice in range(2, 8):
		GlobalSignal.raise.emit(player)
	else:
		GlobalSignal.call.emit(player)

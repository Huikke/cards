extends RefCounted
class_name PokerAiRandom

static func ai_random1(player: int):
	var choice = randi_range(0, 20)
	if choice in range(0, 1):
		GlobalSignal.fold.emit(player)
	elif choice in range(2, 4):
		GlobalSignal.raise.emit(player)
	else:
		GlobalSignal.call.emit(player)

static func ai_random2(player: int):
	var choice = randi_range(0, 20)
	if choice in range(0, 2):
		GlobalSignal.fold.emit(player)
	elif choice in range(2, 10):
		GlobalSignal.raise.emit(player)
	else:
		GlobalSignal.call.emit(player)

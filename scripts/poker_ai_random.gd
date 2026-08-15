extends RefCounted
class_name PokerAiRandom

static func ai_random(player: int):
	var choice = randi_range(0, 20)
	if choice in range(5, 8):
		GlobalSignal.fold.emit(player)
	elif choice in range(2, 5):
		# Bug: if player doesn't have 200, then they simply call
		GlobalSignal.raise.emit(player, 200)
	else:
		GlobalSignal.call.emit(player)

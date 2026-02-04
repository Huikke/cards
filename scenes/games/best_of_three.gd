extends Node2D

var mathbot = preload("res://scripts/mathbot.gd").new()
var card_scene = preload("res://scenes/objects/card.tscn")

var human_score = 0
var ai_score = 0

func _ready():
	$Hands.change_card_overlap(120)
	$Deck.deck_shuffle()
	await get_tree().create_timer(0.3).timeout
	for i in range(3):
		for j in range(2):
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(j)


func _on_hands_card_selected(human_card):
	if human_card.pnum == 0: # Only play own cards
		var ai_card = ai_play()

		var winner = mathbot.bigger(human_card, ai_card)
		if winner == null:
			pass
		elif winner == human_card:
			human_score += 1
		elif winner == ai_card:
			ai_score += 1
		
		var center = get_viewport().get_camera_2d().position
		var position_nudge = [Vector2(0, 200), Vector2(0,-200)]
		for card in [human_card, ai_card]:
			var wild_card = card_scene.instantiate() as Area2D
			wild_card.position = center + position_nudge[card.pnum]
			wild_card.value = card.value
			wild_card.suit = card.suit
			add_child(wild_card)
			wild_card.turn_card()

		human_card.queue_free()
		ai_card.queue_free()
		
		$ScoreDisplay/Score.text = str(human_score) + " : " + str(ai_score)

		if game_over == true:
			if human_score > ai_score:
				$W.visible = true
			elif human_score < ai_score:
				$L.visible = true
			else:
				$T.visible = true


var first = true
var game_over = false
func ai_play():
	var ai_hand = $Hands/P2_Hand.get_children()
	# Temporary solution to our invisible card
	if first:
		ai_hand.pop_front()
		ai_hand.pop_back()
	var ai_card = ai_hand.pick_random()
	print(ai_hand)
	if len(ai_hand) == 1: # hand does not go empty before queue free
		game_over = true
	return ai_card

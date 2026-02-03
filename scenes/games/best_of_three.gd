extends Node2D

var mathbot = preload("res://scripts/mathbot.gd").new()
var card_scene = preload("res://scenes/objects/card.tscn")

var human_score = 0
var ai_score = 0

func _ready():
	for hand in $HUD.get_children():
		hand.get_child(0).custom_minimum_size.x = 120
	$Deck.deck_shuffle()
	await get_tree().create_timer(0.3).timeout
	for i in range(3):
		for j in range(2):
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(j)


func _on_hud_card_selected(human_card):
	if human_card.pnum == 0: # Only play own cards
		var ai_card = ai_play()

		var winner = mathbot.bigger(human_card, ai_card)
		if winner == human_card:
			human_score += 1
		elif winner == ai_card:
			ai_score += 1
		var VIP_var = 600
		for card in [human_card, ai_card]:
			var wild_card = card_scene.instantiate() as Area2D
			wild_card.position = Vector2(660, VIP_var)
			VIP_var = 200
			wild_card.value = card.value
			wild_card.suit = card.suit
			add_child(wild_card)
			wild_card.turn_card()

		human_card.queue_free()
		ai_card.queue_free()
		
		if game_over == true:
			if human_score > ai_score:
				$W.visible = true
			else:
				$L.visible = true


var first = true
var game_over = false
func ai_play():
	var ai_hand = $HUD/P2_Hand.get_children()
	# Temporary solution to our invisible card
	if first:
		ai_hand.pop_front()
	var ai_card = ai_hand.pick_random()
	print(ai_hand)
	if len(ai_hand) == 1: # hand does not go empty before queue free
		game_over = true
	return ai_card

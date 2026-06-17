extends Node2D

var card_placement: Vector2

func _ready():
	card_placement = get_viewport().get_camera_2d().position - Vector2(300, 0)
	$Hands.change_card_overlap(120)
	$Deck.deck_shuffle()
	await get_tree().create_timer(0.3).timeout
	for card in range(2): # Card amount
		for player in range(4): # Player amount
			await get_tree().create_timer(0.2).timeout
			$Deck.deal_player(player)
	
	for card in range(5):
		await get_tree().create_timer(0.25).timeout
		$Deck.deal("table")

func _on_deck_table_deal(card):
	card.position = card_placement
	card_placement += Vector2(125, 0)


func _on_call_pressed():
	$Hands.get_hand_content()

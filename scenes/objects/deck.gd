extends Area2D

signal deal_signal

var card_scene = preload("res://scenes/objects/card.tscn")
var back_sprite = "flowexyz.svg"

var deck_logic

func _ready():
	deck_logic = load("res://scripts/deck_logic.gd").new()
	$Sprite.texture = load("res://assets/cards/back/" + back_sprite)
	for i in range(1, len(deck_logic.deck)/6 + 1):
		var card_padding = $Sprite.duplicate()
		card_padding.position += Vector2(i*2, i*2)
		$AdditionalSprites.add_child(card_padding)

func _on_input_event(_viewport, event, _shape_idx):
	if deck_logic.deck == []: # Bandage fix on too fast clicking
			queue_free()
			return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 3:
			deck_logic.shuffle()
			shuffle_animation()
		elif event.button_index == 2:
			deal_burst()
		elif event.button_index == 4:
			deal_player(1)
		elif event.button_index == 5:
			deal_player(0)
		else:
			deal()

		if deck_logic.deck == []:
			queue_free()
			return

		var card_padding = $AdditionalSprites.get_child_count()
		if card_padding > len(deck_logic.deck) / card_padding or len(deck_logic.deck) == 1:
			$AdditionalSprites.get_child(-1).queue_free()

func deal(mode: String = "local"):
	var card = card_scene.instantiate() as Area2D
	card.position = position
	var pop_card = deck_logic.deck.pop_front()
	card.value = pop_card[0]
	card.suit = pop_card[1]

	if mode == "local":
		deal_animation(card)
	elif mode == "direct":
		return card

func deal_burst():
	for i in len(deck_logic.deck):
		deal()

func deal_player(player):
	var card = deal("direct")
	deal_signal.emit(card, player)
	

func deal_animation(card):
	add_sibling(card)
	var x_move = randf_range(-1, 1)
	var y_move
	if x_move > 0:
		y_move = [1-x_move, -1+x_move].pick_random()
	else:
		y_move = [-1-x_move, 1+x_move].pick_random()
	card.direction = Vector2(x_move, y_move * 1.3)
	card.speed = 1000
	card.get_node("StopMotion").start()

func shuffle_animation():
	var tween = create_tween()
	tween.tween_property(self, "rotation", 0.5, 0.13)
	tween.tween_property(self, "rotation", -0.5, 0.26)
	tween.tween_property(self, "rotation", 0, 0.13)

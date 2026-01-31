extends Area2D

var card_scene = preload("res://scenes/card.tscn")
var back_sprite = "flowexyz.svg"
var deck = []

func _ready():
	$Sprite.texture = load("res://graphics/cards/back/" + back_sprite)
	var suits = ["spade", "heart", "club", "diamond"]
	for i in range(1, 14):
		for suit in suits:
			deck.append([i, suit])
	for i in range(1, len(deck)/6 + 1):
		var card_padding = $Sprite.duplicate()
		card_padding.position += Vector2(i*2, i*2)
		$AdditionalSprites.add_child(card_padding)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 3:
			deck.shuffle()
			shuffle_animation()
		elif event.button_index == 2:
			fast_deal()
		else:
			deal()

		if deck == []:
			queue_free()
			return

		var card_padding = $AdditionalSprites.get_child_count()
		if card_padding > len(deck) / card_padding or len(deck) == 1:
			$AdditionalSprites.get_child(-1).queue_free()

func deal():
	var card = card_scene.instantiate() as Area2D
	card.position = position
	card.scale = Vector2(0.5, 0.5)
	var pop_card = deck.pop_front()
	card.value = pop_card[0]
	card.suit = pop_card[1]

	add_sibling(card)
	deal_animation(card)

func fast_deal():
	for i in len(deck):
		deal()

func deal_animation(card):
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

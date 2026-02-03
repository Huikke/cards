extends GameObject2D
class_name Deck

signal deal_signal

var card_scene = preload("res://scenes/objects/card.tscn")
var back_sprite = preload("res://assets/cards/back/" + "chicken.svg")

var logic

func _ready():
	logic = load("res://scripts/deck_logic.gd").new()
	$Sprite.texture = back_sprite
	for i in range(1, len(logic.deck)/6 + 1):
		var card_padding = $Sprite.duplicate()
		card_padding.position += Vector2(i*2, i*2)
		$AdditionalSprites.add_child(card_padding)

func mouse2():
	if empty_delete():
		return
	deal()
	if empty_delete():
		return
	card_stack()

func mouse3():
	deck_shuffle()

func mouse4():
	if empty_delete():
		return
	deal_player(1)
	if empty_delete():
		return
	card_stack()

func mouse5():
	if empty_delete():
		return
	deal_player(0)
	if empty_delete():
		return
	card_stack()

func deal(mode: String = "local"):
	var card = card_scene.instantiate()
	card.position = position
	var pop_card = logic.deck.pop_front()
	card.value = pop_card[0]
	card.suit = pop_card[1]
	card.back_sprite = back_sprite

	if mode == "local":
		deck_deal(card)
	elif mode == "direct":
		return card

func deal_burst():
	for i in len(logic.deck):
		deal()

func deal_player(player):
	var card = deal("direct")
	deal_signal.emit(card, player)
	

func deck_deal(card):
	get_parent().add_child(card)
	var x_move = randf_range(-1, 1)
	var y_move
	if x_move > 0:
		y_move = [1-x_move, -1+x_move].pick_random()
	else:
		y_move = [-1-x_move, 1+x_move].pick_random()
	card.direction = Vector2(x_move, y_move * 1.3)
	card.speed = 1000
	card.get_node("StopMotion").start()

func deck_shuffle():
	logic.shuffle()
	var tween = create_tween()
	tween.tween_property(self, "rotation", 0.5, 0.13)
	tween.tween_property(self, "rotation", -0.5, 0.26)
	tween.tween_property(self, "rotation", 0, 0.13)

# Cosmetic, adds additional cards to the bottom to make illusion of card stack
func card_stack():
	var stack_count = $AdditionalSprites.get_child_count()
	if stack_count > len(logic.deck) / stack_count or len(logic.deck) == 1:
		$AdditionalSprites.get_child(-1).queue_free()

func empty_delete():
	if logic.deck == []:
		queue_free()
		return true

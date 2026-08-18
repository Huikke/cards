extends GameObject2D
class_name JapaseneDeck

var card_scene = preload("res://scenes/objects/flip_card.tscn")
@onready var back_sprite = Global.back_art

var logic = JapaneseDeckLogic.new("hiragana")

func _ready():
	if back_sprite != "":
		$Sprite.texture = load(back_sprite)
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
	deal("player", 2)
	if empty_delete():
		return
	card_stack()

func mouse5():
	if empty_delete():
		return
	deal("player", 0)
	if empty_delete():
		return
	card_stack()


func deal(mode: String = "local", player: int = -1):
	var pop_card = logic.deck.pop_front()
	if mode == "local" or mode == "table":
		deal_2d(pop_card, mode)
	elif mode == "player":
		deal_ui(pop_card, player)

@rpc("authority")
func deal_2d(pop_card: Array, mode: String):
	if Global.mp_enabled == true and multiplayer.is_server():
		deal_2d.rpc(pop_card, mode)
	var card = card_scene.instantiate()
	card.position = position
	card.content = pop_card

	if mode == "local":
		deck_deal(card, true)
	if mode == "table":
		deck_deal(card, false)

@rpc("authority")
func deal_ui(pop_card: Array, player: int):
	if Global.mp_enabled == true and multiplayer.is_server():
		deal_ui.rpc(pop_card, player)
	var card = {}
	card["value"] = pop_card[0]
	card["suit"] = pop_card[1]
	GlobalSignal.hand_deal.emit(card, player)

func deal_burst():
	for i in len(logic.deck):
		deal()


func deck_deal(card, motion: bool = false):
	get_parent().add_child(card)

	if motion:
		var x_move = randf_range(-1, 1)
		var y_move
		if x_move > 0:
			y_move = [1-x_move, -1+x_move].pick_random()
		else:
			y_move = [-1-x_move, 1+x_move].pick_random()
		card.direction = Vector2(x_move, y_move * 1.3)
		card.speed = 1000
		card.get_node("StopMotion").start()
	else:
		GlobalSignal.table_deal.emit(card)

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

func reset_deck(type):
	logic = JapaneseDeckLogic.new(type)

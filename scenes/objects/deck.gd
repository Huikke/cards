extends GameObject2D
class_name Deck

var card_scene: Resource
@onready var back_sprite = Global.back_art

var logic: Object

func _ready() -> void:
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


func deal(mode: String = "local", player: int = -1) -> void:
	var pop_card = logic.deck.pop_front()
	if mode == "local" or mode == "table":
		deal_2d(pop_card, mode)
	elif mode == "player":
		deal_ui(pop_card, player)

@rpc("authority")
func deal_2d(pop_card: Array, mode: String) -> void:
	pass

@rpc("authority")
func deal_ui(pop_card: Array, player: int) -> void:
	pass

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

func deck_shuffle() -> void:
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

func reset_deck(type: int = -1, size: int = -1) -> void:
	pass

extends Deck

func _ready():
	card_scene = preload("res://scenes/objects/playing_card.tscn")
	logic = DeckLogic.new()
	super()


@rpc("authority")
func deal_2d(pop_card: Array, mode: String) -> void:
	if Global.mp_enabled == true and multiplayer.is_server():
		deal_2d.rpc(pop_card, mode)
	var card = card_scene.instantiate()
	card.position = position
	card.value = pop_card[0]
	card.suit = pop_card[1]
	card.back_sprite = back_sprite

	if mode == "local":
		deck_deal(card, true)
	if mode == "table":
		deck_deal(card, false)

@rpc("authority")
func deal_ui(pop_card: Array, player: int) -> void:
	if Global.mp_enabled == true and multiplayer.is_server():
		deal_ui.rpc(pop_card, back_sprite, player)
	var card = {}
	card["value"] = pop_card[0]
	card["suit"] = pop_card[1]
	card["back_sprite"] = back_sprite
	GlobalSignal.hand_deal.emit(card, player)


func reset_deck(type: int = -1, size: int = -1) -> void:
	if type == -1 and size == -1:
		logic = DeckLogic.new()
	else:
		push_error("Error: Invalid Playing Deck")

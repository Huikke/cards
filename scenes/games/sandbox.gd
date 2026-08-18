extends Node2D

var card_scene = preload("res://scenes/objects/card.tscn")
signal card_entered(Area2D, int)

func _ready():
	$Hands.change_card_overlap(40)
	GlobalSignal.hand_deal.connect($Hands._on_card_to_hand)

func _on_area_entered(object, area):
	if object is not Card:
		return
	var p: int
	if area == $AreaP1:
		p = 0
	elif area == $AreaP2:
		p = 1
	elif area == $AreaP3:
		p = 2
	elif area == $AreaP4:
		p = 3
	card_entered.emit(object, p)
	object.queue_free()

func _on_hands_card_selected(card_ui):
	var card_ow = card_scene.instantiate() # ow == Overworld
	card_ow.position = get_viewport().get_camera_2d().position
	card_ow.value = card_ui.value
	card_ow.suit = card_ui.suit

	$Objects.add_child(card_ow)
	card_ui.queue_free()

func _on_add_player_pressed() -> void:
	$Hands.set_seat_size(len($Hands.seat_setup) + 1)

func _on_remove_player_pressed() -> void:
	$Hands.set_seat_size(len($Hands.seat_setup) - 1)

var decks = ["res://scenes/objects/deck.tscn", "res://scenes/objects/japanese_deck.tscn", "res://scenes/objects/japanese_deck.tscn"]
var no = 0
func _on_spawn_deck_pressed() -> void:
	var new_deck = load(decks[no]).instantiate()
	add_child(new_deck)
	if no == 2:
		new_deck.reset_deck("katakana")

func _on_deck_left_pressed() -> void:
	no = (no - 1) % len(decks)

func _on_deck_right_pressed() -> void:
	no = (no + 1) % len(decks)

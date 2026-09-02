extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$FlipCardDeck.reset_deck(Global.deck_type, Global.deck_size)

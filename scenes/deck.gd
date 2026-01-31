extends Area2D

signal pop_card
var card_scene = preload("res://scenes/card.tscn")
var back_sprite = "firemon.svg"
var deck = []
var rotate: bool

func _ready():
	$Sprite.texture = load("res://graphics/cards/back/" + back_sprite)
	var suits = ["spade", "heart", "club", "diamond"]
	for i in range(1, 14):
		for suit in suits:
			deck.append([i, suit])
		

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 3:
			deck.shuffle()
			shuffle_animation()
		elif deck != []:
			pop_card.emit(self, deck.pop_front())
		if deck == []:
			queue_free()

func shuffle_animation():
	var tween = create_tween()
	tween.tween_property(self, "rotation", 0.5, 0.13)
	tween.tween_property(self, "rotation", -0.5, 0.26)
	tween.tween_property(self, "rotation", 0, 0.13)

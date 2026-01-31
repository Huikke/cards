extends Node2D

var card_scene = preload("res://scenes/card.tscn")
var suits = ["spade", "heart", "club", "diamond"]
var back_sprite = "firemon.svg"

func _on_spawner_area_pop_card(body, card_vs):
	var card = card_scene.instantiate() as Area2D
	card.position = body.position
	card.scale = Vector2(0.5, 0.5)

	card.value = card_vs[0]
	card.suit = card_vs[1]

	add_child(card)
	var x_move = randf_range(-1, 1)
	var y_move
	if x_move > 0:
		y_move = [1-x_move, -1+x_move].pick_random()
	else:
		y_move = [-1-x_move, 1+x_move].pick_random()
	card.direction = Vector2(x_move, y_move * 1.3)
	card.speed = 1000
	card.get_node("StopMotion").start()

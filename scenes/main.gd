extends Node2D

var card_scene = preload("res://scenes/card.tscn")
var suits = ["spade", "heart", "club", "diamond"]
var face = false
var back_sprite = "backman.svg"

# Called when the node enters the scene tree for the first time.
func _ready():
	var card = card_scene.instantiate()
	card.position = Vector2(572, 324)
	card.scale = Vector2(1, 1)
	card.get_node("Sprite").texture = load("res://graphics/cards/back/" + back_sprite)
	card.value = randi_range(1, 13)
	card.suit = suits.pick_random()
	add_child(card)
	card.clicked.connect(on_tile_clicked)

func on_tile_clicked(body):
	if not face:
		var file_name = str(body.value) + "_" + body.suit + ".svg"
		body.get_node("Sprite").texture = load("res://graphics/cards/front/" + file_name)
		face = true
	elif face:
		body.get_node("Sprite").texture = load("res://graphics/cards/back/" + back_sprite)
		face = false

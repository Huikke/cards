extends Area2D

# Card Attributes
@export var value = "troll"
@export var suit = "face"
@export var back_sprite = "firemon.svg"
var suits = ["spade", "heart", "club", "diamond"]
var face = false

# Physics
@export var direction = Vector2(0, 0)
@export var speed = 0

func _ready():
	$Sprite.texture = load("res://graphics/cards/back/" + back_sprite)

func _process(delta):
	position += direction * speed * delta

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		on_tile_clicked()

func on_tile_clicked():
	if not face:
		var file_name = str(value) + "_" + suit + ".svg"
		get_node("Sprite").texture = load("res://graphics/cards/front/" + file_name)
		face = true
	elif face:
		get_node("Sprite").texture = load("res://graphics/cards/back/" + back_sprite)
		face = false

# For stopping the dealt card
func _on_stop_motion_timeout():
	speed = 0

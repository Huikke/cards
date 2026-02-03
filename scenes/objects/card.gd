extends GameObject2D
class_name Card

# Card Attributes
@export var value = "troll"
@export var suit = "face"
@export var back_sprite = preload("res://assets/cards/back/" + "chicken.svg")
var suits = ["spade", "heart", "club", "diamond"]
var face = false

# Physics
@export var direction = Vector2(0, 0)
@export var speed = 0

func _ready():
	$Sprite.texture = back_sprite
	z_index = 1

func _process(delta):
	super(delta)
	position += direction * speed * delta


func mouse2():
	turn_card()

func turn_card():
	if not face:
		var file_name = str(value) + "_" + suit + ".svg"
		get_node("Sprite").texture = load("res://assets/cards/front/" + file_name)
		face = true
	elif face:
		get_node("Sprite").texture = back_sprite
		face = false

# For stopping the dealt card
func _on_stop_motion_timeout():
	speed = 0
	z_index = 0

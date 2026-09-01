extends Card
class_name PlayingCard

# Card Attributes
@export var value = 0
@export var suit = ""
var path_front = "res://assets/cards/front/perfectionism/"
var suits = ["spade", "heart", "club", "diamond"]


func _ready():
	super()

func _process(delta):
	super(delta)


func mouse2():
	flip_card()

func flip_card():
	if not face:
		if value == 0 and suit == "":
			get_node("Sprite").texture = load("res://assets/cards/front/troll_face.svg")
		else:
			var file_name = str(value) + "_" + suit + ".svg"
			get_node("Sprite").texture = load(path_front + file_name)
		face = true
	elif face:
		get_node("Sprite").texture = load(back_sprite)
		face = false

# For stopping the dealt card
func _on_stop_motion_timeout():
	speed = 0
	z_index = 0

@rpc("authority")
func destroy():
	if Global.mp_enabled and multiplayer.is_server():
		destroy.rpc()
	queue_free()

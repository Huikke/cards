extends Card
class_name FlipCard

# Physics
var content = ["A", "あ"]
var japanese = false

func _ready():
	z_index = 1
	$Label.text = content[0]

func _process(delta):
	super(delta)

func mouse2():
	flip_card()

func flip_card():
	if japanese:
		$Label.text = content[0]
		japanese = false
	elif !japanese:
		$Label.text =  content[1]
		japanese = true


# For stopping the dealt card
func _on_stop_motion_timeout():
	speed = 0
	z_index = 0

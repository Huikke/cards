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
var moving = false

func _ready():
	$Sprite.texture = load("res://graphics/cards/back/" + back_sprite)

func _process(delta):
	position += direction * speed * delta
	if moving:
		position = moving + get_viewport().get_mouse_position()


func _on_input_event(_viewport, event, _shape_idx):
	# Copied code in order to click the upmost card in the tree 
	if event is InputEventMouseButton and event.pressed:
		var ppqp2d = PhysicsPointQueryParameters2D.new()
		ppqp2d.position = event.position
		ppqp2d.collide_with_areas = true
		var objects_clicked = get_world_2d().direct_space_state.intersect_point(ppqp2d)

		var colliders = objects_clicked.map(
			func(dict):
				return dict.collider
		)

		colliders.sort_custom(
			func(c1, c2):
				return c1.get_index() < c2.get_index() 
		)
		#################

		if colliders[-1] == self:
			if event.button_index == 2:
				turn_card()
			if event.button_index == 1:
				get_parent().move_child(self, -1)
				moving = position - event.position
	if event is InputEventMouseButton and not event.pressed and event.button_index == 1:
		moving = false

func turn_card():
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

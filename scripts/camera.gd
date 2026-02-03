extends Camera2D


func _process(delta):
	position += Input.get_vector("left", "right", "up", "down") * delta * Global.ms

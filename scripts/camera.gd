extends Camera2D

# Sandbox only for now
func _process(delta):
	position += Input.get_vector("left", "right", "up", "down") * delta * Global.ms

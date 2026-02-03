extends CollisionObject2D
class_name GameObject2D

var moving

func _process(delta):
	# Object in the moving state, moved by either mouse or camera movement
	if moving:
		moving += Input.get_vector("left", "right", "up", "down") * delta * Global.ms
		position = moving + get_viewport().get_mouse_position()
		get_parent().move_child(self, -1)

func _on_input_event(_viewport, event, _shape_idx):
	# Copied code in order to click the upmost card in the tree
	# Zoom and moving card still doesn't work correctly, very useful indeed.
	if event is InputEventMouseButton and event.pressed:
		var ppqp2d = PhysicsPointQueryParameters2D.new()
		var zoom_factor = get_viewport().get_camera_2d().zoom
		var topleft = get_viewport().get_camera_2d().position - (get_viewport_rect().size / 2) / zoom_factor
		print(topleft)
		ppqp2d.position = topleft + event.position / zoom_factor
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
			if event.button_index == 1:
				get_parent().move_child(self, -1) # Move on top of tree
				moving = position - event.position
			elif event.button_index == 2:
				mouse2()
			elif event.button_index == 3:
				mouse3()
			elif event.button_index == 4:
				mouse4()
			elif event.button_index == 5:
				mouse5()
	if event is InputEventMouseButton and not event.pressed and event.button_index == 1:
		moving = false

func mouse2():
	pass

func mouse3():
	pass

func mouse4():
	pass

func mouse5():
	pass

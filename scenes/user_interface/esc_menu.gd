extends CanvasLayer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible == true:
			visible = false
			_on_back_button_pressed()
		else:
			visible = true

func _on_continue_pressed() -> void:
	visible = false

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/games/title_screen.tscn")


func _on_settings_pressed() -> void:
	$FirstMenu.visible = false
	$SettingsMenu.visible = true


func _on_back_button_pressed() -> void:
	$FirstMenu.visible = true
	$SettingsMenu.visible = false

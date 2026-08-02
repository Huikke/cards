extends CanvasLayer


func _on_play_button_pressed():
	$FirstMenu.visible = false
	$GameMenu.visible = true


func _on_back_button_pressed():
	$FirstMenu.visible = true
	$GameMenu.visible = false


func _on_game_button_1_pressed():
	get_tree().change_scene_to_file("res://scenes/games/best_of_three.tscn")


func _on_game_button_2_pressed():
	get_tree().change_scene_to_file("res://scenes/games/poker.tscn")


func _on_game_button_3_pressed():
	get_tree().change_scene_to_file("res://scenes/games/sandbox.tscn")


func _on_game_button_4_pressed():
	get_tree().change_scene_to_file("res://scenes/games/kuhn_poker.tscn")

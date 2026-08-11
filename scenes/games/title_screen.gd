extends CanvasLayer


func _on_play_button_pressed():
	$FirstMenu.visible = false
	$GameMenu.visible = true


func _on_back_button_pressed():
	$FirstMenu.visible = true
	$GameMenu.visible = false


func _on_game_1_button_pressed():
	get_tree().change_scene_to_file("res://scenes/games/best_of_three.tscn")


func _on_game_2_button_pressed():
	get_tree().change_scene_to_file("res://scenes/games/kuhn_poker.tscn")


func _on_game_3_button_pressed():
	get_tree().change_scene_to_file("res://scenes/games/poker.tscn")


func _on_game_4_button_pressed():
	get_tree().change_scene_to_file("res://scenes/games/sandbox.tscn")

var game_settings_first = true
var modes = Global.poker_mode_names
var players_mode = Global.player_poker_modes

func _on_game_3_setting_pressed():
	$GameMenu.visible = false
	$Game3SettingMenu.visible = true
	if game_settings_first:
		for p in range(4):
			$Game3SettingMenu.get_node("Player" + str(p) + "/Mode").text = modes[players_mode[p]]

func _on_setting_back_button_pressed():
	$Game3SettingMenu.visible = false
	$GameMenu.visible = true

func _on_left_pressed(p):
	players_mode[p] = (players_mode[p] - 1) % len(modes)
	$Game3SettingMenu.get_node("Player" + str(p) + "/Mode").text = modes[players_mode[p]]

func _on_right_pressed(p):
	players_mode[p] = (players_mode[p] + 1) % len(modes)
	$Game3SettingMenu.get_node("Player" + str(p) + "/Mode").text = modes[players_mode[p]]

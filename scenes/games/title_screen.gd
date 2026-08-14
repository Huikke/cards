extends CanvasLayer

var base_file_location = "res://scenes/games/"
var game_scenes = ["best_of_three.tscn", "kuhn_poker.tscn", "poker.tscn", "sandbox.tscn"]

# The switch for multiplayer
var mp_enabled = false

func _on_play_button_pressed():
	$FirstMenu.visible = false
	$GameMenu.visible = true


func _on_back_button_pressed():
	$FirstMenu.visible = true
	$GameMenu.visible = false

func _on_game_button_pressed(game_id: int) -> void:
	if mp_enabled == true:
		mp_change_scene.rpc(game_id)
	get_tree().change_scene_to_file(base_file_location + game_scenes[game_id])

@rpc("authority")
func mp_change_scene(game_id: int) -> void:
	get_tree().change_scene_to_file(base_file_location + game_scenes[game_id])

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


func _on_multiplayer_button_pressed() -> void:
	$FirstMenu.visible = false
	$NetworkHandler.visible = true

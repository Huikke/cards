extends CanvasLayer

var base_file_location = "res://scenes/games/"
var game_scenes = ["best_of_three.tscn", "kuhn_poker.tscn", "poker.tscn", "sandbox.tscn"]


func _on_play_button_pressed():
	$FirstMenu.visible = false
	$GameMenu.visible = true

func _on_multiplayer_button_pressed() -> void:
	$FirstMenu.visible = false
	$NetworkHandler.visible = true

func _on_settings_button_pressed() -> void:
	$FirstMenu.visible = false
	$SettingsMenu.visible = true


func _on_back_button_pressed():
	$FirstMenu.visible = true
	$GameMenu.visible = false
	$SettingsMenu.visible = false

func _on_game_button_pressed(game_id: int) -> void:
	if Global.mp_enabled == true:
		change_scene.rpc(game_id)
	change_scene(game_id)

@rpc("authority")
func change_scene(game_id: int) -> void:
	get_tree().change_scene_to_file(base_file_location + game_scenes[game_id])

var game_settings_first = true
var modes = Global.poker_mode_names
var mode_options = Global.poker_mode_options
var players_mode = Global.player_poker_modes

func _on_game_3_setting_pressed():
	$GameMenu.visible = false
	$PokerSettingMenu.visible = true
	if game_settings_first:
		for p in range(4):
			mode_update(p, false)
			var left_node = $PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/Left")
			var right_node = $PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/Right")
			var option_button = $PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/OptionButton")
			left_node.pressed.connect(_on_left_pressed.bind(p))
			right_node.pressed.connect(_on_right_pressed.bind(p))
			option_button.item_selected.connect(_on_option_button_item_selected.bind(p))
		game_settings_first = false


func _on_setting_back_button_pressed():
	$PokerSettingMenu.visible = false
	$GameMenu.visible = true

func _on_left_pressed(p):
	players_mode[p][0] = (players_mode[p][0] - 1) % len(modes)
	mode_update(p)


func _on_right_pressed(p):
	players_mode[p][0] = (players_mode[p][0] + 1) % len(modes)
	mode_update(p)

func _on_option_button_item_selected(i, p):
	players_mode[p][1] = i

func mode_update(p, clear_option = true):
	$PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/PlayerNro").text = "Player " + str(p+1)
	$PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/Mode").text = modes[players_mode[p][0]]
	$PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/OptionButton").clear()
	if clear_option:
		players_mode[p][1] = 0
	for option in mode_options[players_mode[p][0]]:
		$PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/OptionButton").add_item(option)
	$PokerSettingMenu/PlayerSettingsBox.get_node("PlayerSettings" + str(p) + "/OptionButton").selected = players_mode[p][1]

var player_setting_scene = preload("res://scenes/user_interface/player_settings.tscn")
func _on_add_pressed() -> void:
	var new_player = player_setting_scene.instantiate()
	var p = len(Global.player_poker_modes)
	new_player.name = "PlayerSettings" + str(p)
	Global.player_poker_modes.append([0, 0])
	Global.player_poker_names.append("Player " + str(p+1))
	new_player.get_node("PlayerNro").text = "Player " + str(p+1)
	new_player.get_node("Mode").text = modes[0]
	for option in mode_options[0]:
		new_player.get_node("OptionButton").add_item(option)
	new_player.get_node("Left").pressed.connect(_on_left_pressed.bind(p))
	new_player.get_node("Right").pressed.connect(_on_right_pressed.bind(p))
	new_player.get_node("OptionButton").item_selected.connect(_on_option_button_item_selected.bind(p))
	$PokerSettingMenu/PlayerSettingsBox.add_child(new_player)
	
	print(Global.player_poker_modes)


func _on_remove_pressed() -> void:
	var last_child = $PokerSettingMenu/PlayerSettingsBox.get_child(-1)
	$PokerSettingMenu/PlayerSettingsBox.remove_child(last_child)
	Global.player_poker_modes.remove_at(-1)
	Global.player_poker_names.remove_at(-1)
	print(Global.player_poker_modes)


func _on_quit_button_pressed() -> void:
	get_tree().quit()

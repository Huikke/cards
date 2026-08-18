extends Node

var ms = 5 * 60
var mp_enabled = false

var back_art: String

var player_poker_modes = [[0, 0], [1, 0], [1, 1], [1, 0]]
var player_poker_names = ["Player 1", "Player 2", "Player 3", "Player 4"]
var poker_mode_names = ["Player", "Random", "LLM"]
var poker_mode_options = [["Player 1", "Player 2", "Player 3", "Player 4"], ["Random 1", "Random 2"], ["Gemini", "Llama"]]
var multiplayer_players = []

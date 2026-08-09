extends Node2D

var poker_gd = preload("res://scenes/games/poker.gd").new()

func _ready():
	print(poker_gd.pot_sum())
	poker_gd.pots = [213, 321, 300, 333]
	print(poker_gd.pot_sum())

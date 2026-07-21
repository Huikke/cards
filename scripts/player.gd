extends Node
class_name Player

var money = 10000
var round_bet = 0

func print_money():
	print(money)

func bet(amount):
	var difference = amount - round_bet
	money -= difference
	round_bet += difference
	return difference

func win(amount):
	money += amount

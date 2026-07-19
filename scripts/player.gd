extends Node
class_name Player

var money = 10000
var bet_current = 0

func print_money():
	print(money)

func bet(amount):
	var difference = amount - bet_current
	money -= difference
	bet_current += difference
	return difference

func win(amount):
	money += amount

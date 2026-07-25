extends Node
class_name Player

var balance = 10000
var round_bet = 0

func print_balance():
	print(balance)

func bet(amount):
	var all_in = false
	var difference = amount - round_bet

	if balance - difference <= 0:
		difference = balance
		all_in = true

	balance -= difference
	round_bet += difference

	return [difference, all_in]

func win(amount):
	balance += amount

extends Node
class_name Player

var balance = 10000
var round_bet = 0

func get_balance():
	return balance

func set_balance(amount: int):
	balance = amount

func get_round_bet():
	return round_bet

func bet(amount):
	var all_in = false
	var difference = amount - round_bet

	if balance - difference <= 0:
		difference = balance
		all_in = true

	balance -= difference
	round_bet += difference

	return [difference, all_in]

# For Kuhn Poker
func bet_simple(amount):
	balance -= amount
	return amount

func win(amount):
	balance += amount

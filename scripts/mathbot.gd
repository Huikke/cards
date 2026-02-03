func bigger(n1: Node, n2: Node):
	var bonus = 0
	if n1.value == 1: # Ace is best!
		bonus += 13
	if n2.value == 1:
		bonus -= 13
	if n1.value + bonus > n2.value:
		return n1
	elif n1.value + bonus < n2.value:
		return n2
	else:
		return null

func bigger(n1: Node, n2: Node):
	if n1.value > n2.value:
		return n1
	elif n2.value < n1.value:
		return n2
	else:
		return n2

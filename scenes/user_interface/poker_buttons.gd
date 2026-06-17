extends Button

signal called

func _pressed():
	called.emit()

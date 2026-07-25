extends CanvasLayer

func _on_fold():
	$".".visible = false
	GlobalSignal.fold.emit(0)

func _on_call():
	$".".visible = false
	GlobalSignal.call.emit(0)

func _on_raise():
	$".".visible = false
	GlobalSignal.raise.emit(0)


func _on_raise_slider_value_changed(value):
	$ButtonsContainer/Raise.text = "\nRaise\n" + str(int(value)) + " €"
	GlobalSignal.raise_slider_value_changed.emit(value)

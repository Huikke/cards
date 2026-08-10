extends CanvasLayer

var raise_text = "Placeholder"

func _on_fold():
	$".".visible = false
	GlobalSignal.fold.emit(0)

func _on_call():
	$".".visible = false
	GlobalSignal.call.emit(0)

func _on_raise():
	$".".visible = false
	var amount = $ButtonsContainer/RaiseSlider.value
	GlobalSignal.raise.emit(0, amount)

func update_raise_text():
	$ButtonsContainer/Raise.text = "\n" + raise_text + "\n" + str(int($ButtonsContainer/RaiseSlider.value)) + " €"

func _on_raise_slider_value_changed(value):
	$ButtonsContainer/Raise.text = "\n" + raise_text + "\n" + str(int(value)) + " €"

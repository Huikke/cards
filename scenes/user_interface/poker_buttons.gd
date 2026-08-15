extends CanvasLayer

var raise_text = "Placeholder"
var player: int

func set_player(p_num):
	player = p_num

func _on_fold():
	$".".visible = false
	GlobalSignal.fold.emit(player)

func _on_call():
	$".".visible = false
	GlobalSignal.call.emit(player)

func _on_raise():
	$".".visible = false
	var amount = $ButtonsContainer/RaiseSlider.value
	GlobalSignal.raise.emit(player, amount)

func update_raise_text():
	if $ButtonsContainer/RaiseSlider.value == $ButtonsContainer/RaiseSlider.max_value:
		$ButtonsContainer/Raise.text = "All In"
	else:
		$ButtonsContainer/Raise.text = "\n" + raise_text + "\n" + str(int($ButtonsContainer/RaiseSlider.value)) + " €"

func _on_raise_slider_value_changed(value):
	if $ButtonsContainer/RaiseSlider.value == $ButtonsContainer/RaiseSlider.max_value:
		$ButtonsContainer/Raise.text = "All In"
	else:
		$ButtonsContainer/Raise.text = "\n" + raise_text + "\n" + str(int(value)) + " €"

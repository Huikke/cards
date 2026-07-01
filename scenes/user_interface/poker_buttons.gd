extends CanvasLayer

func _on_fold():
	Global.folded.append(0) # Change needed in mp
	$".".visible = false
	GlobalSignal.fold.emit(0)

func _on_call():
	$".".visible = false
	GlobalSignal.call.emit(0)

func _on_raise():
	# $".".visible = false
	GlobalSignal.raise.emit(0)

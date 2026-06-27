extends CanvasLayer

func _on_fold():
	GlobalSignal.fold.emit(0)

func _on_call():
	GlobalSignal.call.emit(0)

func _on_raise():
	GlobalSignal.raise.emit(0)

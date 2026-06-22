extends CanvasLayer


func _on_fold():
	GlobalSignal.fold.emit()

func _on_call():
	GlobalSignal.call.emit()

func _on_raise():
	GlobalSignal.raise.emit()

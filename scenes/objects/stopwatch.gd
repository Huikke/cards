extends GameObject2D

var on = false
var time_elapsed: float = 0


func _process(delta):
	super(delta)
	if on:
		time_elapsed += delta
		var total_seconds: int = int(time_elapsed)
		var minutes: int = total_seconds / 60
		var seconds: int = total_seconds % 60
		$Label.text = "%02d:%02d" % [minutes, seconds]


func mouse2():
	toggle_timer()

func mouse3():
	reset_timer()

func toggle_timer():
	on = !on

func reset_timer():
	on = false
	time_elapsed = 0
	$Label.text = "00:00"

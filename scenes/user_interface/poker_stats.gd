extends PanelContainer

func set_player_name(text):
	$MC/VBC/TopPC/MC/NameLabel.text = text

func set_heads_up(text):
	$MC/VBC/MidPC/MC/HeadsUpLabel.text = text

func set_balance(text):
	$MC/VBC/BottomHBC/PC/MC/CurrencyLabel.text = text + " €"

func set_indicator_color(color):
	$MC/VBC/BottomHBC/Indicator.color = color

func balance_change_animation(text: String, direction: String = "down"):
	var the_node = $MC/VBC/BottomHBC/PC/MC/BalanceChangeLabel
	the_node.text = text + " €"
	the_node.offset_transform_position = Vector2(0, 0)

	var y_dir = 40
	if direction == "up":
		y_dir *= -1

	var tween = create_tween()
	tween.tween_property(the_node, "modulate:a", 1, 0.2)
	tween.parallel().tween_property(the_node, "offset_transform_position", Vector2(0, y_dir), 0.3)
	# Causes visual bug if players are too fast
	tween.tween_property(the_node, "modulate:a", 0, 0.2).set_delay(3)

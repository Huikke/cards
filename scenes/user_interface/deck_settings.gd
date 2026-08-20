extends HBoxContainer

var path = "res://assets/cards/back/"
var back_art_list: Array[String] = []
var back_id: int = 0

func _ready() -> void:
	var dir_list = ResourceLoader.list_directory(path)
	for file_name in dir_list:
		if !file_name.contains(".import"):
			back_art_list.append(file_name)
	
	back_id = back_art_list.find("lokki.svg")
	back_art_selection(back_id)

func back_art_selection(id: int) -> void:
	Global.back_art = path + back_art_list[id]
	$DeckPanel/VBC/DeckTexture.texture = load(path + back_art_list[id])
	$DeckPanel/VBC/Label.text = back_art_list[id].left(-4)

func _on_left_pressed() -> void:
	back_id = (back_id - 1) % len(back_art_list)
	back_art_selection(back_id)

func _on_right_pressed() -> void:
	back_id = (back_id + 1) % len(back_art_list)
	back_art_selection(back_id)

extends Node
class_name PokerAiLLM

var http_request = HTTPRequest.new()
var url: String
var model_name: String
var payload: Dictionary


func _init(m_name):
	model_name = m_name
	if model_name.contains("gemini"):
		load_env_file()
		var api_key = OS.get_environment("GEMINI_API_KEY")
		url = "https://generativelanguage.googleapis.com/v1beta/models/" + str(model_name) + ":generateContent?key=" + api_key

		payload = {
			"contents": [
				{
					"parts": [
						{"text": "placeholder"}
					]
				}
			],
			"systemInstruction": {
				"parts": [
				{ "text": "You are poker player. Respond with only action (fold, call, check, bet, raise).
					If betting or raising, also mention by how much separated by a space." }
				]
			}
		}
	elif model_name.contains("llama"):
		url = "http://localhost:12434/engines/llama.cpp/v1/chat/completions"

		payload = {
			"model": model_name,
			"messages": [
				{
					"role": "system",
					"content": "You are poker player. Respond with only action (fold, call, check, bet, raise).
					If betting or raising, also mention by how much separated by a space."
				},
				{
					"role": "user",
					"content": "placeholder"
				}
			]
		}

func _ready():
	add_child(http_request)

func ai_move(player, hand, roles, balances, pot, game_log):
	var input = "You: Player " + str(player+1) + "\n"
	input += "Your cards: " + hand + "\n\n"
	input += ", ".join(roles)
	var p = 1
	input += "\nBalance:\n"
	for balance in balances:
		if p == player+1:
			input += "Player " + str(p) + " (You): " +  str(balance) + "€ "
		else:
			input += "Player " + str(p) + ": " +  str(balance) + "€ "
		p += 1
	input += "\n" + "Pot: " + str(pot) + " €"
	input += "\n\n" + "Poker Hand History:"
	for info in game_log:
		input += "\n" + info

	if model_name.contains("gemini"):
		payload["contents"][0]["parts"][0]["text"] = input
	elif model_name.contains("llama"):
		payload["messages"][1]["content"] = input
	send_request(player)
	print(payload)

func send_request(player):
	var json = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	http_request.request_completed.connect(_http_request_completed.bind(player))
	http_request.request(url, headers, HTTPClient.METHOD_POST, json)

@warning_ignore("unused_parameter")
func _http_request_completed(result, response_code, headers, body, player):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	var output_move: String
	if model_name.contains("gemini"):
		output_move = response["candidates"][0]["content"]["parts"][0]["text"]
	elif model_name.contains("llama"):
		output_move = response["choices"][0]["message"]["content"]
	print(output_move)
	output_move = output_move.to_lower()

	if output_move == "fold":
		GlobalSignal.fold.emit(player)
	elif output_move.begins_with("call") or output_move == "check":
		GlobalSignal.call.emit(player)
	elif output_move.begins_with("raise") or output_move.begins_with("bet"):
		GlobalSignal.raise.emit(player, int(output_move.split(" ")[1]))
	else:
		push_error("LLM output didn't meet requirements")

func load_env_file(path: String = "res://.env") -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		var parts = line.split("=")
		if parts.size() == 2:
			OS.set_environment(parts[0], parts[1])
		else:
			push_error("env issues")

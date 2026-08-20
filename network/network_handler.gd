extends Node

var PORT = 6060
var DEFAULT_SERVER_IP = "localhost"
var peer := WebSocketMultiplayerPeer.new()
@onready var chat_window = $ChatContainer/ChatWindow
@onready var type_window = $ChatContainer/HBC/TypeWindow
@onready var send_button = $ChatContainer/HBC/Send

func _ready() -> void:
	# Connect Godot's built-in multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# --- SERVER / HOST METHOD ---
func host_game() -> void:
	peer = WebSocketMultiplayerPeer.new()
	
	# create_server(port, bind_address, TLSOptions)
	var error = peer.create_server(PORT)
	if error != OK:
		print("Failed to start WebSocket server: ", error)
		return
		
	# Assigning this activates Godot's multiplayer RPCs and synchronizers
	multiplayer.multiplayer_peer = peer
	print("WebSocket Server listening on port: ", PORT)
	chat_print("Server started on port: " + str(PORT))


# --- CLIENT METHOD ---
func join_game(ip: String = DEFAULT_SERVER_IP) -> void:
	peer = WebSocketMultiplayerPeer.new()
	
	# WebSockets use URL format: ws:// for standard, wss:// for SSL/TLS encrypted
	var url = "ws://" + ip + ":" + str(PORT)
	
	var error = peer.create_client(url)
	if error != OK:
		print("Failed to connect to WebSocket server: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("Connecting to WebSocket server at: ", url)
	chat_print("Connecting to " + url)


# --- RPC FUNCTION FOR TESTING ---

@rpc("any_peer", "call_local")
func send_chat_message(message: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	var sender_name = Global.player_names[Global.multiplayer_players.find(sender_id)]
	chat_print(sender_name + " says: " + message)

@rpc("authority", "call_local")
func broadcast_chat_message(message: String) -> void:
	chat_print(message)

func chat_print(message: String) -> void:
	if !chat_window.text == "":
		chat_window.text += "\n"
	chat_window.text += message


# --- NETWORK SIGNAL CALLBACKS ---

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	Global.multiplayer_players.append(id)
	update_players.rpc(Global.multiplayer_players)
	var no = Global.multiplayer_players.find(id)
	broadcast_chat_message(str(Global.player_names[no]) + " (" + str(id) + ") joined!")
	# Trigger an RPC call to test communication
	if multiplayer.is_server():
		$MultiplayerMenu/Play.disabled = false

@rpc("call_local")
func update_players(multiplayer_players):
	Global.multiplayer_players = multiplayer_players

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)

func _on_connected_to_server() -> void:
	print("Successfully connected to the WebSocket server!")
	chat_print("Connected to server!")

func _on_connection_failed() -> void:
	print("Failed to connect to server.")

func _on_server_disconnected() -> void:
	print("Server closed or connection lost.")


# --- Buttons ---

func _on_host_pressed() -> void:
	host_game()
	$MultiplayerMenu/Back.disabled = true
	Global.mp_enabled = true
	Global.multiplayer_players.append(1)


func _on_join_pressed() -> void:
	join_game()
	$MultiplayerMenu/Back.disabled = true
	Global.mp_enabled = true


func _on_play_pressed() -> void:
	send_chat_message.rpc("Ready!")
	$MultiplayerMenu.visible = false
	$"../GameMenu".visible = true
	for game in $"../GameMenu".get_children():
		if game.name != "Game3HBC":
			game.disabled = true
	print(Global.multiplayer_players)


func _on_send_pressed() -> void:
	if type_window.text.contains("@"):
		var new_name = str(type_window.text).trim_prefix("@")
		name_change.rpc(new_name)
	else:
		send_chat_message.rpc(type_window.text)
	type_window.text = ""

func _on_type_window_text_submitted(_new_text: String) -> void:
	_on_send_pressed()

func _on_back_pressed() -> void:
	$".".visible = false
	$"../FirstMenu".visible = true

# --- @ ---
@rpc("any_peer", "call_local")
func name_change(new_name: String):
	var index = Global.multiplayer_players.find(multiplayer.get_remote_sender_id())
	if multiplayer.is_server():
		broadcast_chat_message.rpc(Global.player_names[index] + " changed name into " + new_name)
	Global.player_names[index] = new_name

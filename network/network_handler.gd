extends Node

var DEFAULT_PORT = 6060
var DEFAULT_SERVER_IP = "localhost"
var peer := WebSocketMultiplayerPeer.new()
@onready var _chat_window = $ChatContainer/ChatWindow
@onready var _type_window = $ChatContainer/HBC/TypeWindow
@onready var _send_button = $ChatContainer/HBC/Send
@onready var _ip_field = $JoinMenu/IpField
@onready var _port_field = $JoinMenu/PortField

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
	var error = peer.create_server(DEFAULT_PORT)
	if error != OK:
		print("Failed to start WebSocket server: ", error)
		return
		
	# Assigning this activates Godot's multiplayer RPCs and synchronizers
	multiplayer.multiplayer_peer = peer
	print("WebSocket Server listening on port: ", DEFAULT_PORT)
	chat_print("Server started on port: " + str(DEFAULT_PORT))


# --- CLIENT METHOD ---
func join_game() -> void:
	peer = WebSocketMultiplayerPeer.new()
	
	# WebSockets use URL format: ws:// for standard, wss:// for SSL/TLS encrypted
	var ip = DEFAULT_SERVER_IP
	var port = str(DEFAULT_PORT)
	if _ip_field.text != "":
		ip = _ip_field.text
	if _port_field.text != "":
		port = _port_field.text

	var url = "ws://" + ip + ":" + port

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
	if !_chat_window.text == "":
		_chat_window.text += "\n"
	_chat_window.text += message


# --- NETWORK SIGNAL CALLBACKS ---

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	Global.multiplayer_players.append(id)
	# Trigger an RPC call to test communication
	if multiplayer.is_server():
		update_players.rpc(Global.multiplayer_players)
		var index = Global.multiplayer_players.find(id)
		broadcast_chat_message.rpc(str(Global.player_names[index]) + " (" + str(id) + ") joined!")
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
	if _type_window.text.contains("@"):
		var new_name = str(_type_window.text).trim_prefix("@")
		name_change.rpc(new_name)
	else:
		send_chat_message.rpc(_type_window.text)
	_type_window.text = ""

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

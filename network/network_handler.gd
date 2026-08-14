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


# --- RPC FUNCTION FOR TESTING ---
@rpc("any_peer", "call_local")
func send_chat_message(message: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	print("Peer %d says: %s" % [sender_id, message])
	chat_window.text += "Peer %d says: %s" % [sender_id, message] + "\n"


# --- NETWORK SIGNAL CALLBACKS ---

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	# Trigger an RPC call to test communication
	if multiplayer.is_server():
		send_chat_message.rpc("Welcome to the server!")

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)

func _on_connected_to_server() -> void:
	print("Successfully connected to the WebSocket server!")
	send_chat_message.rpc("Hello from new client!")

func _on_connection_failed() -> void:
	print("Failed to connect to server.")

func _on_server_disconnected() -> void:
	print("Server closed or connection lost.")

func _on_host_pressed() -> void:
	host_game()


func _on_join_pressed() -> void:
	join_game()


func _on_start_pressed() -> void:
	send_chat_message.rpc("Ready!")


func _on_send_pressed() -> void:
	send_chat_message.rpc(type_window.text)
	type_window.text = ""


func _on_type_window_text_submitted(_new_text: String) -> void:
	_on_send_pressed()

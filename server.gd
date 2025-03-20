extends Node


const DEFAULT_PORT = 12345
const MAX_CLIENTS = 32
const LOBBY_ID_LENGHT = 5
const LOBBY_ID_SYMBOLS = "abcdefghijklmnopqrstuvwxyz1234567890"


# SHOULD BE THE SAME AS IN CLIENT!!!!
enum MessageTypes{
	ID,
	JOIN,
	USER_CONNECTED,
	USER_DISCONNECTED,
	LOBBY,
	REMOVE_LOBBY,
	CANDIDATE,
	OFFER,
	ANSWER,
	CHECK_IN,
	LEAVE_LOBBY
}


var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}

func generate_lobby_id():
	var result = ""
	for i in range(LOBBY_ID_LENGHT):
		result += LOBBY_ID_SYMBOLS[randi() % LOBBY_ID_SYMBOLS.length()]
	return result


func _ready():
	if "--server" in OS.get_cmdline_args():
		print("Hosting on " + str(DEFAULT_PORT))
		create_server(DEFAULT_PORT)
		
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)


func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)
			print(data)
			if data.message_type == MessageTypes.LOBBY:
				print("\nRecieved request to join a lobby\n")
				join_lobby(data)
			elif data.message_type == MessageTypes.OFFER or data.message_type == MessageTypes.ANSWER or data.message_type == MessageTypes.CANDIDATE:
				print("\nSource is " + str(data.org_peer) + "\n") #+ " message: " + data.data)
				send_to_user(data.id, data)
			elif data.message_type == MessageTypes.LEAVE_LOBBY:
				print("player " + str(data.id) + " wants to leave lobby: " + str(data.lobby_id))
			elif data.message_type == MessageTypes.REMOVE_LOBBY:
				print("\nRecieved request to remove lobby: " + data.lobby_id + "\n")
				if lobbies.has(data.lobby_id):
					lobbies.erase(data.lobby_id)

	

func join_lobby(user_data):
	print("\nCreating lobby\n")
	
	var result = ""
	if user_data.lobby_id == "":
		user_data.lobby_id = generate_lobby_id()
		lobbies[user_data.lobby_id] = Lobby.new(user_data.id)
	
	var player = lobbies[user_data.lobby_id].add_player(user_data.id, user_data.name)
	
	
	var lobby_info = {
			"message_type" : MessageTypes.LOBBY,
			"players" : lobbies[user_data.lobby_id].players,
			"host" : lobbies[user_data.lobby_id].host_id,
			"lobby_id" : user_data.lobby_id
		}
		
	for p in lobbies[user_data.lobby_id].players:
		send_to_user(p, lobby_info)
		var message1 = {
			"message_type" : MessageTypes.USER_CONNECTED,
			"id" : user_data.id
		}
		send_to_user(p, message1)
		
		var message2 = {
			"message_type" : MessageTypes.USER_CONNECTED,
			"id" : p
		}
		send_to_user(user_data.id, message2)
	
	var message = {
		"message_type" : MessageTypes.USER_CONNECTED,
		"id" : user_data.id,
		"player" : lobbies[user_data.lobby_id].players[user_data.id]
	}
	send_to_user(user_data.id, message)
	
	print("\nCreated Lobby" + user_data.lobby_id + "\n")
	
func send_to_user(user_id: int, data):
	var data_bytes = JSON.stringify(data).to_utf8_buffer()
	peer.get_peer(user_id).put_packet(data_bytes)

func create_server(port):
	peer.create_server(port)
	print("Started!!")


func _on_peer_connected(id):
	print("\nPeer connected: " + str(id) + "\n")
	
	users[id] = {
		"message_type" : MessageTypes.ID,
		"id" : id
	}
	var data_bytes = JSON.stringify(users[id]).to_utf8_buffer()
	peer.get_peer(id).put_packet(data_bytes)
	
func _on_peer_disconnected(id):
	pass


func _on_timer_timeout():
	for l in lobbies:
		if lobbies[l].is_three_hours_passed():
			lobbies.erase(l)
			print("\nErased outdated lobby\n")

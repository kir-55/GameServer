GDPC                @                                                                      
   T   res://.godot/exported/133200997/export-c89a2950482f3a432bab03a0591e8d28-server.scn  �      	      ��;D���qO@�~        res://.godot/extension_list.cfg                
bs�]]3�����*�B    ,   res://.godot/global_script_class_cache.cfg  P      �       {�M�})[�Ɋ��>���       res://.godot/uid_cache.bin  �      ;       ��䞹v�<��k       res://lobby.gd  p      E      �����ꪶȹ���m�       res://project.binary@      �       &���m��	�X�>��       res://server.gd �            �����YEF&�ow��       res://server.tscn.remap �      c       6�]��U�s;�i*�v�       res://webrtc/LICENSE.json           4      �i}{~Ш�<+�� %�        res://webrtc/webrtc.gdextension @      +      �s�
�
���(2���            MIT License 

Copyright (c) 2013-2022 Niels Lohmann

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
            [configuration]

entry_symbol = "webrtc_extension_init"
compatibility_minimum = 4.1

[libraries]

linux.debug.x86_64 = "lib/libwebrtc_native.linux.template_debug.x86_64.so"
linux.debug.x86_32 = "lib/libwebrtc_native.linux.template_debug.x86_32.so"
linux.debug.arm64 = "lib/libwebrtc_native.linux.template_debug.arm64.so"
linux.debug.arm32 = "lib/libwebrtc_native.linux.template_debug.arm32.so"
macos.debug = "lib/libwebrtc_native.macos.template_debug.universal.framework"
windows.debug.x86_64 = "lib/libwebrtc_native.windows.template_debug.x86_64.dll"
windows.debug.x86_32 = "lib/libwebrtc_native.windows.template_debug.x86_32.dll"
android.debug.arm64 = "lib/libwebrtc_native.android.template_debug.arm64.so"
android.debug.x86_64 = "lib/libwebrtc_native.android.template_debug.x86_64.so"
ios.debug.arm64 = "lib/libwebrtc_native.ios.template_debug.arm64.dylib"
ios.debug.x86_64 = "lib/libwebrtc_native.ios.template_debug.x86_64.simulator.dylib"

linux.release.x86_64 = "lib/libwebrtc_native.linux.template_release.x86_64.so"
linux.release.x86_32 = "lib/libwebrtc_native.linux.template_release.x86_32.so"
linux.release.arm64 = "lib/libwebrtc_native.linux.template_release.arm64.so"
linux.release.arm32 = "lib/libwebrtc_native.linux.template_release.arm32.so"
macos.release = "lib/libwebrtc_native.macos.template_release.universal.framework"
windows.release.x86_64 = "lib/libwebrtc_native.windows.template_release.x86_64.dll"
windows.release.x86_32 = "lib/libwebrtc_native.windows.template_release.x86_32.dll"
android.release.arm64 = "lib/libwebrtc_native.android.template_release.arm64.so"
android.release.x86_64 = "lib/libwebrtc_native.android.template_release.x86_64.so"
ios.release.arm64 = "lib/libwebrtc_native.ios.template_release.arm64.dylib"
ios.release.x86_64 = "lib/libwebrtc_native.ios.template_release.x86_64.simulator.dylib"
     class_name Lobby
extends RefCounted


const DELETE_LOBBY_AFTER = 3 #measured in hours

var host_id: int
var players: Dictionary = {}
var  created_at: int


func _init(id):
	host_id = id
	created_at = Time.get_unix_time_from_system()


func is_three_hours_passed():
	var current_time: int = Time.get_unix_time_from_system()
	var time_difference = current_time - created_at
	return time_difference > (DELETE_LOBBY_AFTER * 60 * 60)  # 3 hours in seconds


func add_player(id, name):
	players[id] = {
		"id" : id,
		"name" : name,
		"index" : players.size() + 1
	}
	return players[id]
           RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       Script    res://server.gd ��������      local://PackedScene_thrto          PackedScene          	         names "         Server    script    Node    Timer 
   wait_time 
   autostart    _on_timer_timeout    timeout    	   variants                      �C            node_count             nodes        ��������       ����                            ����                         conn_count             conns                                      node_paths              editable_instances              version             RSRC       extends Node


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
	CHECK_IN
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
         [remap]

path="res://.godot/exported/133200997/export-c89a2950482f3a432bab03a0591e8d28-server.scn"
             list=Array[Dictionary]([{
"base": &"RefCounted",
"class": &"Lobby",
"icon": "",
"language": &"GDScript",
"path": "res://lobby.gd"
}])
             z����O   res://icon.svgVY��CCR   res://server.tscn     res://webrtc/webrtc.gdextension
ECFG      application/config/name      
   GameServer     application/run/main_scene         res://server.tscn      application/config/features$   "         4.2    Forward Plus    
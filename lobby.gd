class_name Lobby
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

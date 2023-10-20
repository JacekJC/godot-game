extends Node

class World:
	var name : String
	
	func save_world():
		var world_bytes = PackedByteArray[2048];
		return world_bytes;
	
	func load_world():
		pass

class Location:
	var name : String
	var size : int;
	var neighbours : Array[Location];

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

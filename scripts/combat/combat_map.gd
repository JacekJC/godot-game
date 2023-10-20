extends Node


class map_tile:
	var x : int
	var y : int
	var ground : bool = false;
	var neighbours : Array[map_tile] = [];
	var entity = null

class combat_map:
	var size_x : int;
	var size_y : int;
	var tile_array = [];
	
	func generate_tiles():
		self.tile_array = [];
		for x in size_x:
			self.tile_array.push_back([]);
			for y in size_y:
				self.tile_array[x].push_back(map_tile.new());
				self.tile_array[x][y].ground = true;
				self.tile_array[x][y].x = x;
				self.tile_array[x][y].y = y;
		pass

	func update_tile_neighbours():
		var n = [Vector2(1,0), Vector2(0,1), Vector2(-1,0), Vector2(0,-1)];
		for x in size_x:
			for y in size_y:
				for dir in n:
					var res = get_node(dir.x+x,dir.y+y)
					if(res!=null):
						tile_array[x][y].neighbours.push_back(res);
		return self;

	func get_node(px:int,py:int):
		if(px>=0&&py>=0&&px<self.size_x&&py<self.size_y):
			return self.tile_array[px][py];
		return null;

	func flood_fill(points, depth):
		var open_list = []+points
		var closed_list = []+points
		var i = 0;
		while(i < depth):
			var new_list = []
			for n in open_list:
				for on in n.neighbours:
					if(!closed_list.has(on)):
						closed_list.push_back(on)
						new_list.push_back(on)
			open_list = new_list
			i+=1
		return closed_list

	func get_path(posx:int,posy:int,tx:int,ty:int):	
		var sn = get_node(posx,posy);
		var tn = get_node(tx,ty);
		if(sn==null||tn==null):
			print(" path point out of bounds! ");
			return null;
		var openlist = [sn]
		var parents = [0]
		var closedlist = [sn]
		var index = 0
		while openlist.size() > 0 && !closedlist.has(tn):
			print(openlist.size())
			var newlist = []
			for n in openlist:
				for on in n.neighbours:
					if(!closedlist.has(on)):
						closedlist.push_back(on)
						newlist.push_back(on)
						parents.push_back(index)
				index += 1
			openlist = newlist	
		for n in openlist:
			closedlist.push_back(n)
		if(!closedlist.has(tn)):
			print(" no path found! ")
			return null
		var path = []
		var cn = closedlist.find(tn)
		while(cn!=0):
			print(" current parent = ", cn)
			path.push_back(closedlist[cn])
			cn = parents[cn]
		path.push_back(cn);
		print(" path found! length: ", path.size())
		return path
	
func create_new_map(sx : int, sy : int):
	var map = combat_map.new();
	map.size_x = sx;
	map.size_y = sy;
	map.generate_tiles();
	return map;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func print_test():
	print("combat_map_manager_added!");

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

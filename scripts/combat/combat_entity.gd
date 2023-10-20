extends Node


class c_entity:
	var name : String
	var health : int
	var speed : int
	var initiative : int
	var team : int
	var variables = {}
	var attacks = []

	var x : int
	var y : int
	
	var combat;	
	var display_object;

	func get_global_variable(name):
		if(name=='me'):
			return get_node()
		if(name=='enemies'):
			return "will get enemies!"
		return null

	func get_node():
		return [combat.map.get_node(x,y)]
	
	func set_var(name, value):
		variables[name] = value
		return self
	
	func get_var(name):
		return variables[name]
		
	func exec_attack(index):
		attacks[index].exec_debug(self, self.combat);
		return self
	
	func add_attacks(attack_arr):
		for a in attack_arr:
			attacks.push_back(a);
		return self
		
	func create_display_object():
		var new_ob = Node3D.new();
		var spr = Sprite3D.new();
		new_ob.add_child(spr);
		spr.texture = load("res://icon.svg");
		if combat != null:
			combat.node.add_child(new_ob);
		display_object = new_ob;
		display_object.position = Vector3(x, 0, y);
		return self

	func move_to(goal_node):
		set_position(goal_node.x, goal_node.y)
		

	func set_position(px:int,py:int):
		combat.map.get_node(self.x,self.y).entity = null
		self.x = px
		self.y = py
		if(combat!=null):
			combat.map.get_node(px,py).entity = self
		print("position set!")
		if(display_object!=null):
			display_object.position = Vector3(self.x,0,self.y)
		return self
	
func create_entity():
	var c_ent = c_entity.new();
	return c_ent;

	
func create_test_entity(team : int, x:int, y:int):
	var c_ent = c_entity.new();
	c_ent.health = 2;
	c_ent.speed = 2;
	c_ent.initiative = 3;
	c_ent.name = "TEST_ENTITY";
	c_ent.team = team;
	c_ent.x = x
	c_ent.y = y
	return c_ent;

func print_test():
	print("combat_entity_manager_added!");
	
func print_entity(entity : c_entity):
	print("~|| ", entity.name, " ||~");
	print("HEALTH : ", entity.health, " | SPEED : ", entity.speed, " | INITIATIVE : ", entity.initiative, " | TEAM : ", entity.team)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

extends Node

# combat entity manager
var cem : Node
# combat map manager
var cmp : Node
# attack parser
var atp : Node

class combat:
	var round : int
	var turn_index : int
	var map
	var entity_list = []

	var node
	
	func next_combat_round():
		self.turn_index += 1
		return self
	
	func end_combat():
		return self
		
	func add_entity(entity):
		entity_list.push_back(entity);
		entity.combat = self
		if entity.display_object != null:
			node.add_child(entity.display_object)
		map.get_node(entity.x,entity.y).entity = entity;
		return self

	func tiles(entity, query):
		var ret = []
		if(query=="enemies"):
			for e in entity_list:
				if(e.team != entity.team):
					ret.push_back(e.get_node())
		elif(query=="friends"):
			for e in entity_list:
				if(e.team == entity.team && e!= entity):
					ret.push_back(e.get_node())
		elif(query=="all"):
			for e in entity_list:
				ret.push_back(e.get_node())
		return ret
	
		
	func generate_map(cmp:Node,size_x:int,size_y:int):
		self.map = cmp.create_new_map(size_x, size_y);
		return self
		
	func place_entities():
		return self

	func init(combat_node):
		node = combat_node

	func move_entities(array, goal):
		for a in array:
			a.entity.move_to(goal)

func start_new_combat():
	print("starting_new_combat!");
	var res_combat : combat = combat.new();
	return res_combat

func INIT_MANAGER():
	# create entity manager.
	cem = Node.new();
	add_child(cem);
	cem.set_script(load("res://scripts/combat/combat_entity.gd"));
	cem.print_test();
	cmp = Node.new();
	add_child(cmp);
	cmp.set_script(load("res://scripts/combat/combat_map.gd"));
	cmp.print_test();
	atp = Node.new()
	add_child(atp)
	atp.set_script(load("res://scripts/combat/attack_parser.gd"))
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	INIT_MANAGER()
	start_test_combat();
	pass # Replace with function body.

func start_test_combat():
	var combat = start_new_combat();
	combat.init(self.get_child(0))
	combat.generate_map(cmp, 10, 10)
	combat.add_entity(cem.create_test_entity(0, 0, 0).create_display_object())
	combat.add_entity(cem.create_test_entity(1, 8, 8).create_display_object())
	combat.map.update_tile_neighbours()
	combat.entity_list[0].add_attacks(atp.load_file_and_parse("test_ai"));
	combat.entity_list[0].exec_attack(0)
	#combat.map.get_path(0,0, 9,9)
	return combat;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

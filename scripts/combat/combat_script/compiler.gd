extends Node

var operations = Node.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	operations.set_script(load("res://scripts/combat/combat_script/operations.gd"))
	pass # Replace with function body.

func _init():	
	operations.set_script(load("res://scripts/combat/combat_script/operations.gd"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func compile(result):
	var res = compile_instruction(result)
	print(res.debug())
	return res

enum ctype{
	cop,
	cnum,
	cstr,
	cstrlit,
	cjump,
	ccom
}

enum ntype{
	efunc,
	estr_lit,
	eint_lit,
	eadd,
	esub,
	emul,
	ediv,
	evar,
	escope
}

#--------------------------------------------COMPILING HERE!-------------------------------------------
func compile_instruction(ins):
	var child = []
	print("current ins : ", ins.type, " " ,ins.value)
	if ins.children.size()>0:
		for c in ins.children:
			child.push_back(compile_instruction(c))
	if ins.type == ntype.efunc:
		print("got a function, ", ins.value)
		return nfunc.new([null, ins.value], ins.arg_count, child)
	if ins.t == ctype.cnum:
		return nnum_lit.new(int(ins.value))
	if ins.t == ctype.cstrlit:
		return nstr_lit.new(ins.value)
	if ins.t == ctype.cstr:
		if(child.size()==1 && child[0].ntype == "func"):
			child[0].name = [nvariable.new(ins.value, [child[0].name[0]]), child[0].name[1]]
			print(" is a call text!, ", child[0].name, " ", child[0].name[0].exec())
			return child[0]
		return nvariable.new(ins.value, child)
	if ins.t == ctype.cop:
		if(acc_op_i.has(ins.value)):
			#print(child.size(), " : ", child)
			return operations.get_op(child[0], child[1], ins.value)
	return empty.new(ins.value, child)

#------------------------------------------------COMPILING ENDS HERE!---------------------------------

var acc_op_i = ['=', '*', '+', '-']

class empty:
	var children
	var name
	var ntype = "null"

	func _init(_name, _children):
		name = _name
		children=_children
	func exec(vars=null):
		return " null node "
	func debug():
		var str = ""
		for c in children:
			str += c.debug()+" "
		return name + " null " + str 	

class nfunc:	
	var name
	var args = []
	var ntype = "func"
	var child = null

	func _init(_name, _arg_count, _args):
		print("args ", _args, " : ", _arg_count)
		if(_args.size()>0):
			#for i in _arg_count:
				#args.push_back(_args[i])
			if(_arg_count>0):
				for i in _arg_count:
					args.push_back(_args[i])
					print("arg added ", _args[i].ntype)
				if _args.size() > _arg_count:
					child=_args[_args.size()-1]

			else:
				child = _args[0]
		name = _name
		pass
	
	func exec(vars=null, extra=null):
		if(vars!=null):
			var ar = []
			for a in args:
				ar.push_back(a.exec(vars))
			print(name)
			var val = null
			if name[0]!=null:	
				val = name[0].exec(vars)
			var r = vars.callfunc(val, getname(), ar, extra)
			if child!=null:
				child.exec(vars, r)
		return "func not implemented"

	func getname(vars=null):
		var res = [name[1]]
		return name[1]
		if(name[0]==null):
			return [name[1]]
		else:
			res.push_back(name[0].exec(vars))
		return res

	func debug():
		print("FUNCTION NAME : ", getname())
		pass
		var arg_d = ""
		for a in args:
			arg_d += a.debug() + " "
		if name==null:
			return " calling error with args " + arg_d
		if child!=null:
			arg_d += " ." + child.debug()
		if(name[1]==null):	
			return "calling " + name[0] + " with args " + arg_d
		return "calling " + str(getname()) + " with args " + arg_d

enum etype{
	etile,
	enumb,
	estr,
	err,
	eent
}

class nnum_lit:
	var value	
	var ntype = "num_lit"

	func exec(vars=null):
		return [etype.enumb, value]
	func _init( _value):
		value =  _value
	func debug():
		return str(value)

class nstr_lit:
	var value	
	var ntype = "num_lit"

	func exec(vars=null):
		return [etype.estr, value]
	func _init( _value):
		value =  _value
	func debug():
		return str(value)

class nvariable:
	var name
	var children = []
	var ntype = "var"

	func vset(vars, val):
		if(vars!=null):
			vars.set_var(get_name(), val)
		return get_name()

	func get_name():
		var value = [name]
		if(children!=null):
			for child in children:
				if(child!=null):
					value.push_back(child.exec())
		return value
		

	func exec(vars=null):
		var value = [name]
		if(children!=null):
			for child in children:
				if(child!=null):
					value.push_back(child.exec())
		print(" var got ", value )
		if(vars!=null):
			#return vars.get_var(get_name())
			return vars.get_var(get_name())

	func _init(_value, _children):
		name = _value
		children = _children
	func debug():
		var str = ""
		for c in children:
			str+=c.debug()
		return name + " " + str


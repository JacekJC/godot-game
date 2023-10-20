extends Node


var parser
var tokenizer
var compiler

# Called when the node enters the scene tree for the first time.
func _ready():
	parser = Node2D.new()
	parser.set_script(load("res://scripts/combat/combat_script/parser.gd"))
	tokenizer = Node2D.new()
	tokenizer.set_script(load("res://scripts/combat/combat_script/tokenizer.gd"))
	compiler = Node2D.new()
	compiler.set_script(load("res://scripts/combat/combat_script/compiler.gd"))
	var line = "me = combat.get_friends( combat.getme, wow )"
	line = "set_this = combat.get_me()"
	print("parsing line, ", line)
	var p = parser.parse_line(line)
	print("tokenizing ",p)
	p = tokenizer.tokenize(p, 0)
	print("compiling ",p[1])
	p = compiler.compile(p[1])
	print(p.debug())
	pass
	#print(exists)
	#print("|| PARSING ATTACKS ||")

func _init():	
	print("attack parser loaded")	

func fPrint( params ):
	var fstr = ""
	for p in params:
		fstr+=str(p) + " "
	print(fstr)


class entity:
	var variables = {}

func entity_place_holder():
	return entity.new()

func load_file_and_parse(file_name):
	return null
	var exists = FileAccess.file_exists("res://aifiles/"+file_name+".txt")
	if(!exists):
		return null
	var t = FileAccess.open("res://aifiles/"+file_name+".txt", FileAccess.READ)
	t = extract_attacks(t.get_as_text().split('\n'))
	var attacks = []
	for s in t:
		var r = parser.parse_text(s.str_steps)
		s.steps = r[0]
		s.jump_points = r[1]
		s.node = self
		attacks.push_back(s)
	print("got ", attacks.size(), " attacks")
	return attacks


class attack:
	var node : Node
	var name : String
	var steps = []
	var str_steps = []
	var jump_points = {}

	var index = 0
	var controller = null

	var temp_vars = {}

	func set_temp_var(name, value):
		temp_vars[name] = value;
	
	func get_temp_var(name):
		return temp_vars[name]

	func exec(controller, combat):
		while(index < steps.size()):
			steps[index].exec({'controller'=controller, 'combat'=combat,'attack'=self})
			index += 1;
		pass
	
	func exec_debug(controller, combat):
		print("executing attack : with ", steps.size(), " steps")
		while(index < steps.size()):	
			print("--------------- : ", str_steps[index])
			var r = steps[index].exec(self)	
			index += 1;
		pass

	func fJump( name ):
		self.index = self.jumps_points[name]

	func fSet( name, value ):
		self.temp_vars[name] = value

	func set_var(path, val):
		print("setting variable ", path, " to ")
		if(["combat", "world"].has(path[0])):
			print("get parents for var")
		else:
			temp_vars[path[0]] = val
		print(path, " set to ", val)
		return temp_vars[path[0]]

	func get_var(path):
		if(["combat", "world"].has(path[0])):
			print("get parents for var")
		else:
			print("getting var ", path)
			if !temp_vars.has(path[0]):
				return "Variable does not exist"
			print("got temp var ", temp_vars[path[0]])
			return temp_vars[path[0]]
		return null

	func callfunc(oped, name, args, extra = null):
		print("function call ", oped, " ", name, " ", args, " ", extra)
		return str(name) + " called"

func extract_attacks(str_arr):
	var index = 0
	var attacks = []
	var nattack = null
	while(index < str_arr.size()):
		if(str_arr[index]==''):
			index+=1
			continue
		elif str_arr[index][0] == '<':
			if(str_arr[index][1]=='/'):
				if(nattack!=null):
					attacks.push_back(nattack)
				nattack = null;
			nattack = attack.new()
		elif(nattack!=null):
			nattack.str_steps.push_back(str_arr[index])
		index+=1
	return attacks

enum ekeywords{
	eclear,
	ejump,
	eif,
}

enum efilter{
	distance_to_closest,
	closest,
	distance_to_furthest,
	furthest,
	cover,
	union,
	difference,
	intersect
}

var filter_key = {
	"Fdistance_to_closest" = efilter.distance_to_closest, 
	"Fclosest" = efilter.closest, 
	"Fdistance_to_furthest" = efilter.distance_to_furthest, 
	"Ffurthest" = efilter.furthest,
	"Fcover" = efilter.cover,
	"Fbool_union" = efilter.union,
	"Fbool_difference" = efilter.difference,
	"Fbool_intersect" = efilter.intersect
}


var key = ['(',')',',','[',']','{','}','.','@','#','!']


func parse_text(str_array):
	var steps = [];
	var jumps = {};
	var index = 0;
	for s in str_array:
		print("parsing, ", s)
		var i = parse_line(s, index)
		if(i!=null):
			if(i[0]==0):
				jumps[i[1]] = index
				index+=1
				continue
			steps.push_back(i[1]);
			index+=1
	return [steps, jumps]

func isnum(str):
	var t = str
	if(str==null):
		return false
	if(str=="0"):
		return true
	if(int(t)==0):
		return false
	return true

#////////OPERATIONS///////////

class add_op:
	func exec(value_a, value_b, vars):
		if(value_a.type() == value_b.type()):

			if(value_a.type() == etype.enumb):
				var r = value_a.exec(vars) + value_b.exec(vars)
				return[etype.enumb, r]

			if(value_a.type() == etype.estr):
				var r = value_a.exec(vars) + value_b.exec(vars)
				return[etype.estr, r]

			if(value_a.type() == etype.etile):
				var r = []+value_a.exec(vars)
				var b = value_b.exec(vars)
				for t in b:
					if(!r.has(t)):
						r.push_back(t)
				return[etype.etile, r]
		return[etype.err, "Non-matching types"]

class sub_op:
	func exec(value_a, value_b, vars):
		if(value_a.type() == value_b.type()):
			if(value_a.type() == etype.etile):
				var r = []+value_a.exec(vars)
				var b = value_b.exec(vars)
				for t in b:
					if(r.has(t)):
						r.erase(t)
				return[etype.etile, r]

			elif(value_a.type() == etype.enumb):
				var r = value_a.exec(vars) + value_b.exec(vars)
				return[etype.enumb, r]
		return[etype.err, "Non-matching types"]

class mul_op:
	func exec(value_a, value_b, vars):
		if(value_a.type() == value_b.type()):
			if(value_a.type() == etype.etile):
				var r = []
				var a = value_b.exec(vars)
				var b = value_b.exec(vars)
				for t in b:
					if(a.has(t)):
						r.push_back(t)
				return[etype.etile, r]
			elif(value_a.type() == etype.enumb):
				var r = value_a.exec(vars) * value_b.exec(vars)
				return[etype.enumb, r]
		return[etype.err, "Non-matching types"]

class eq_op:
	func exec(value_a, value_b, vars):	
		return value_a.vset(vars, value_b.exec(vars))
		
class nop:
	var left
	var right
	var operation

	func exec(vars):
		print("executing calc ")
		return operation.exec(left, right, vars)

	func _init(_left, _right, _op):
		left=_left
		right=_right
		if(_op=="="):
			operation = eq_op.new()
		elif(_op=="+"):
			operation = add_op.new()
		elif(_op=="-"):
			operation = sub_op.new()
		elif(_op=="*"):
			operation = mul_op.new()
	func debug():
		return "will calc " + left.debug() + " : " + right.debug()



func compile_line(result):
	var res = compile_instruction(result)
	print(res.debug())
	return res

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
			return nop.new(child[0], child[1], ins.value)
	return empty.new(ins.value, child)

#------------------------------------------------COMPILING ENDS HERE!---------------------------------
		
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
		

var v_chars = ['#','%','$','~']

var operators = ['!=', '==', '>', '<', '+', '-', '=', '&&', '||', '!!']

class ctoken:
	var t : ctype
	var value : String

	func _init(_t, _value):
		value = _value
		t = _t
		

enum ctype{
	cop,
	cnum,
	cstr,
	cstrlit,
	cjump,
	ccom
}

func parse_line(line, index = 0):
	var i = 0
	var ind = 0;
	var result = []
	var buffer = ""; 
	var c = read_char(line,ind)
	while c != null && i < 100:
		#print(buffer)
		buffer = ""
		if ignore.has(c):
			ind+=1
			c = read_char(line, ind)
			continue
		if is_a_n(c):
			if isnum(c):
				while c!=null && isnum(c):
					buffer+= c
					ind+=1
					c=read_char(line,ind)
				result.push_back(ctoken.new(ctype.cnum, buffer))
				continue
			else:
				while c!=null && is_char(c):
					buffer+=c
					ind+=1
					c=read_char(line,ind)
				result.push_back(ctoken.new(ctype.cstr, buffer))
				continue
		else:
			if c!=null && is_op(c):
				if c=='#':
					buffer+=c
					ind+=1
					c=read_char(line, ind)
					while is_char(c):
						buffer+=c
						ind+=1
						c=read_char(line, ind)
					result.push_back(ctoken.new(ctype.cop, buffer))	
					ind+=1
					c=read_char(line, ind)
					continue
				elif c=='!'&&ind==0:
					return null
				elif c=="'":
					ind+=1
					c = read_char(line,ind)
					while c != "'":
						if(c!="'"):
							buffer+=c
						ind+=1
						c = read_char(line, ind)
					ind+=1
					result.push_back(ctoken.new(ctype.cstrlit, buffer))
					c=read_char(line,ind)
					continue
				buffer+=c
				result.push_back(ctoken.new(ctype.cop, buffer))	
				ind+=1
				c=read_char(line,ind)
				continue
		ind+=1
		c = read_char(line, ind)
	var r = tokenize(result, 0)
	if r != null:
		if(r[0] == 0):
			return r
		if(r[0] == 1):
			return [1, compile_line(r[1])]
	return null

class token:
	var t : ctype
	var type : ntype
	var value : String
	var arg_count : int = 0
	var children: Array[token] = []

	func debug():	
		var str = value + " ("
		if(children.size()==2):
			return "["+children[0].debug() + " " + value + " " + children[1].debug()+"]"
		if(children.size()==0):
			return "{"+self.value+"}"
		for c in children:
			str+= c.debug() + " "
		str+=") "
		return str
			

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

func tokenize(tokens, depth, adepth = 0):
	var stri=""
	if(tokens.size()==0):
		return null
	if depth==0:
		if tokens.size() == 1:
			if tokens[0].value[0] == '#':
				#JUMP POINT HERE
				return [0, tokens[0].value[0]]
	var ctoken = token.new()
	ctoken.type = ntype.eint_lit
	if(tokens.size()==1):
		if(tokens[0].value=="FUNC"):
			return tokens[0].children
		ctoken.value = tokens[0].value
		ctoken.t = tokens[0].t
		if(depth>0):
			ctoken.children = tokens[0].children
		if(adepth==0):
			return [1, ctoken]
		return ctoken
	ctoken.value="FUNC"
	var sub_index = []
	var a_tokens = []
	var sub_tokens = []
	var a_depth = 0
	#handle brackets
	var n_token = token.new()
	for t in tokens:
		if(t.value==""):
			continue
		n_token = token.new()
		n_token.type = ntype.eint_lit
		n_token.t = t.t
		n_token.value = t.value
		if t.t == ctype.cop:
			if(t.value=="("):	
				if(a_depth>0):
					sub_tokens.push_back(n_token)
				a_depth+=1
				continue
			if(t.value==")"):
				print("--CLOSED BRACKET FOUND--")
				a_depth-=1
				if a_depth==0:
					stri=""
					for s in sub_tokens:
						stri+=s.value+" "
					print(stri)
					var res = tokenize(sub_tokens, depth, adepth+1)
					if(res!=null):
						stri = res.value+" "
						for g in res.children:
							stri+=g.value+" "
						print("func: ", stri)
						if(res.value=="FUNC"):
							a_tokens[a_tokens.size()-1].children = res.children
						else:
							a_tokens[a_tokens.size()-1].children.push_back(res)
						if res.children.size() == 0:
							a_tokens[a_tokens.size()-1].arg_count = 1
						else:
							a_tokens[a_tokens.size()-1].arg_count = res.children.size()
					else:	
						print("func res null")
					a_tokens[a_tokens.size()-1].type = ntype.efunc
					print("set a function!!! ", a_tokens[a_tokens.size()-1].value)
				#	a_tokens[a_tokens.size()-1].children[a_tokens[a_tokens.size()-1].children.size()-1].type=ntype.efunc
					#print("brackets debug ", a_tokens[a_tokens.size()-1].debug())
					sub_tokens = []
				else:
					sub_tokens.push_back(n_token)
				continue
		if a_depth < 1 :
			n_token.value = t.value
			n_token.t = t.t
			if depth>0:
				n_token.children = t.children
			a_tokens.push_back(n_token)
		else:
			sub_tokens.push_back(t)
	#handle sub_values
	var ind = a_tokens.size()-1
	while ind >= 0:
		if(a_tokens[ind].t == ctype.cop):
			if(a_tokens[ind].value == "."):
				a_tokens[ind-1].children.push_back(a_tokens[ind+1])
				a_tokens.remove_at(ind+1)
				a_tokens.remove_at(ind)
		ind-=1	
	stri=""
	for t in a_tokens:
		stri+=t.value+" "+str(t.type)+" "
	print("nice little debug ", stri)
	#handle commas:
	var fin_tokens = []
	var c_tokens = []
	ind = 0
	while ind < a_tokens.size():
		#print("handeling ", ind, " : ", a_tokens[ind].debug())
		if(a_tokens[ind].t == ctype.cop):
			if(a_tokens[ind].value == ','):
				#print("splitting for comma ")
				fin_tokens.push_back(c_tokens)
				c_tokens = []
				ind+=1
				continue
		c_tokens.push_back(a_tokens[ind])
		ind+=1	

	fin_tokens.push_back(c_tokens)
	if(fin_tokens.size()>1):
		a_tokens = []
		for t in fin_tokens:
			if(t.size()>1):
				#print("PROCESSING FOR COMMA THING ", t.size())
				a_tokens.push_back(tokenize(t, depth, adepth+1))
			else:
				a_tokens.push_back(t[0])

	#handle operators
	ind = 0
	var i_ind = -1
	for t in a_tokens:
		#print("testing for op ", t.debug())
		if(t.t==ctype.cop):
			if(acc_op_i.has(t.value) && (i_ind==-1 || acc_op_i.find(t.value) < acc_op_i.find(a_tokens[i_ind].value))):
				i_ind = ind
		ind+=1
	if(i_ind!=-1):
		#print("splitting for ", i_ind, " ", a_tokens[i_ind].debug())
		ctoken.value = a_tokens[i_ind].value
		ctoken.t = a_tokens[i_ind].t
		var split = split_arr(a_tokens, i_ind)
		#print("split stats ", split[0].size(), " : ", split[1].size())
		ctoken.children.push_back(tokenize(split[0], depth+1, adepth+1))
		ctoken.children.push_back(tokenize(split[1], depth+1, adepth+1))
	else:
		for t in a_tokens:
			ctoken.children.push_back(t)
	ind = 0
	while ind < ctoken.children.size():
		if(ctoken.children[ind]==null):
			ctoken.children.remove_at(ind)
			ind-=1
		ind+=1
	if(depth==0):
		if(ctoken.children.size()==1):
			if(ctoken.value=="FUNC"):
				if adepth==0:
					return [1, ctoken.children[0]]
				return ctoken.children[0]
				
	if adepth==0:
		return [1, ctoken]
	return ctoken

var scope_chars = ['^', '$', '#']

var acc_op_i = ['=', '*', '+', '-']

var op_i = ["=", "*", "/", "+", "-", "!", "#", "$", "%"]

func sub_arr(arr, lower, upper):
	var rarr = []
	var i = lower
	while i < upper:
		rarr.push_back(arr[i])
		i+=1
	return rarr

func split_arr(arr, index):
	var left = []
	var right = []
	var ind = 0
	while(ind<index):
		left.push_back(arr[ind])
		ind+=1
	ind=index+1
	while(ind<arr.size()):
		right.push_back(arr[ind])
		ind+=1
	return [left, right]

class e_error:
	var error_msg : String

	func _init(msg):
		error_msg = msg

enum etype{
	etile,
	enumb,
	estr,
	err,
	eent
}

func read_char(line, ind):
	if(len(line)==ind):
		return null
	return line[ind]

var oddchar = ['=','/','\\','+','-','!','"','£','$','%','^','&','*','(',')',
				'#','|','?','~','{','}','[',']','¬',"'",'.',',']

func is_speech(cchar):
	if(cchar=='"'):
		return true
	return false

var ignore = ['\n', '\t', '\r', ' ', '']

func is_op(cchar):
	#print("is", cchar, "in oddchar : ", oddchar.has(cchar))
	if(oddchar.has(cchar)):
		return true
	return false

func is_a_n(cchar):
	if(cchar=='0' or int(cchar)!=0):
		return true
	if(!oddchar.has(cchar)&&!ignore.has(cchar)):
		return true
	return false

func is_char(cchar):
	if oddchar.has(cchar):
		return false
	if ignore.has(cchar):
		return false
	if isnum(cchar):
		return false
	return true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

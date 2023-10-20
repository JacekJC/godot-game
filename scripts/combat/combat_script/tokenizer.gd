extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


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

var acc_op_i = ['=', '*', '+', '-']

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

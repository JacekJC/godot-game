extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


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
	return result

func read_char(line, ind):
	if(len(line)==ind):
		return null
	return line[ind]

var oddchar = ['=','/','\\','+','-','!','"','£','$','%','^','&','*','(',')',
				'#','|','?','~','{','}','[',']','¬',"'",'.',',']

var ignore = ['\n', '\t', '\r', ' ', '']

func isnum(str):
	var t = str
	if(str==null):
		return false
	if(str=="0"):
		return true
	if(int(t)==0):
		return false
	return true

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


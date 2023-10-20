extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
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

enum etype{
	etile,
	enumb,
	estr,
	err,
	eent
}

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
	
func get_op(left,right,op):
	return nop.new(left,right,op)

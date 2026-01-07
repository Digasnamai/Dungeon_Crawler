extends Node

var cam1
var cam2
var proto_controller
var TransitionScreen

#dungeon x,y cell coordinate array size
@export var _dimensions : Vector2i = Vector2i(7, 7)
#setting x and y to -1 will determine a random entrace
@export var _start : Vector2i = Vector2i(-1, -1) 
#shortest path to completion
@export var _critical_path_length: int 
#number of branches
@export var _branches : int 
@export var _branch_length : Vector2i = Vector2i(1, 2)
#double rooms
@export var _doubles : int
var double_rooms_joined : Array

var _branch_candidates : Array[Vector2i]
var _double_candidates : Array[Vector2i]
var dungeon : Array
var doubles_pairs : Array

var _room_size : int

var _direction : Vector2i
var _current_room: Vector2i

var room = load("res://room.tscn")

func _ready() -> void:
	
	cam1 = get_node("SubViewportContainer (shader)/SubViewport/Cam1")
	cam2 = get_node("SubViewportContainer (shader)/SubViewport/ProtoController/Head/Camera3D")
	proto_controller = get_node("SubViewportContainer (shader)/SubViewport/ProtoController")
	TransitionScreen = get_node("TransitionScreen")
	
	#same results every time
	#seed(12345) 

	
	_initialize_dungeon()
	_place_entrance()
	_generate_path(_start, _critical_path_length, "M")
	
	#_print_dungeon()
	
	#_place_doubles()
	
	#_print_dungeon()
	
	_generate_branches()
	
	_print_dungeon()
	
	_generate_rooms()
	
	_place_player()


func _initialize_dungeon() -> void:
	
	#number of branches in the path
	_critical_path_length = randi_range(4,6)
	_branches = randi_range(0,2)
	_doubles = randi_range(1,2)
	_room_size = 7
	
	for x in _dimensions.x:
		dungeon.append([])
		for y in _dimensions.y:
			dungeon[x].append(0)
	

func _process(delta: float) -> void:
	
	var dungeon_as_string : String = ""
	for y in _dimensions.y:
		for x in _dimensions.x:
			if dungeon[x][y]:
				if Vector2i(x,y) == _current_room:
					dungeon_as_string += "[Y]"
				else:
					dungeon_as_string += "[ ]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += '\n'
	
	$Label.text = dungeon_as_string
	
	
func _place_entrance() -> void:
	if _start.x < 0 or _start.x >= _dimensions.x:
		_start.x = randi_range(0, _dimensions.x - 1)
	if _start.y < 0 or _start.y >= _dimensions.y:
		_start.y = randi_range(0, _dimensions.y - 1)
	dungeon[_start.x][_start.y] = "B"

func _generate_path(from : Vector2i, length : int, marker : String) -> bool:
	if length == 0:
		return true
	
	var current : Vector2i = from
	var direction : Vector2i
	match randi_range(0, 3):
		0:
			direction = Vector2i.UP
		1:
			direction = Vector2i.RIGHT
		2:
			direction = Vector2i.DOWN
		3:
			direction = Vector2i.LEFT
	for i in 4:
		if (current.x + direction.x >= 0 and current.x + direction.x < _dimensions.x and
			current.y + direction.y >= 0 and current.y + direction.y < _dimensions.y and
			not dungeon[current.x + direction.x][current.y + direction.y]):
			current += direction
			dungeon[current.x][current.y] = marker
			if dungeon[current.x][current.y] == "M":
				if length == 1:
					dungeon[current.x][current.y] = "E"
				else:
					_double_candidates.append(current)
					
			elif length == 1:
				dungeon[current.x][current.y] = "S"
				
			_branch_candidates.append(current)
			
			if _generate_path(current, length - 1, marker):
				
				if length == _critical_path_length:
					_direction = direction
				return true
			else:
				_branch_candidates.erase(current)
				dungeon[current.x][current.y] = 0
				current -= direction

		direction = Vector2(direction.y, -direction.x)
	return false

			
func _place_doubles() -> void:
	
	var doubles_created : int = 0
	var candidate : Vector2i
	
	while doubles_created < _doubles and _double_candidates.size():
		
		var direction : Vector2i
		match randi_range(0, 3):
			0:
				direction = Vector2i.UP
			1:
				direction = Vector2i.RIGHT
			2:
				direction = Vector2i.DOWN
			3:
				direction = Vector2i.LEFT
		
		candidate = _double_candidates[randi_range(0, _double_candidates.size() - 1)]
		
		if (candidate.x + direction.x >= 0 and candidate.x + direction.x < _dimensions.x and 
		candidate.y + direction.y >= 0 and candidate.y + direction.y < _dimensions.y and not 
		dungeon[candidate.x + direction.x][candidate.y + direction.y] and
		str(dungeon[candidate.x + direction.x][candidate.y + direction.y]) != "E" and
		str(dungeon[candidate.x + direction.x][candidate.y + direction.y]) != "D" and
		str(dungeon[candidate.x + direction.x][candidate.y + direction.y]) != "B"):
			
			dungeon[candidate.x + direction.x][candidate.y + direction.y] = "D"
			dungeon[candidate.x][candidate.y] = "D"
			
			_double_candidates.erase(candidate)
			_double_candidates.erase(candidate + direction)
			
			doubles_created += 1
			doubles_pairs.append([candidate,candidate + direction])
			
		else: direction = Vector2(direction.y, -direction.x)
	
func _generate_branches() -> void:
	var branches_created : int = 0
	var candidate : Vector2i
	while branches_created < _branches and _branch_candidates.size():
		candidate = _branch_candidates[randi_range(0, _branch_candidates.size() - 1)]
		if _generate_path(candidate, randi_range(_branch_length.x, _branch_length.y), str(branches_created + 1)):
			branches_created += 1
		else:
			_branch_candidates.erase(candidate)

func _print_dungeon() -> void:
	var dungeon_as_string : String = ""
	for y in _dimensions.y:
		for x in _dimensions.x:
			if dungeon[x][y]:
				dungeon_as_string += "[" + str(dungeon[x][y]) + "]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += '\n'
	print(dungeon_as_string)
	
func _generate_rooms() -> void:
	for y in _dimensions.y:
		for x in _dimensions.x:
			if dungeon[x][y]:

				var rooms_node = get_child(0)
				
				
				var new_room = room.instantiate()
				rooms_node.add_child(new_room)
				var added_room = rooms_node.get_child(rooms_node.get_child_count()-1)
				
				
				added_room.position = Vector3(x*_room_size,0,y*_room_size)
				
				var _possible_directions = [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
				var _directions : Array = []
				var _exclude : Array = []
				
				for direction in _possible_directions:
					if (x + direction.x >= 0 and x + direction.x < _dimensions.x and 
					y + direction.y >= 0 and y + direction.y < _dimensions.y and  
					dungeon[x + direction.x][y + direction.y] and not
					((str(dungeon[x][y]) == "B" and str(dungeon[x + direction.x][y + direction.y]) == "E") or 
					(str(dungeon[x][y]) == "E" and str(dungeon[x + direction.x][y + direction.y]) == "B"))):
						
						if not (str(dungeon[x][y]) == "D" and str(dungeon[x + direction.x][y + direction.y]) == "D"):
							_directions.append(direction)
						else:
							_exclude.append(direction)
							if (([Vector2i(x,y), Vector2i(x+direction.x,y+direction.y)] in doubles_pairs) or 
							([Vector2i(x+direction.x,y+direction.y),Vector2i(x,y)] in doubles_pairs)):
								if Vector2i(x,y) not in double_rooms_joined and Vector2i(x+direction.x,y+direction.y) not in double_rooms_joined:
									added_room._spawn_double_room_joint(direction, _room_size)
									double_rooms_joined.append(Vector2i(x,y))
									double_rooms_joined.append(Vector2i(x+direction.x,y+direction.y))
									#print(double_rooms_joined)
							else:
								_exclude.erase(direction)
								_directions.append(direction)

				
				added_room._spawn_hallways_and_walls(_directions, _room_size, _exclude)
				
				if dungeon[x][y] == "B":
					added_room.material.albedo_color = Color(1,1,0)
				elif dungeon[x][y] == "M":
					added_room.material.albedo_color = Color(1,0.5,0.5)
				elif dungeon[x][y] == "E":
					added_room.material.albedo_color = Color(1,0,0)
				elif dungeon[x][y] == "D":
					added_room.material.albedo_color = Color(0,1,0)
				#elif dungeon[x][y].is_valid_integer():
					#pass


func _place_player():
	#start at middle of room and displace it by a quarter of a room's size in the opposite direction of the starting direction
	proto_controller.position = Vector3i(_start.x*_room_size - _room_size/4 * _direction.x,0,_start.y*_room_size - _room_size/4 * _direction.y)
	proto_controller.look_at(Vector3i((_start.x + _direction.x)*_room_size,0,(_start.y + _direction.y)*_room_size),Vector3i(0,1,0))
	proto_controller.change_look_rotation()

	_current_room = Vector2i(_start.x,_start.y)
	
func _input(event):
	
	if event.is_action_pressed("ui_accept"):
		cam1.set_current(not cam1.current)
		cam1.set_current(not cam2.current)

	if Input.is_action_just_pressed("ui_right"):

		if not proto_controller.is_tween_running():
			_direction = Vector2i(-_direction.y,_direction.x)
			var _target_position = Vector3(_current_room.x*_room_size - _room_size/4 * _direction.x,0,_current_room.y*_room_size - _room_size/4 * _direction.y)
			proto_controller.move_sideways(_target_position, Vector3(0,-PI/2,0))
		
	if Input.is_action_just_pressed("ui_left"):

		if not proto_controller.is_tween_running():
			_direction = Vector2i(_direction.y,-_direction.x)
			var _target_position = Vector3(_current_room.x*_room_size - _room_size/4 * _direction.x,0,_current_room.y*_room_size - _room_size/4 * _direction.y)
			proto_controller.move_sideways(_target_position, Vector3(0,PI/2,0))
		
	if Input.is_action_just_pressed("ui_up"):
		
		if (_current_room.x + _direction.x >= 0 and _current_room.x + _direction.x < _dimensions.x and 
		_current_room.y + _direction.y >= 0 and _current_room.y + _direction.y < _dimensions.y and  
		dungeon[_current_room.x + _direction.x][_current_room.y + _direction.y] and not proto_controller.is_tween_running()):
			
			_current_room += _direction
			proto_controller.move_forward(Vector3(_current_room.x*_room_size - _room_size/4 * _direction.x,0,_current_room.y*_room_size - _room_size/4 * _direction.y))
			TransitionScreen.transition()
			await TransitionScreen.on_transition_finished
			
	if Input.is_action_just_pressed("ui_down"):
		
		if (_current_room.x - _direction.x >= 0 and _current_room.x - _direction.x < _dimensions.x and 
		_current_room.y - _direction.y >= 0 and _current_room.y - _direction.y < _dimensions.y and  
		dungeon[_current_room.x - _direction.x][_current_room.y - _direction.y]):
			
			_current_room -= _direction
			_direction = -_direction
			TransitionScreen.transition()
			await TransitionScreen.on_transition_finished
			proto_controller.position = Vector3i(_current_room.x*_room_size - _room_size/4 * _direction.x,0,_current_room.y*_room_size - _room_size/4 * _direction.y)
			proto_controller.look_at(Vector3i((_current_room.x + _direction.x)*_room_size,0,(_current_room.y + _direction.y)*_room_size),Vector3i(0,1,0))

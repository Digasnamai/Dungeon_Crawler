extends CSGBox3D

@onready var type

var hallway = load("res://hallway.tscn")
var joint = load("res://double_room_joint.tscn")
var wall = load("res://wall.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _spawn_hallways_and_walls(directions : Array, room_size : int, exclude : Array):

	var _possible_directions = [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
	
	for direction in directions:

		var new_hallway = hallway.instantiate()
		add_child(new_hallway)
		var added_hallway = get_child(get_child_count()-1)
		
		if (direction.y != 0):
			added_hallway.rotation_degrees.y = 90
		added_hallway.position = Vector3(direction.x * (room_size/2),0,direction.y * (room_size/2))
		
	for direction in _possible_directions:
		if direction not in directions:
			if direction not in exclude:
				var new_wall = wall.instantiate()
				add_child(new_wall)
				var added_wall = get_child(get_child_count()-1)
			
				if (direction.y != 0):
					added_wall.rotation_degrees.y = 90
				added_wall.position = Vector3(direction.x * room_size/2,0,direction.y * room_size/2)


func _spawn_double_room_joint(direction: Vector2i, room_size : int):

	var new_joint = joint.instantiate()
	add_child(new_joint)
	var added_joint = get_child(get_child_count()-1)
	
	if (direction.y != 0):
		added_joint.rotation_degrees.y = 90
	added_joint.position = Vector3(direction.x * room_size/2.0,0,direction.y * room_size/2.0)
	

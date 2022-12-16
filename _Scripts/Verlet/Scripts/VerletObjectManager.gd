extends Node


# variable declarations
export var followMouse = false
export var startingPosition: Vector2 = Vector2(0,0)
export var offsetDirection: Vector2 = Vector2(0,1)
export var pinnedSlack = 1.8
export var iterations: int = 80
export var totalNodes: int = 30
export var nodeDistance: float = 16
export var gravity: Vector2 = Vector2(0, 980)
export var ropeColour: Color = Color(1,1,1,1)
export var ropeWidth: float = 1
var nodes = []
var nodeObject = preload("res://Objects/VerletObject.tscn")
var lineRenderer: Line2D
var ticks = 0

func _ready():
	# create child nodes
	for i in totalNodes:
		#var newNode = nodeObject.instance()
		var newNode = {"currentPosition": Vector2(), "oldPosition": Vector2()}
		#newNode.transform.origin = startingPosition
		#newNode.transform.origin += (offsetDirection) * (nodeDistance * i)
		newNode.currentPosition = startingPosition
		newNode.currentPosition += (offsetDirection) * (nodeDistance * i)
		nodes.push_back(newNode)
		#add_child(newNode)
	
	# find nodes and store in array for modification
	#nodes = get_children()
	
	# create line renderer as child
	lineRenderer = Line2D.new()
	lineRenderer.set_default_color(ropeColour)
	lineRenderer.set_width(ropeWidth)
	lineRenderer.set_antialiased(false)
	lineRenderer.set_begin_cap_mode(2)
	lineRenderer.set_end_cap_mode(2)
	lineRenderer.set_joint_mode(2)
	for i in nodes.size():
		lineRenderer.add_point(nodes[i].currentPosition)
	add_child(lineRenderer)


func _physics_process(delta):
	ticks += 1
	simulate(delta)
	for i in iterations:
		apply_constraints()
	update_line()


# custom functions
func simulate(delta):
	for i in nodes.size():
		var temp: Vector2 = nodes[i].currentPosition
		var amountMoved = (nodes[i].currentPosition - nodes[i].oldPosition) + (gravity * delta * delta)
		nodes[i].currentPosition += amountMoved
		nodes[i].oldPosition = temp
	
		# update position and check collision
		#nodes[i].global_transform.origin = nodes[i].currentPosition
		# var collision = nodes[i].move_and_collide(amountMoved)
		#if collision:
			#var hitPos = collision.get_position()
			#nodes[i].currentPosition = hitPos

func apply_constraints():
	for i in nodes.size() - 1:
		var node1 = nodes[i]
		var node2 = nodes[i + 1]
		
		# make sure first node follows mouse
		if followMouse:
			if i == 0:
				node1.currentPosition = get_viewport().get_mouse_position()
		else:
			if i == 0:
				node1.currentPosition = startingPosition
			elif i + 1 == nodes.size() - 1:
				node2.currentPosition = startingPosition + (offsetDirection * (nodeDistance * (nodes.size() / pinnedSlack)))
		
		# get current distance between the two nodes
		var diffX = node1.currentPosition.x - node2.currentPosition.x
		var diffY = node1.currentPosition.y - node2.currentPosition.y
		var distance = node1.currentPosition.distance_to(node2.currentPosition)
		var difference = 0
		
		# avoid a division by zero
		if distance > 0:
			difference = (nodeDistance - distance) / distance
		
		var translation = Vector2(diffX, diffY) * (0.5 * difference)
		
		#var col1 = node1.move_and_collide(translation)
		node1.currentPosition += translation
		#if col1:
			#var hitPos = col1.get_position()
			#node1.currentPosition = hitPos
			
		#var col2 = node2.move_and_collide(-translation)
		node2.currentPosition -= translation
		#if col2:
			#var hitPos = col2.get_position()
			#node2.currentPosition = hitPos

func update_line():
	for i in nodes.size():
		lineRenderer.set_point_position(i, nodes[i].currentPosition)

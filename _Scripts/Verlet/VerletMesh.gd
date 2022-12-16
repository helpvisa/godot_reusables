extends Node2D

# testing
onready var testBody = preload("res://Objects/TestBody.tscn")

# variable declarations
export var followMouse = false
export var startingPosition: Vector2 = Vector2(0,0)
export var iterations: int = 60
export var isRigid: bool = true;
export var gravity: Vector2 = Vector2(0, 980) # in pixels per second
export var friction: float = 0.98
export var bounce: float = 1
export var maxRopeTension: float = 0
export var ropeColour: Color = Color(1,1,1,1)
export var ropeWidth: float = 2
export var checkCollision: bool = false
export var selectWidth: int = 3
var nodeBoard = false
var runSimulation: bool = false
var nodes = []
var savedNodes = []
var sticks = []
var savedSticks = null
var toDelete = []
var ticks = 0


###########
# main body
# on load
func _ready():
	pass


# update loops
func _process(_delta):
	if Input.is_action_just_pressed("toggleSimulation"):
		runSimulation = !runSimulation
	
	if Input.is_action_just_pressed("leftClick"):
		construct_node(get_viewport().get_mouse_position())
	
	if Input.is_action_pressed("rightClick"):
		var mousePos = get_viewport().get_mouse_position()
		for i in nodes.size():
			if mousePos.x > nodes[i].currentPosition.x - selectWidth\
			and mousePos.x < nodes[i].currentPosition.x + selectWidth\
			and mousePos.y > nodes[i].currentPosition.y - selectWidth\
			and mousePos.y < nodes[i].currentPosition.y + selectWidth:
				if !nodeBoard:
					select_node(nodes[i])
					break
				elif nodeBoard != nodes[i]:
					connect_node(nodes[i], nodeBoard)
					deselect_node(nodeBoard)
					nodeBoard = false
	
	if Input.is_action_just_pressed("rightClick"):
		var mousePos = get_viewport().get_mouse_position()
		for i in nodes.size():
			if mousePos.x > nodes[i].currentPosition.x - selectWidth\
			and mousePos.x < nodes[i].currentPosition.x + selectWidth\
			and mousePos.y > nodes[i].currentPosition.y - selectWidth\
			and mousePos.y < nodes[i].currentPosition.y + selectWidth:
				if !nodeBoard:
					select_node(nodes[i])
					break
				elif nodeBoard != nodes[i]:
					connect_node(nodes[i], nodeBoard)
					deselect_node(nodeBoard)
					nodeBoard = false
			elif nodeBoard:
					deselect_node(nodeBoard)
					nodeBoard = false
	
	if Input.is_action_just_pressed("pinNode"):
		var mousePos = get_viewport().get_mouse_position()
		for i in nodes.size():
			if mousePos.x > nodes[i].currentPosition.x - selectWidth\
			and mousePos.x < nodes[i].currentPosition.x + selectWidth\
			and mousePos.y > nodes[i].currentPosition.y - selectWidth\
			and mousePos.y < nodes[i].currentPosition.y + selectWidth:
				pin_node(nodes[i])
	
	if Input.is_action_just_pressed("saveNodes"):
		savedSticks = var2str(sticks)
		print("Saved!")
	
	if Input.is_action_just_pressed("loadNodes"):
		if (savedSticks):
			sticks = str2var(savedSticks)
			nodes = []
			for i in sticks.size():
				nodes.push_back(sticks[i].node1)
				nodes.push_back(sticks[i].node2)
			print("Loaded!")
		else:
			nodes = []
			sticks = []
			"Reset."
	
	if Input.is_action_just_pressed("addTestBody"):
		var newBody = testBody.instance()
		newBody.global_transform.origin = get_viewport().get_mouse_position()
		add_child(newBody)


# physics loop
func _physics_process(delta):
	ticks += 1
	toDelete = []
	
	# follow mouse
	follow_mouse()
	
	if runSimulation:
		simulate(delta)
		if checkCollision:
			snapshot_collisions()
		for i in iterations:
			for k in toDelete.size():
				disconnect_node(toDelete[k])
			if checkCollision:
				resolve_collisions()
			apply_constraints()
	update()


# draw calls for lines
func _draw():
	draw_connections()
	if !runSimulation:
		draw_nodes_editable()
	else:
		draw_nodes_sim()


##################
# custom functions
# simulate verlet integration
func simulate(delta):
	for i in nodes.size():
		var temp: Vector2 = nodes[i].currentPosition
		
		if !nodes[i].pinned:
			var amountMoved = (nodes[i].currentPosition - nodes[i].oldPosition) + (gravity * delta * delta)
			if nodes[i].isTouching:
				amountMoved *= friction
				nodes[i].isTouching = false
			nodes[i].currentPosition += amountMoved
		nodes[i].oldPosition = temp


# enforce distance constraints between points
func apply_constraints():
	for i in sticks.size():
		var node1 = sticks[i].node1
		var node2 = sticks[i].node2
		
		var distance = node1.currentPosition.distance_to(node2.currentPosition)
		
		
		var diffX = node1.currentPosition.x - node2.currentPosition.x
		var diffY = node1.currentPosition.y - node2.currentPosition.y
		var difference = 0
		
		# avoid division by zero
		if distance > 0:
			difference = (sticks[i].distance - distance) / distance
		
		if difference > maxRopeTension and maxRopeTension > 0:
			toDelete.push_back(i)
			#print("deleting stick #", i)
		elif isRigid or distance > sticks[i].distance:
			var translation = Vector2(diffX, diffY) * (0.5 * difference)
			if !node1.pinned:
				node1.currentPosition += translation
			if !node2.pinned:
				node2.currentPosition -= translation


# func to snapshot nearby collisions for rope
func snapshot_collisions():
	# prepare for intersection test w sphere shape
	var physics := get_world_2d().direct_space_state
	var colShape = CircleShape2D.new()
	colShape.radius = 1
	var query = Physics2DShapeQueryParameters.new() # prepare the intersection query into the physics world
	
	for i in nodes.size():
		# reset collisions array
		nodes[i].collisions = []
		
		# create a temp transform for intersection test
		var newTransform = Transform2D()
		newTransform.origin = nodes[i].currentPosition # update its position to match node
		query.set_shape(colShape) # set shape for query
		query.transform = newTransform # set transform to query
		var collisions = physics.intersect_shape(query) # perform the query and store its results
		
		# check if we already have colliders
		#var colToAdd = []
		#for j in collisions.size():
		#	var idx = - 1
		#	for k in nodes[i].collisions.size():
		#		if nodes[i].collisions[k].collider_id == collisions[j].collider_id:
		#			idx = k
		#	if idx < 0:
		#		colToAdd.push_back(collisions[j])
		# add the ones we do not have
		#for j in colToAdd.size():
		#for j in collisions.size():
		nodes[i].collisions = collisions


# func to resolve collisions based on snapshat
func resolve_collisions():
	for i in nodes.size():
		for k in nodes[i].collisions.size():
			var body = nodes[i].collisions[k].collider
			var shape = body.find_node("CollisionShape*").get_shape()
			if shape is CircleShape2D:
				var radius = shape.get_radius()
				var distance = body.global_transform.origin.distance_to(nodes[i].currentPosition)
				
				if distance - radius <= 0:
					# push point outside circle
					var dir = nodes[i].currentPosition - body.global_transform.origin
					dir = dir.normalized()
					var hitPos = body.global_transform.origin + dir * radius
					
					var bounceVector = (hitPos - nodes[i].currentPosition) * bounce
					if !nodes[i].pinned:
						nodes[i].currentPosition = hitPos
						if !nodes[i].isTouching:
							nodes[i].currentPosition += bounceVector * bounce
					nodes[i].isTouching = true
					
					if body is RigidBody2D:
						body.apply_impulse(hitPos - body.global_position, bounceVector * -1)
				
			elif shape is RectangleShape2D:
				# get nodes position in local space of collider's transform
				var localPoint = body.to_local(nodes[i].currentPosition)
				# get its extents and scale
				var half = shape.get_extents()
				var scalar = body.transform.get_scale()
				var dx = localPoint.x
				var px = half.x - abs(dx)
				
				var dy = 0
				var py = 0
				if px > 0:
					dy = localPoint.y
					py = half.y - abs(dy)
				if py > 0:
					# push node along closest edge
					# multiply distance by scale
					if (px * scalar.x < py * scalar.y):
						var sx = sign(dx)
						localPoint.x = half.x * sx
					else:
						var sy = sign(dy)
						localPoint.y = half.y * sy
					
					var hitPos = body.to_global(localPoint)
					
					var bounceVector = (hitPos - nodes[i].currentPosition) * bounce
					if !nodes[i].pinned:
						nodes[i].currentPosition = hitPos
						if !nodes[i].isTouching:
							nodes[i].currentPosition += bounceVector * bounce
					nodes[i].isTouching = true
					
					if body is RigidBody2D:
						body.apply_impulse(hitPos - body.global_position, bounceVector * -1)


# make node follow mouse
func follow_mouse():
	if Input.is_action_pressed("follow") and nodeBoard:
		nodeBoard.currentPosition += (get_viewport().get_mouse_position() - nodeBoard.currentPosition) / 2


# plot node
func construct_node(coordinates):
	var newNode = {"currentPosition": Vector2(), "oldPosition": Vector2(), "pinned": false, "isTouching": false, "collisions": [], "colour": Color(1,0.75,0.75,1)}
	newNode.currentPosition = coordinates
	newNode.oldPosition = newNode.currentPosition
	nodes.push_back(newNode)

func select_node(node):
	node.colour = Color(1,0,0,1)
	nodeBoard = node

func deselect_node(node):
	if !node.pinned:
		node.colour = Color(1,0.75,0.75,1)
	else:
		node.colour = Color(0.75,1,0.75,1)

func connect_node(node1, node2):
	var distance = node2.currentPosition.distance_to(node1.currentPosition)
	var newStick = {"node1": node1, "node2": node2, "distance": distance}
	sticks.push_back(newStick)

func disconnect_node(index):
	sticks.remove(index)

func pin_node(node):
	if !node.pinned:
		node.colour = Color(0.75,1,0.75,1)
	else:
		node.colour = Color(1,0.75,0.75,1)
	node.pinned = !node.pinned


# graphically update line
func draw_connections():
	for i in sticks.size():
		draw_line(sticks[i].node1.currentPosition, sticks[i].node2.currentPosition, ropeColour, ropeWidth, false)


# graphically plot nodes
func draw_nodes_editable():
	for i in nodes.size():
		draw_circle(nodes[i].currentPosition, selectWidth, nodes[i].colour)

func draw_nodes_sim():
	for i in nodes.size():
		draw_circle(nodes[i].currentPosition, ropeWidth - 1, ropeColour)

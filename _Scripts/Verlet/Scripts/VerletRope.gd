extends Node2D


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
var lineRenderer: Line2D
var ticks = 0


###########
# main body
# on load
func _ready():
	# create child nodes
	for i in totalNodes:
		var newNode = {"currentPosition": Vector2(), "oldPosition": Vector2(), "collisions": []}
		newNode.currentPosition = startingPosition
		newNode.currentPosition += (offsetDirection) * (nodeDistance * i)
		nodes.push_back(newNode)
	
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


# physics loop
func _physics_process(delta):
	ticks += 1
	simulate(delta)
	snapshot_collisions()
	for i in iterations:
		apply_constraints()
		resolve_collisions()
	update_line()


##################
# custom functions
# simulate verlet integration
func simulate(delta):
	for i in nodes.size():
		var temp: Vector2 = nodes[i].currentPosition
		var amountMoved = (nodes[i].currentPosition - nodes[i].oldPosition) + (gravity * delta * delta)
		nodes[i].currentPosition += amountMoved
		nodes[i].oldPosition = temp


# enforce distance constraints between points
func apply_constraints():
	for i in nodes.size() - 1:
		var node1 = nodes[i]
		var node2 = nodes[i + 1]
		
		# make sure first node follows mouse
		if followMouse:
			if i == 0 and Input.is_action_pressed("leftClick"):
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
		
		node1.currentPosition += translation
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
		var colToAdd = []
		for j in collisions.size():
			var idx = - 1
			for k in nodes[i].collisions.size():
				if nodes[i].collisions[k].collider_id == collisions[j].collider_id:
					idx = k
			if idx < 0:
				colToAdd.push_back(collisions[j])
		# add the ones we do not have
		for j in colToAdd.size():
			nodes[i].collisions.push_back(colToAdd[j])


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
					nodes[i].currentPosition = hitPos
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
					nodes[i].currentPosition = hitPos


# graphically update line
func update_line():
	for i in nodes.size():
		lineRenderer.set_point_position(i, nodes[i].currentPosition)

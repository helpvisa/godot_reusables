extends Spatial


# variable declarations
export var startingPosition: Vector3 = Vector3(0,0,0)
export var offsetDirection: Vector3 = Vector3(0,-1,-1)
export var iterations: int = 60
export var totalNodes: int = 40
export var nodeDistance: float = 1
export var gravity: Vector3 = Vector3(0, -9.8, 0)
export var ropeColour: Color = Color(1,1,1,1)
export var ropeWidth: float = 2
var nodes = []
var ticks = 0
var meshRenderer = null


###########
# main body
# on load
func _ready():
	# create child nodes
	for i in totalNodes:
		var newNode = {"currentPosition": Vector3(), "oldPosition": Vector3()}
		newNode.currentPosition = startingPosition
		newNode.currentPosition += (offsetDirection) * (nodeDistance * i)
		newNode.oldPosition = newNode.currentPosition
		nodes.push_back(newNode)
	
	# create mesh renderer as child
	meshRenderer = ImmediateGeometry.new()
	meshRenderer.set_color(ropeColour)
	add_child(meshRenderer)


# physics loop
func _physics_process(delta):
	ticks += 1
	simulate(delta)
	for i in iterations:
		apply_constraints()
	render_line3D()


##################
# custom functions
# simulate verlet integration
func simulate(delta):
	for i in nodes.size():
		var temp: Vector3 = nodes[i].currentPosition
		var amountMoved = (nodes[i].currentPosition - nodes[i].oldPosition) + (gravity * delta)
		nodes[i].currentPosition += amountMoved
		nodes[i].oldPosition = temp


# enforce distance constraints between points
func apply_constraints():
	for i in nodes.size() - 1:
		var node1 = nodes[i]
		var node2 = nodes[i + 1]
		
		# make sure first node is pinned
		if i == 0:
			node1.currentPosition = startingPosition
		
		# get current distance between the two nodes
		var diffX = node1.currentPosition.x - node2.currentPosition.x
		var diffY = node1.currentPosition.y - node2.currentPosition.y
		var diffZ = node1.currentPosition.z - node2.currentPosition.z
		var distance = node1.currentPosition.distance_to(node2.currentPosition)
		var difference = 0
		
		# avoid a division by zero
		if distance > 0:
			difference = (nodeDistance - distance) / distance
		
		var translation = Vector3(diffX, diffY, diffZ) * (0.5 * difference)
		
		node1.currentPosition += translation
		node2.currentPosition -= translation

func render_line3D():
	meshRenderer.clear()
	meshRenderer.begin(1, null)
	for i in nodes.size():
		if i+1 < nodes.size():
			var node1 = nodes[i]
			var node2 = nodes[i+1]
			meshRenderer.add_vertex(node1.currentPosition)
			meshRenderer.add_vertex(node2.currentPosition)
	meshRenderer.end()

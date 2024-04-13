extends Camera3D

# get components
@export var state: Node

# variable declaration
@onready var originalOrigin = transform.origin
@onready var originalBasis = transform.basis
var playerRot = 0
var viewBob: Vector3 = Vector3.ZERO
var rotBobX: float = 0
var rotBobZ: float = 0
var localOffset = {
	"view": Vector3.ZERO,
	"rotX": 0.0,
	"rotZ": 0.0,
}
var resetCounter = 0
var resetCounterGoal = 0
var leftFoot = false


func _ready():
	state.connect("stepped", process_step_signal)
	state.connect("jumped", process_jump_signal)
	state.connect("landed", process_land_signal)


func _process(delta):
	# move bob toward offset goal
	lerp_bob(delta)
	
	# apply camera movement bobs
	transform.origin = originalOrigin + viewBob
	
	# apply camera rotational bobs
	transform.basis = originalBasis * Basis(Vector3.RIGHT, rotBobX) * Basis(Vector3.FORWARD, rotBobZ)
	rotation_degrees.x = playerRot


# offset state definitions
var motions = {
	"reset": {
		"view": Vector3.ZERO,
		"rotX": 0.0,
		"rotZ": 0.0,
	},
	"strideLeft": {
		"view": Vector3(0, -0.2, 0),
		"rotX": 0.0,
		"rotZ": 0.015,
	},
	"strideRight": {
		"view": Vector3(0, -0.2, 0),
		"rotX": 0.0,
		"rotZ": -0.015,
	},
	"jump": {
		"view": Vector3.ZERO,
		"rotX": -0.1,
		"rotZ": 0.0,
	},
	"land": {
		"view": Vector3(0, -0.2, 0),
		"rotX": 0.0,
		"rotZ": 0.0,
	},
}


# custom functions
func flip_foot():
	leftFoot = !leftFoot


func reset_counter():
	resetCounter = 0


func set_counter_goal(goal):
	resetCounterGoal = goal


func process_step_signal():
	reset_counter()
	set_counter_goal(0.2)
	
	if leftFoot:
		localOffset = motions.strideLeft
	else:
		localOffset = motions.strideRight
	
	flip_foot()


func process_jump_signal():
	reset_counter()
	set_counter_goal(0.05)
	
	localOffset = motions.jump


func process_land_signal(velocity):
	reset_counter()
	set_counter_goal(0.125)
	
	localOffset = motions.land
	localOffset.view.y = clamp(velocity.y / 10, -3, 0)


func lerp_bob(delta):
	resetCounter += delta
	if (resetCounter > resetCounterGoal):
		localOffset = motions.reset
	
	viewBob = lerp(viewBob, localOffset.view, 6 * delta)
	rotBobX = lerp(rotBobX, localOffset.rotX, 6 * delta)
	rotBobZ = lerp(rotBobZ, localOffset.rotZ, 6 * delta)

extends Camera

# on load
func _ready():
	state.connect("stepped", self, "processStepSignal")
	state.connect("first_step", self, "processStepSignal")
	state.connect("jumped", self, "processJumpSignal")
	state.connect("landed", self, "processLandSignal")

# processing
func _process(delta):
	# move bob toward offset goal
	lerpBob(delta)
	
	# apply camera movement bobs
	transform.origin = origin + viewBob
	
	# apply camera rotational bobs
	transform.basis = basis * Basis(Vector3.RIGHT, rotBobX) * Basis(Vector3.FORWARD, rotBobZ)

# variable declaration
onready var origin = transform.origin
onready var basis = transform.basis
var viewBob: Vector3 = Vector3.ZERO
var rotBobX: float = 0
var rotBobZ: float = 0
var localOffset = {
	"view": Vector3.ZERO,
	"rotX": 0,
	"rotZ": 0,
}
var resetCounter = 0
var resetCounterGoal = 0
var leftFoot = false

# get components
onready var state = get_node("../../StateTracker")

# offset state definitions
var motions = {
	"reset": {
		"view": Vector3.ZERO,
		"rotX": 0,
		"rotZ": 0,
	},
	"strideLeft": {
		"view": Vector3(0, -0.2, 0),
		"rotX": 0,
		"rotZ": 0.015,
	},
	"strideRight": {
		"view": Vector3(0, -0.2, 0),
		"rotX": 0,
		"rotZ": -0.015,
	},
	"jump": {
		"view": Vector3.ZERO,
		"rotX": -0.1,
		"rotZ": 0,
	},
	"land": {
		"view": Vector3(0, -0.2, 0),
		"rotX": 0,
		"rotZ": 0,
	},
}

# function declarations
func flipFoot():
	leftFoot = !leftFoot

func resetCounter():
	resetCounter = 0

func setCounterGoal(goal):
	resetCounterGoal = goal

func processStepSignal():
	resetCounter()
	setCounterGoal(0.2)
	
	if leftFoot:
		localOffset = motions.strideLeft
	else:
		localOffset = motions.strideRight
	
	flipFoot()

func processJumpSignal():
	resetCounter()
	setCounterGoal(0.05)
	
	localOffset = motions.jump

func processLandSignal(velocity):
	resetCounter()
	setCounterGoal(0.125)
	
	localOffset = motions.land
	localOffset.view.y = clamp(velocity.y / 10, -3, 0)

func lerpBob(delta):
	resetCounter += delta
	if (resetCounter > resetCounterGoal):
		localOffset = motions.reset
	
	viewBob = lerp(viewBob, localOffset.view, 6 * delta)
	rotBobX = lerp(rotBobX, localOffset.rotX, 6 * delta)
	rotBobZ = lerp(rotBobZ, localOffset.rotZ, 6 * delta)

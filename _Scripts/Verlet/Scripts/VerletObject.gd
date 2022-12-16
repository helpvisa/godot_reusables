extends KinematicBody2D


# variable declarations
export var currentPosition: Vector2 = Vector2()
export var oldPosition: Vector2 = Vector2()
var velocity: Vector2 = Vector2()


# prepare on load
func _ready():
	currentPosition = global_transform.origin
	oldPosition = global_transform.origin


# perform the verlet physics integration
func _physics_process(delta):
	# perform the calculations
	velocity = (currentPosition - oldPosition) / delta

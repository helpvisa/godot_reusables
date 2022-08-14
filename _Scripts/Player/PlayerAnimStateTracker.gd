extends Node


################
# on script load
func _ready():
	pass

func _physics_process(_delta):
	tick += 1
	distanceThisTick = player.currentPosition.distance_to(player.positionLastTick)
	
	totalDistanceTravelled += distanceThisTick # distance travelled including time spent midair
	
	if player.is_on_floor():
		if !onFloor:
			#print("Landed!")
			emit_signal("landed", player.lastTickVelocity)
			onFloor = true
		
		distanceOnFoot += distanceThisTick # distance travelled while on the ground
		stepTrigger += distanceThisTick # and add this to the step trigger var too
	else:
		onFloor = false
	
	# display values in console
	#if (tick % 5 == 0):
		#print("Total distance travelled: ", totalDistanceTravelled)
		#print("Distance travelled on foot: ", distanceOnFoot)
	
	# trigger step after walking certain distance
	if stepTrigger > stepDistance:
		stepTrigger = 0
		#print("Stepped! ", tick)
		emit_signal("stepped")
		var stepSound = footstep.instance()
		stepSound.transform.origin = player.global_transform.origin
		stepSound.baseHiPass = 2000
		get_tree().get_root().add_child(stepSound)
	
	if abs(player.currentVelocity.x) > 0.1 || abs(player.currentVelocity.y) > 0.1 || abs(player.currentVelocity.z) > 0.1:
		#print("Moving ", tick)
		if !alreadyMoving and player.is_on_floor():
			emit_signal("first_step")
			var stepSound = footstep.instance()
			stepSound.transform.origin = player.global_transform.origin
			stepSound.baseHiPass = 2000
			get_tree().get_root().add_child(stepSound)
			alreadyMoving = true
		emit_signal("moving")
	else:
		stepTrigger = 0
		alreadyMoving = false


# variable declarations
var totalDistanceTravelled = 0
var distanceThisTick = 0
var distanceOnFoot = 0
var stepTrigger = 0 # variable that triggers step
var alreadyMoving = false
var onFloor = false
var tick = 0
export var stepDistance = 3
########## testing
export var footstep = preload("res://scenes/audio/AudioStreamPlayer3D.tscn")


# signals
signal stepped
signal first_step
signal landed
signal jumped
signal moving


# capture components
onready var player = get_parent()

# functions
func emitJump(inputs, states):
	if player.is_on_floor() and states.jump:
		emit_signal("jumped")

extends Node

# get components
@onready var player = get_parent()

# variable declarations
var totalDistanceTravelled = 0
var distanceThisTick = 0
var distanceOnFoot = 0
var stepTrigger = 0 # variable that triggers step
var alreadyMoving = false
var onFloor = false
var tick = 0
@export var stepDistance = 1
@export var footsteps: Array[AudioStreamOggVorbis]
@export var landing: AudioStreamOggVorbis

# signals
signal stopped
signal stepped
signal landed
signal jumped
signal moving


func _physics_process(_delta):
	tick += 1
	distanceThisTick = player.currentPosition.distance_to(player.positionLastTick)
	
	totalDistanceTravelled += distanceThisTick # distance travelled including time spent midair
	
	if player.is_on_floor():
		if !onFloor:
			emit_signal("landed", player.lastTickVelocity)
			if landing:
				var audioNode = AudioStreamPlayer3D.new()
				audioNode.stream = landing
				audioNode.autoplay = true
				audioNode.volume_db = -35 + abs(player.lastTickVelocity.y) * 3
				add_child(audioNode)
				audioNode.global_position = player.global_position - Vector3(0, 1, 0)
			onFloor = true
		
		distanceOnFoot += distanceThisTick # distance travelled while on the ground
		stepTrigger += distanceThisTick # and add this to the step trigger var too
	else:
		onFloor = false
		stepTrigger = 0
	
	# display values in console
	#if (tick % 5 == 0):
		#print("Total distance travelled: ", totalDistanceTravelled)
		#print("Distance travelled on foot: ", distanceOnFoot)
	
	# trigger step after walking certain distance
	if stepTrigger > stepDistance:
		stepTrigger = 0
		#print("Stepped! ", tick)
		emit_signal("stepped")
		if footsteps.size() > 0:
			var idx = randi_range(0, footsteps.size()-1)
			var stepSound = footsteps[idx]
			var audioNode = AudioStreamPlayer3D.new()
			audioNode.stream = stepSound
			audioNode.autoplay = true
			audioNode.volume_db = -30 + Vector2(player.velocity.x, player.velocity.z).length_squared()
			get_parent().add_child(audioNode)
			audioNode.global_position = player.global_position - Vector3(0, 1, 0)
	
	if abs(player.velocity.x) > 0.1 || abs(player.velocity.y) > 0.1 || abs(player.velocity.z) > 0.1:
		#print("Moving ", tick)
		if !alreadyMoving and player.is_on_floor():
			emit_signal("stepped")
			alreadyMoving = true
			if footsteps.size() > 0:
				var idx = randi_range(0, footsteps.size()-1)
				var stepSound = footsteps[idx]
				var audioNode = AudioStreamPlayer3D.new()
				audioNode.stream = stepSound
				audioNode.autoplay = true
				audioNode.volume_db = -30 + Vector2(player.velocity.x, player.velocity.z).length_squared()
				get_parent().add_child(audioNode)
				audioNode.global_position = player.global_position - Vector3(0, 1, 0)
		emit_signal("moving")
	else:
		stepTrigger = 0
		alreadyMoving = false


# custom functions
func emit_jump(inputs, states):
	if player.is_on_floor() and states.jump:
		emit_signal("jumped")

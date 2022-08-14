extends AudioStreamPlayer3D


# variable declarations
# just for testing purposes, this will be handled by an audio manager eventually
onready var player = get_node("../Spatial/PlayerTemplate")
##################################################
export var attenuationSpeed = 5
export(int, LAYERS_3D_PHYSICS) var layers
var busIdx
var busName
onready var reverbEffect = AudioEffectReverb.new()
export var baseHiPass = 0
export var destroyOnFinish = true # destroy when done playing?
export var playOnStart = true # play sound when it is created
# volume and falloff goals
var attenuationGoal = 20500
var baseVolume = 0
var volumeGoal = 0
# reverb goals
var roomSize = 0.2
var baseWetMix = 0.5
var wetMix = 0
var baseDelay = 25
var delay = 0
var timeElapsed = 0
var refreshGoal = 1/10 # how many seconds between audio raycast checks

# on load
func _ready():
	# create an audio bus to assign this file to (this will eventually be handeled within manager)
	var rng = RandomNumberGenerator.new() # random assignment number (will eventually use index)
	rng.randomize()
	# create a new audio bus, add it, and route it through to Ambient bus
	AudioServer.add_bus()
	busIdx = AudioServer.get_bus_count() - 1
	busName = "NewSnd" + str(rng.randf_range(0,1000))
	AudioServer.set_bus_name(busIdx, busName)
	bus = busName
	AudioServer.set_bus_send(busIdx, "Ambient")
	
	# prep
	baseVolume = unit_db
	checkReverb()
	traceFrom(player.global_transform.origin)
	# add reverb effect to audio source
	reverbEffect.predelay_feedback = 0
	AudioServer.add_bus_effect(busIdx, reverbEffect, 0)
	reverbEffect = AudioServer.get_bus_effect(busIdx, 0)
	
	# set initial values
	attenuation_filter_cutoff_hz = attenuationGoal
	unit_db = volumeGoal
	reverbEffect.room_size = roomSize
	reverbEffect.wet = wetMix
	reverbEffect.predelay_msec = delay
	reverbEffect.hipass = baseHiPass
	
	# should it start playing now?
	if playOnStart:
		playing = true

# update
func _physics_process(delta):
	# check if updates should be performed
	timeElapsed += delta
	if (timeElapsed > refreshGoal):
		timeElapsed = 0
		checkReverb()
		traceFrom(player.global_transform.origin)
	
	if !playing and destroyOnFinish:
		queue_free()

# free update
func _process(delta):
	# interpolate
	lerpAttenuation(delta)
	lerpReverb(delta)

# function declarations
func traceFrom(from):
	var trace = performRaycast(from, global_transform.origin)
	if (trace):
		attenuationGoal = clamp(20500 - (trace.position.distance_to(global_transform.origin) * 250), 1200, 20500)
		volumeGoal = baseVolume - sqrt(trace.position.distance_to(global_transform.origin) / 2)
	else:
		attenuationGoal = clamp(20500 - (player.global_transform.origin.distance_to(global_transform.origin) * 100), 1200, 20500)
		volumeGoal = baseVolume
	# alter reverb wetness based on player distance
	wetMix = clamp(baseWetMix + (player.global_transform.origin.distance_to(global_transform.origin) / 100), 0, 1)
	delay = baseDelay + player.global_transform.origin.distance_to(global_transform.origin) * 10

func lerpAttenuation(delta):
	# rolloff
	attenuation_filter_cutoff_hz = \
	lerp(attenuation_filter_cutoff_hz, attenuationGoal, delta * attenuationSpeed)
	
	# volume (muffled by walls between)
	unit_db = \
	lerp(unit_db, volumeGoal, delta * attenuationSpeed)

func checkReverb():
	# perform a series of raycasts to evaluate room size
	# cast forward
	var forward = performRaycast(global_transform.origin, transform.basis.z * 100)
	# cast backward
	var backward = performRaycast(global_transform.origin, transform.basis.z * -100)
	# cast right
	var right = performRaycast(global_transform.origin, transform.basis.x * 100)
	# cast left
	var left = performRaycast(global_transform.origin, transform.basis.x * -100)
	# cast up
	var up = performRaycast(global_transform.origin, transform.basis.y * 100)
	# cast down
	var down = performRaycast(global_transform.origin, transform.basis.y * -100)
	
	# calculate average distance to hit points
	var distance = 0
	if (forward):
		distance = forward.position.distance_to(global_transform.origin)
	if (backward):
		distance += backward.position.distance_to(global_transform.origin)
	if (right):
		distance += right.position.distance_to(global_transform.origin)
	if (left):
		distance += left.position.distance_to(global_transform.origin)
	if (up):
		distance += up.position.distance_to(global_transform.origin)
	if (down):
		distance += down.position.distance_to(global_transform.origin)
	distance /= 200
	#print(distance)
	
	roomSize = clamp(distance, 0, 1)
	# determine base wetness
	baseWetMix = clamp(distance, 0, 1)
	baseDelay = distance * 50
	#print(reverbEffect.predelay_msec)

func lerpReverb(delta):
	reverbEffect.room_size = lerp(reverbEffect.room_size, roomSize, delta * attenuationSpeed)
	reverbEffect.wet = lerp(reverbEffect.wet, wetMix, delta * attenuationSpeed)
	reverbEffect.predelay_msec = lerp(reverbEffect.predelay_msec, delay, delta * attenuationSpeed)

func performRaycast(from, to):
	var space = get_world().direct_space_state
	# do raycast
	# format is: from, to, exclude (array), collisionmask, collide_with_bodies (true), collide_with_areas (false)
	var result = space.intersect_ray(from, to, [], layers)
	return result

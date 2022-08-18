extends AudioStreamPlayer3D


# variable declarations
var player
var childEmitter: AudioStreamPlayer3D
onready var cscript = load("res://scripts/Audio/Custom3DAudio.gd")
export var attenuationSpeed = 5
export(int, LAYERS_3D_PHYSICS) var layers
var busIdx
var busName
var reverbEffect
export var baseVolume = 0
export var audioRange = 100
export var baseHiPass = 0
export var destroyOnFinish = true # destroy when done playing?
export var playOnStart = true # play sound when it is created
export var debug: bool = false # draw
# store original position
var originalPosition = Vector3()
var positionGoal = Vector3()
# volume and falloff goals
var attenuationGoal = 20500
var attenuationDbGoal = -24
var childAttenuationGoal = 20500
var volumeGoal = 0
var childVolumeGoal = 0
# reverb goals
var roomSize = 0.2
var baseWetMix = 0.5
var wetMix = 0
var baseDelay = 25
var delay = 0

# on load
func _ready():
	# debug
	if debug:
		var testMat = SpatialMaterial.new()
		testMat.flags_no_depth_test = true
		testMat.render_priority = 1
		var childVisual = CSGSphere.new()
		childVisual.radius = 0.5
		childVisual.set_material(testMat)
		childEmitter.add_child(childVisual)

# update
func _physics_process(delta):
	if !playing and destroyOnFinish:
		queue_free()

# free update
func _process(delta):
	# interpolate
	lerpPosition(delta)
	lerpAttenuation(delta)
	lerpReverb(delta)

# function declarations
func lerpPosition(delta):
	if (childEmitter):
		childEmitter.global_transform.origin = lerp(childEmitter.global_transform.origin, positionGoal, delta * (attenuationSpeed))

func lerpAttenuation(delta):
	# rolloff
	attenuation_filter_cutoff_hz = \
	lerp(attenuation_filter_cutoff_hz, attenuationGoal, delta * attenuationSpeed)
	attenuation_filter_db = \
	lerp(attenuation_filter_db, attenuationDbGoal, delta * attenuationSpeed)
	
	# volume (muffled by walls between)
	unit_db = \
	lerp(unit_db, volumeGoal, delta * attenuationSpeed)
	
	# now for subemitter
	if (childEmitter):
		childEmitter.attenuation_filter_cutoff_hz = \
		lerp(childEmitter.attenuation_filter_cutoff_hz, childAttenuationGoal, delta * attenuationSpeed)
		childEmitter.unit_db = \
		lerp(childEmitter.unit_db, childVolumeGoal, delta * attenuationSpeed)

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

# setup function
func _setup():
	# disable attenuation
	set_attenuation_model(3)
	# store original placed position
	originalPosition = global_transform.origin
	positionGoal = originalPosition
	
	# create a new audio bus, add it, and route it through to Ambient bus
	AudioServer.add_bus()
	busIdx = AudioServer.get_bus_count() - 1
	busName = "NewSnd" + str(busIdx)
	AudioServer.set_bus_name(busIdx, busName)
	bus = busName
	AudioServer.set_bus_send(busIdx, "Ambient")
	
	# prep
	unit_db = -80
	reverbEffect = AudioEffectReverb.new()
	reverbEffect.predelay_feedback = 0
	AudioServer.add_bus_effect(busIdx, reverbEffect, 0)
	reverbEffect = AudioServer.get_bus_effect(busIdx, 0)
	
	# set initial values
	reverbEffect.hipass = baseHiPass
	
	# should it start playing now?
	if playOnStart:
		playing = true
	
	# create child emitter
	childEmitter = AudioStreamPlayer3D.new()
	childEmitter.stream = stream
	childEmitter.unit_db = -80
	childEmitter.bus = busName
	childEmitter.set_attenuation_model(3)
	if (playing):
		childEmitter.playing = true
	add_child(childEmitter)

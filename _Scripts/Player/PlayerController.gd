extends CharacterBody3D

# variable declarations
@export var camera: Camera3D

# physics parameters
@export var moveSpeed = 65 # player's base movespeed
@export_range(0, 1) var airInfluence: float = 0.1 # amount of movement influence player retains in midair
@export var groundFriction = 10 # ground friction
@export var airFriction = 1.3 # air friction
@export var weight = 1 # player's weight
@export var jumpHeight = 5 # player's jumpheight
@export var coyoteTime = 0.25 # number of seconds a jump is still effective after leaving the ground
@export var gravity = 9.8 # effect of gravity on player

# look options
@export var minLookAngle = -80 # angle to which the player can look down
@export var maxLookAngle = 80 # angle to which the player can look up
@export var lookSensitivity = 1000 # mouselook sensitivity
@export var controllerSensHor = 250 # controller hoirzontal look sensitivity
@export var controllerSensVer = 150 # controller vertical look sensitivity

# control settings (replace with capture from upper-level input manager which modifies this dict)
@export var useExternalInput = false
var inputs = {
	"movement": Vector2(), # store input as Vector2 for future controller support
	"jump": false, # single key actions stored as bool flags
	"mouseDelta": Vector2(),
	"controllerLook": Vector2(),
}

# vectors and tracking variables
var playerInput = Vector2() # store input in 2d vector (forward/backward and left/right)
var lastTickVelocity = Vector3() # store player's velocity from previous update
var internalMouseDelta = Vector2() # store mouse movement per tick
var coyoteTimer = 0
var currentPosition = Vector3()
var positionLastTick = Vector3()

# state dictionary containing player state info
var movementStates = {
	"jumped": false,
	"walking": false,
}


func _ready():
	# hide and lock if internal input manager enabled
	if !useExternalInput:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# store current position
	positionLastTick = global_transform.origin
	currentPosition = global_transform.origin
	
	# set velocity to zero
	velocity = Vector3.ZERO


func _input(event):
	if event is InputEventMouseMotion and !useExternalInput:
		internalMouseDelta = event.relative


func _process(delta):
	if !useExternalInput:
		internal_input(delta) # use built-in input management
	process_input(delta) # process input dict


func _physics_process(delta):
	# reset player states
	movementStates.walking = false
	
	# capture last frame velocity and position and store it; update current position
	lastTickVelocity = velocity
	positionLastTick = currentPosition
	currentPosition = global_transform.origin
	
	# acquire forward and right directional vectors
	var playerForward = global_transform.basis.z
	var playerRight = global_transform.basis.x
	# use these vectors to get the relative forward player direction
	var relativeDirection = (playerForward * playerInput.y + playerRight * playerInput.x)
	
	# check if on floor
	if is_on_floor():
		# reset coyote timer
		coyoteTimer = 0
		# update current velocity based on inputs, full ground influence
		velocity += ((relativeDirection * moveSpeed) / weight) * delta
		# apply ground friction
		velocity.x -= (velocity.x * groundFriction) * delta
		velocity.z -= (velocity.z * groundFriction) * delta
	else:
		# increment coyote timer
		coyoteTimer += 1 * delta
		# update current velocity based on inputs, minimal air influence
		velocity += ((relativeDirection * moveSpeed * airInfluence) / weight) * delta
		# apply air friction
		velocity.x -= (velocity.x * airFriction) * delta
		velocity.z -= (velocity.z * airFriction) * delta
	
	# jump logic (checks if is_on_ground or if coyoteTimer is less than allowed coyote time)
	if movementStates.jumped and (is_on_floor() or coyoteTimer < coyoteTime):
		velocity.y = jumpHeight
		coyoteTimer = coyoteTime
	
	# apply gravity (perpendicular to floor to stop sliding)
	#var gravityResistance = get_floor_normal() if is_on_floor() else Vector3.UP
	#velocity -= (gravityResistance * (gravity * delta))
	velocity.y -= gravity * delta
		
	# reset jump state
	movementStates.jumped = false
	
	move_and_slide()


# custom functions
# function which handles baked-in input
func internal_input(delta):
	# handle directional movement
	playerInput = Vector2() # blank input vector
	inputs.movement.y -= 1 * Input.get_action_strength("move_forward")
	inputs.movement.y += 1 * Input.get_action_strength("move_backward")
	inputs.movement.x -= 1 * Input.get_action_strength("move_left")
	inputs.movement.x += 1 * Input.get_action_strength("move_right")
	
	# controller camera look
	inputs.controllerLook = Vector2.ZERO
	inputs.controllerLook.x -= Input.get_action_strength("look_left") * controllerSensHor
	inputs.controllerLook.x += Input.get_action_strength("look_right") * controllerSensHor
	inputs.controllerLook.y += Input.get_action_strength("look_down") * controllerSensVer
	inputs.controllerLook.y -= Input.get_action_strength("look_up") * controllerSensVer
	
	if Input.is_action_just_pressed("jump"):
		inputs.jump = true
	
	# set mouse delta
	inputs.mouseDelta = internalMouseDelta * lookSensitivity * delta
	internalMouseDelta = Vector2()


# function to handle use of input managers
func process_input(delta):
	# handle directional movement
	playerInput = inputs.movement
		
	# normalize input vector if necessary
	if playerInput.length_squared() > 1:
		playerInput = playerInput.normalized()
	
	if inputs.jump:
		movementStates.jumped = true
	
	# handle player rotation + camera movement
	rotation_degrees.y -= inputs.mouseDelta.x * delta # body left/right
	rotation_degrees.y -= inputs.controllerLook.x * delta
	camera.playerRot -= inputs.mouseDelta.y * delta # eyes up/down
	camera.playerRot -= inputs.controllerLook.y * delta
	camera.playerRot = clamp(camera.playerRot, minLookAngle, maxLookAngle) # up/down clamp
	
	reset_input_dict() # reset input flags


# handles resetting the values of the inputs dict
func reset_input_dict():
	inputs.movement = Vector2()
	inputs.mouseDelta = Vector2()
	inputs.jump = false

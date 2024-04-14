extends CharacterBody3D

# variable declarations
@export var camera: Camera3D

# physics parameters
@export var moveSpeed = 25 # player's base movespeed
@export_range(0, 1) var backstepSpeedMultiplier = 0.6 # percentage of max speed player can move in reverse
@export_range(0, 1) var sidestepSpeedMultiplier = 0.8 # same as above but for strafing
@export_range(0, 1) var runCutoff = 0.6 # when to stop sprinting
@export var runMultiplier = 1.8
@export_range(0, 1) var airInfluence: float = 0.1 # amount of movement player retains in midair
@export var groundFriction = 10 # ground friction
@export var airFriction = 1.3 # air friction
@export var weight = 1 # player's weight
@export var jumpHeight: float = 1.2 # player's jumpheight
@export var jumpModTime = 40 # number of ticks during which a jump can be modulated
@export var coyoteTime = 0.25 # number of seconds a jump would still work after leaving the ground
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
	"movement": Vector2.ZERO, # store input as Vector2 for future controller support
	"jump": false, # single key actions stored as bool flags
	"run": false, # run modifier
	"toggleRun": false, # toggleable version
	"mouseDelta": Vector2.ZERO,
	"controllerLook": Vector2.ZERO,
}

# vectors and tracking variables
var playerInput = Vector2.ZERO # store input in 2d vector (forward/backward and left/right)
var lastTickVelocity = Vector3.ZERO # store player's velocity from previous update
var internalMouseDelta = Vector2.ZERO # store mouse movement per tick
var coyoteTimer = 0
var jumpTimer = 0
var currentPosition = Vector3.ZERO
var positionLastTick = Vector3.ZERO

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
	# disable toggleable run if not moving
	if Vector2(velocity.x, velocity.z).length_squared() < 2 or playerInput.y > -runCutoff:
		inputs.toggleRun = false
		inputs.run = false
	elif inputs.toggleRun:
		inputs.run = true
	
	# capture last frame velocity and position and store it; update current position
	lastTickVelocity = velocity
	positionLastTick = currentPosition
	currentPosition = global_transform.origin
	
	# acquire forward and right directional vectors
	var playerForward = global_transform.basis.z
	var playerRight = global_transform.basis.x
	# use these vectors to get the relative forward player direction
	var relativeDirection = (playerForward * playerInput.y + playerRight * playerInput.x)
	
	# acquire run speed multiplier
	var runApply = 1
	if inputs.run:
		runApply = runMultiplier
	
	# check if on floor
	if is_on_floor():
		# reset coyote timer
		coyoteTimer = 0
		jumpTimer = 0
		# update current velocity based on inputs, full ground influence
		velocity += ((relativeDirection * moveSpeed * runApply) / weight) * delta
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
	if jumpTimer > 0 and jumpTimer < jumpModTime:
		jumpTimer += 1
		if inputs.jump:
			velocity.y += jumpHeight / jumpTimer
	if movementStates.jumped and (is_on_floor() or coyoteTimer < coyoteTime):
		velocity.y = jumpHeight
		coyoteTimer = coyoteTime
		jumpTimer += 1
	
	# apply gravity and move
	velocity.y -= gravity * delta
	move_and_slide()


# custom functions
# function which handles baked-in input
func internal_input(delta):
	# handle directional movement
	playerInput = Vector2.ZERO # blank input vector
	inputs.movement.y -= 1 * Input.get_action_strength("move_forward")
	inputs.movement.y += backstepSpeedMultiplier * Input.get_action_strength("move_backward")
	inputs.movement.x -= sidestepSpeedMultiplier * Input.get_action_strength("move_left")
	inputs.movement.x += sidestepSpeedMultiplier * Input.get_action_strength("move_right")
	
	# controller camera look
	inputs.controllerLook = Vector2.ZERO
	inputs.controllerLook.x -= Input.get_action_strength("look_left") * controllerSensHor
	inputs.controllerLook.x += Input.get_action_strength("look_right") * controllerSensHor
	inputs.controllerLook.y += Input.get_action_strength("look_down") * controllerSensVer
	inputs.controllerLook.y -= Input.get_action_strength("look_up") * controllerSensVer
	
	# modifiers
	if Input.is_action_pressed("jump"):
		inputs.jump = true
	else:
		inputs.jump = false
	
	if Input.is_action_pressed("run_hold"):
		inputs.run = true
	else:
		inputs.run = false
	
	# toggles
	if Input.is_action_just_pressed("run_toggle"):
		inputs.toggleRun = !inputs.run
	
	# set mouse delta for mouselook
	inputs.mouseDelta = internalMouseDelta * lookSensitivity * delta
	internalMouseDelta = Vector2.ZERO


# function to handle use of input managers
func process_input(delta):
	# handle directional movement
	playerInput = inputs.movement
		
	# normalize input vector if necessary
	if playerInput.length_squared() > 1:
		playerInput = playerInput.normalized()
	
	if inputs.jump:
		movementStates.jumped = true
	else:
		movementStates.jumped = false
	
	# handle player rotation + camera movement
	rotation_degrees.y -= inputs.mouseDelta.x * delta # body left/right
	rotation_degrees.y -= inputs.controllerLook.x * delta
	camera.playerRot -= inputs.mouseDelta.y * delta # eyes up/down
	camera.playerRot -= inputs.controllerLook.y * delta
	camera.playerRot = clamp(camera.playerRot, minLookAngle, maxLookAngle) # up/down clamp
	
	reset_input_dict() # reset input flags


# handles resetting the values of the inputs dict, excepting modifiers / toggles like run and jump
func reset_input_dict():
	inputs.movement = Vector2.ZERO
	inputs.mouseDelta = Vector2.ZERO
	inputs.controllerLook = Vector2.ZERO

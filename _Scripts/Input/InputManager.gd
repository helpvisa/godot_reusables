extends Node

###########
# main code
# execute on script load
func _ready():
	# find player node
	player = get_tree().get_root().find_node(playerName, true, false)
	# connect player node to this inputmanager
	self.connect("sendInput", player, "parseExternalInput")
	self.connect("sendInput", player.get_node("StateTracker"), "emitJump")
	
	if (managerStates.currentlyControlling == "player"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# get the mouse delta
func _input(event):
	if event is InputEventMouseMotion:
		inputs.lookVector = event.relative * mouseSensitivity


# process input and send this info to the player controller
func _process(delta):
	# acquire their current state
	processKeyboard()
	#processController(delta)
	
	# emit input signal if player is being controlled
	if managerStates.currentlyControlling == "player":
		emit_signal("sendInput", inputs, states)
	
	# blank the inputs
	resetVars()


###########
# functions
func resetVars():
	# reset vectors
	inputs.movementVector = Vector2()
	inputs.lookVector = Vector2()
	# reset vars in dict
	states.jump = false

# process keyboard inputs
func processKeyboard():
	# handle directional movement
	if Input.is_action_pressed(moveForward):
		inputs.movementVector.y += 1
	if Input.is_action_pressed(moveBackward):
		inputs.movementVector.y -= 1
	if Input.is_action_pressed(moveLeft):
		inputs.movementVector.x += 1
	if Input.is_action_pressed(moveRight):
		inputs.movementVector.x -= 1
	
	# handle jumping
	if Input.is_action_just_pressed(jump):
		states.jump = true
	
	# handle UI inputs
	if Input.is_action_just_pressed(menuEscape):
		if managerStates.currentlyControlling == "player":
			managerStates.currentlyControlling = "menu"
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			managerStates.currentlyControlling = "player"
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# process controller inputs
func processController(delta):
	# handle directional movement
	inputs.movementVector += Input.get_vector("controller_leftstick_right", "controller_leftstick_left", "controller_leftstick_down", "controller_leftstick_up")
	# handle right stick look
	var controllerAim = Vector2()
	controllerAim = Input.get_vector("controller_rightstick_left", "controller_rightstick_right", "controller_rightstick_up", "controller_rightstick_down")
	
	if controllerAim == Vector2.ZERO:
		currentControllerAcceleration = Vector2.ZERO # reset acceleration if no input
	else:
		if abs(controllerAim.x) > 0.5:
			currentControllerAcceleration.x += (controllerAim.x * controllerAcceleration) * delta # add acceleration
		if abs(controllerAim.y) > 0.5:
			currentControllerAcceleration.y += (controllerAim.y * controllerAcceleration) * delta
	currentControllerAcceleration.x = clamp(currentControllerAcceleration.x, -3, 3) # clamp acceleration
	currentControllerAcceleration.y = clamp(currentControllerAcceleration.y, -3, 3)
	
	inputs.lookVector += (controllerAim + currentControllerAcceleration) * controllerSensitivity
	
	if Input.is_action_just_pressed("controller_a"):
		states.jump = true
	 

###############
# variables
var inputs = {
	"movementVector": Vector2(),
	"lookVector": Vector2(),
}
var states = {
	"jump": false,
}
var managerStates = {
	"currentlyControlling": "player",
}


# key settings (set which project input map keys to assign to input manager vars)
export var mouseSensitivity = 3.5
export var controllerSensitivity = 150
export var controllerAcceleration = 3.5
export var currentControllerAcceleration = Vector2.ZERO
export var moveForward = "move_forward"
export var moveBackward = "move_backward"
export var moveLeft = "move_left"
export var moveRight = "move_right"
export var jump = "jump"
export var menuEscape = "ui_cancel"


# signal definitions
signal sendInput


################
# get components
export var playerName = "PlayerTemplate"
var player

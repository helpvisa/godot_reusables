extends Spatial


# variable declarations
var audioSources = []
var player
var soundNodes
export var updatesPerSecond: int = 20
var framerate: float = 1 / updatesPerSecond
var updateTimer: float = 0
var astar
var pointRenderer

# on script load
func _ready():
	# get components
	findNodes(get_tree().get_root(), "AudioStreamPlayer3D", audioSources)
	var playerArray = []
	findByName(get_tree().get_root(), "PlayerTemplate", playerArray)
	var pointsObjectArray = []
	findByName(get_tree().get_root(), "SoundNodes", pointsObjectArray)
	soundNodes = pointsObjectArray[0]
	
	player = playerArray[0]
	for source in audioSources:
		source.player = player
		source._setup()
	
	# setup astar
	astar = AStar.new()
	
	# add points
	if soundNodes:
		# add
		for point in soundNodes.points:
			astar.add_point(point.id, point.position, 1)
		
		# connect
		for point in soundNodes.points:
			for c in point.connections:
				astar.connect_points(point.id, c, true)

# update
func _physics_process(delta):
	updateTimer += delta
		
	if astar.get_point_count() > 0 and updateTimer > framerate:
		updateTimer = 0
		for sound in audioSources:
			var distanceOnPath = 0
			var finalPos = sound.originalPosition
			var volume = 0
			var subtractiveVolume = 0
			var distanceFromSound = sound.originalPosition.distance_to(player.global_transform.origin)
			if distanceFromSound < sound.audioRange:
				var pathToSound = getSoundPath(sound.originalPosition, player.global_transform.origin)
				for i in pathToSound.size():
					finalPos = pathToSound[i]
					var distanceToAdd = 0
					var firstCast: bool = false
					var hit
					if i < 1:
						finalPos = sound.originalPosition
						hit = performRaycast(sound.originalPosition, player.global_transform.origin)
						firstCast = true
					else:
						distanceToAdd = pathToSound[i-1].distance_to(pathToSound[i])
						hit = performRaycast(pathToSound[i], player.global_transform.origin)
					if hit and hit.collider.name == player.name:
						if firstCast:
							sound.positionGoal = sound.originalPosition
						else:
							var dir = pathToSound[i] - player.global_transform.origin
							var newSoundPos = pathToSound[i] + dir
							sound.roomSize = clamp(0.01 * distanceOnPath, 0, 1)
							sound.wetMix = clamp(0.015 * distanceOnPath, 0, 1)
							sound.baseDelay = 10 * distanceOnPath
							sound.positionGoal = newSoundPos
						distanceOnPath += distanceToAdd
						break
					distanceOnPath += distanceToAdd
				distanceOnPath += finalPos.distance_to(player.global_transform.origin)
				volume = calcVolume(distanceOnPath)
				volume += volume * clamp(distanceFromSound / sound.audioRange, 0, 1)
				subtractiveVolume = calcVolume(finalPos.distance_to(sound.originalPosition))
			else:
				volume = -80
			sound.childVolumeGoal = volume + sound.baseVolume
			sound.volumeGoal = sound.childVolumeGoal + subtractiveVolume
			sound.childAttenuationGoal = clamp(20500 - distanceOnPath * 100, 3200, 20500)
			var atten = performRaycast(player.global_transform.origin, sound.originalPosition)
			if atten:
				var distance = atten.position.distance_to(sound.originalPosition)
				sound.attenuationGoal = clamp(20500 - distance * 250, 3200, 20500)
			else:
				sound.attenuationGoal = 20500


# function declarations
# find nodes by class
func findNodes(node: Node, className: String, result: Array) -> void:
	if node.is_class(className):
		result.push_back(node)
	for child in node.get_children():
		findNodes(child, className, result)

# find player
func findByName(node: Node, name: String, result: Array):
	if node.get_name() == name:
		result.push_back(node)
	else:
		for child in node.get_children():
			findByName(child, name, result)

# find where to place audio
func getSoundPath(from, to):
	var from_point = astar.get_closest_point(from)
	var to_point = astar.get_closest_point(to)
	var path = astar.get_point_path(from_point, to_point)
	return path

func calcVolume(distance):
	var volume = 0
	if distance != 0:
		volume = 1 / distance
		volume = linear2db(volume)
	volume = clamp(volume, -80, 0)
	return volume

# perform a raycast from and to a point
func performRaycast(from, to):
	var space = get_world().direct_space_state
	# do raycast
	# format is: from, to, exclude (array), collisionmask, collide_with_bodies (true), collide_with_areas (false)
	var result = space.intersect_ray(from, to)
	return result

tool
extends Node

# variable declaration
# button
export var grabNodes: bool = false
export var updateVisual: bool = false
export var seeInGame: bool = false
var id_counter: int = 0
var sceneNodes = []
export var points = []
var geo
var mat

func _ready():
	if seeInGame:
		instantiate_geo()

func _process(_delta):
	if Engine.editor_hint:
		if updateVisual:
			updateVisual = false
			instantiate_geo()
		
		if grabNodes:
			# reset button and id
			grabNodes = false
			id_counter = 0
			points = []
			
			# get node positions
			fetchNodePositions()
			for node in sceneNodes:
				var newPoint = {
					"position": node.global_transform.origin,
					"id": id_counter,
					"connections": []
				}
				points.push_back(newPoint)
				id_counter += 1
	elif seeInGame:
		init_geo()

# function declaration
# get child nodes
func fetchNodePositions():
	sceneNodes = get_children()

# draw child nodes
func instantiate_geo():
	mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	mat.vertex_color_use_as_albedo = true
	mat.flags_use_point_size = true
	mat.params_point_size = 12
	
	if geo == null :
		geo = $geo
		if geo == null :
			print("new geo")
			geo = ImmediateGeometry.new()
			geo.set_name("geo")
			add_child(geo)
			init_geo()
		else :
			init_geo()
	else:
		init_geo()

func init_geo():
	geo.clear()
	geo.begin(0)
	geo.set_material_override(mat)
	geo.set_color(Color(1, 0, 0))
	for p in points:
		geo.add_vertex(p.position)
	geo.end()
	geo.begin(1)
	for p in points:
		if p.connections:
			for c in p.connections:
				geo.add_vertex(p.position)
				geo.add_vertex(points[c].position)
	geo.end()

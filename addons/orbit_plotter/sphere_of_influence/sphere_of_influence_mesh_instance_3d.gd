@tool
extends MeshInstance3D
class_name SphereOfInfluenceMeshInstance3D


const SoiMesh := preload("res://addons/orbit_plotter/sphere_of_influence/new_sphere_mesh.tres")


@export var radius := 10.0:
	set(value):
		radius = value
		scale = Vector3.ONE * radius * 2.0
		_compute_fade_distance()

@export_range(0.0, 1.0) var proximity_fade := 0.9:
	set(value):
		proximity_fade = value
		_compute_fade_distance()


var _proximity_fade_distance
var _material: ShaderMaterial


func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = SoiMesh.duplicate(true)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var distance_to_camera := global_position.distance_squared_to(camera.global_position)
		var fade := smoothstep(_proximity_fade_distance, radius ** 2.0, distance_to_camera)
		transparency = 1.0 - fade
		visible = not is_zero_approx(fade)


func _compute_fade_distance() -> void:
	_proximity_fade_distance = (radius * proximity_fade) ** 2.0

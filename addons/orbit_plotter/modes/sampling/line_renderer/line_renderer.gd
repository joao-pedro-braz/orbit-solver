@tool
extends MultiMeshInstance3D


const LineRendererMultiMesh := preload("res://addons/orbit_plotter/modes/sampling/line_renderer/line_renderer.multimesh")


@export var curve: Curve3D:
	set(value):
		curve = value
		if _is_ready:
			_semaphore.post()
		
		curve.changed.connect(func(): _semaphore.post())


@export var material: ShaderMaterial:
	set(value):
		material = value
		if _is_ready:
			_semaphore.post()
		
		material.changed.connect(func(): _semaphore.post())
	get:
		if not material:
			material = LineRendererMultiMesh.mesh.material
		return material


@onready var _is_ready := true

var _thread := Thread.new()
var _semaphore := Semaphore.new()
var _exit_thread := false
var _notifier := VisibleOnScreenNotifier3D.new()


func _init() -> void:
	multimesh = LineRendererMultiMesh.duplicate()
	multimesh.mesh.material = material
	
	_thread.start(
		func():
			while true:
				_semaphore.wait()
				if _exit_thread:
					return
				_build_mesh()
	)


func _ready() -> void:
	if curve:
		_semaphore.post()

	add_child(_notifier)
	_notifier.screen_entered.connect(func(): multimesh.visible_instance_count = -1)
	_notifier.screen_exited.connect(func(): multimesh.visible_instance_count = 0)


func _exit_tree() -> void:
	_exit_thread = true
	_semaphore.post()
	_thread.wait_to_finish()


func _build_mesh() -> void:
	multimesh.instance_count = curve.point_count - 1
	var offset := 0.0
	var aabb := AABB()
	for i in multimesh.instance_count:
		var point := curve.get_point_position(i)
		var next_point := curve.get_point_position(i + 1)
		
		var transform = Transform3D()
		transform = transform.translated(point)
		transform = transform.looking_at(next_point)
		transform = transform.rotated_local(Vector3.RIGHT, -PI / 2.0)
		transform = transform.translated_local(Vector3(0.0, point.distance_to(next_point) * 0.5, 0.0))
		transform = transform.scaled_local(Vector3(1.0, point.distance_to(next_point) * 2.05, 1.0))
		multimesh.set_instance_transform(i, transform)
		var position: Vector3 = transform * Vector3.ZERO
		aabb = aabb.expand(position)
		position = to_global(position)
		multimesh.set_instance_custom_data(i, Color(position.x, position.y, position.z))
	
	_notifier.aabb = aabb

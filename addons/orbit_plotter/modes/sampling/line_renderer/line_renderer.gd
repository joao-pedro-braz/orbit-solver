@tool
extends MeshInstance3D


const DefaultMaterial := preload("res://addons/orbit_plotter/modes/sampling/line_renderer/default.material")


@export var curve: PackedVector3Array:
	set(value):
		curve = value
		if _is_ready:
			_mesh_builder_semaphore.post()


@export var material: StandardMaterial3D:
	set(value):
		material = value
		if _is_ready:
			_mesh_builder_semaphore.post()

		material.changed.connect(func(): _mesh_builder_semaphore.post())
	get:
		if not material:
			material = DefaultMaterial
		return material


@onready var _is_ready := true

var _mesh_builder_thread := Thread.new()
var _mesh_builder_semaphore := Semaphore.new()
var _exit_mesh_builder_thread := false
var _notifier := VisibleOnScreenNotifier3D.new()


func _init() -> void:
	mesh = ImmediateMesh.new()
	
	_mesh_builder_thread.start(
		func():
			while true:
				_mesh_builder_semaphore.wait()
				if _exit_mesh_builder_thread:
					return
				_instance_mesh()
	)


func _ready() -> void:
	if curve:
		_mesh_builder_semaphore.post()

	add_child(_notifier)


func _exit_tree() -> void:
	_exit_mesh_builder_thread = true
	_mesh_builder_semaphore.post()
	_mesh_builder_thread.wait_to_finish()


func _instance_mesh() -> void:
	if curve.size() <= 1:
		return
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for i in curve.size():
		var point := curve[i]
		var next_point := curve[(i + 1) % curve.size()]
		if point.is_equal_approx(next_point):
			continue
		mesh.surface_add_vertex(point)
	mesh.surface_end()

@tool
extends Camera3D
var source_camera:Camera3D

func _ready() -> void:
	#fixes a bug where the camera does not initalize in editor every time
	projection = Camera3D.PROJECTION_PERSPECTIVE

func _process(_delta: float) -> void:
	if source_camera == null:
		source_camera = CSGPlusGlobals.controller.scene_viewport.get_camera_3d()
	global_transform = source_camera.global_transform

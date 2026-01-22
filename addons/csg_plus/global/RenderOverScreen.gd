@tool
extends MeshInstance2D

var viewport:SubViewport

func _ready() -> void:
	viewport = CSGPlusGlobals.controller.scene_viewport

func _process(_delta: float) -> void:
	scale = viewport.size
	position = scale/2
	scale.y = -scale.y
	scale = scale * 1.095

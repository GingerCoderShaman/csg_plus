@tool
extends SubViewport

var viewport:SubViewport

func _ready() -> void:
	viewport = CSGPlusGlobals.controller.scene_viewport

func _process(_delta: float) -> void:
	size = viewport.size
	size_2d_override = viewport.size

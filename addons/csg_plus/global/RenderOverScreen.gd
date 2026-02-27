@tool
extends MeshInstance2D

var viewport:Viewport

func _ready() -> void:
	viewport = CSGPlusGlobals.controller.scene_viewport

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		scale = viewport.size
		position = scale/2
		scale.y = -scale.y
		scale = scale * 1.095
	else: #TODO related to stretch issue, will need to add a detector 
		#for this if I plan to make character selector a plugin, 
		#rather then game
		var scale_adjusted = Vector2(viewport.size)
		var scale_original = Vector2(1152, 648) #TODO scale of default window, this will need to be sysmatically grabbed
		var factor = scale_adjusted/scale_original

		if factor.x > factor.y:
			factor /= factor.y
		else:
			factor /= factor.x

		position = scale_original/2*factor
		scale = scale_original * factor / 1.095
		scale.y = -scale.y

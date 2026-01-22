@tool
class_name MaterialRendererData

var callback = null
var materials = []

func _init(callback, materials) -> void:
	self.callback = callback
	self.materials = materials

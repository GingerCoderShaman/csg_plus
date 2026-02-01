@tool
extends Panel

var viewport:SubViewport
@onready var text_edit:TextEdit = $"ErrorPanelText"

func _ready() -> void:
	viewport = CSGPlusGlobals.controller.scene_viewport

func _process(delta: float) -> void:
	if modulate.a > 0:
		size.x = viewport.size.x * .8
		position.x = viewport.size.x * .1
		text_edit.size.x = size.x
		modulate.a -= delta * .2

func alert(text:String):
	text_edit.text = text
	modulate.a = 1

func alert_if_empty(text:String):
	if modulate.a < 0 || text_edit.text == text:
		modulate.a = 1
		text_edit.text = text

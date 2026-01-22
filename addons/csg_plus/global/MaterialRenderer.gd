@tool
class_name ConvexFaceEditorPreview
extends SubViewport

var index = 0
var images = []
var material_to_render: Array[MaterialRendererData] = []

func take_snapshots(target_material, callback):
	material_to_render.append(
		MaterialRendererData.new(
			callback,
			target_material
		)
	)
	render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _ready() -> void:
	$Camera3D.projection = Camera3D.PROJECTION_PERSPECTIVE

func _process(_delta: float) -> void:
	if material_to_render.size() > 0:
		if index != material_to_render[0].materials.size():
			images.append(await generate_image(material_to_render[0].materials[index]))
			index+= 1
			return
		material_to_render[0].callback.call(images)
		material_to_render.pop_front()
		index = 0
		images = []
		return
	render_target_update_mode = SubViewport.UPDATE_DISABLED

func generate_image(target_material:Material):
	$DrawingPad.mesh.material = target_material

	await RenderingServer.frame_post_draw
	#print ("grabbing image %s" % target_material.resource_path)
	var image:Image = get_viewport().get_texture().get_image()
	var tex:ImageTexture = ImageTexture.create_from_image(image)
	return tex

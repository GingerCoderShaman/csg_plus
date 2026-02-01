@tool
extends VBoxContainer

const RESOURCE_REFERENCE = "res://"

var snap_amount:
	set(value):
		%SnapNumber.value = value
	get():
		return %SnapNumber.value

var snap_active:
	set(value):
		%SnapUse.button_pressed = value
	get():
		return %SnapUse.button_pressed

var snap_global:
	set(value):
		%SnapGlobal.button_pressed = value
	get():
		return %SnapGlobal.button_pressed

var edit_children:
	set(value):
		%EditChildren.button_pressed = value
	get():
		return %EditChildren.button_pressed
		

var current_texture:
	set(value):
		_user_selected_material = value
		var index = seek_index_of_material(value)
		%TextureOption.selected = index
	get:
		var id = %TextureOption.get_selected_id()
		if id == -1 || id >= materials.size():
			return _user_selected_material
		return materials[id]

var materials = []

var offset_position_x:
	set(value):
		%OffsetX.value = value
	get():
		return $%OffsetX.value

var offset_position_y:
	set(value):
		%OffsetY.value = value
	get():
		return %OffsetY.value

var offset_position:
	set(value):
		%OffsetX.value = value.x
		%OffsetY.value = value.y
	get():
		return Vector2(%OffsetX.value, %OffsetY.value)

var offset_angle:
	set(value):
		%OffsetAngle.value = rad_to_deg(value)
	get():
		return deg_to_rad(%OffsetAngle.value)

var offset_scale_x:
	set(value):
		%OffsetScaleX.value = value
	get():
		return $%OffsetScaleX.value

var offset_scale_y:
	set(value):
		%OffsetScaleY.value = value
	get():
		return %OffsetScaleY.value

var offset_scale:
	set(value):
		%OffsetScaleX.value = value.x
		%OffsetScaleY.value = value.y
	get():
		return Vector2(%OffsetScaleX.value, %OffsetScaleY.value)

var cylinder_points:
	set(value):
		%CylinderPoints.value = float(value)
	get():
		return %CylinderPoints.value

var on_update_callback = null

var _user_selected_material = null

func seek_index_of_material(material:Material):
	for index in materials.size():
		if materials[index].get_rid() == material.get_rid():
			return index
	return -1

func _ready() -> void:
	snap_amount = CSGPlusGlobals.controller.snap_distance
	snap_global = CSGPlusGlobals.controller.setting_global_positioner
	snap_active = CSGPlusGlobals.controller.snap
	edit_children = CSGPlusGlobals.controller.edit_children
	cylinder_points = CSGPlusGlobals.controller.cylinder_points
	%SnapNumber.visible = CSGPlusGlobals.controller.snap
	%SnapLabel.visible = CSGPlusGlobals.controller.snap
	setup_options()

func update():
	if on_update_callback:
		on_update_callback.call(self)

func material_selected(value):
	_user_selected_material = materials[value]
	update()

func reset_resource_options():
	setup_options()
	update()

func set_face_addons_visible(open=true):
	for node:Control in get_children():
		if node.name.begins_with('Face'):
			node.visible = open

func update_snap_number(value):
	CSGPlusGlobals.controller.snap_distance = value
	CSGPlusGlobals.controller.refresh_tool()
	update()

func update_snap_active(value):
	CSGPlusGlobals.controller.snap = value
	CSGPlusGlobals.controller.refresh_tool()
	%SnapNumber.visible = CSGPlusGlobals.controller.snap
	%SnapLabel.visible = CSGPlusGlobals.controller.snap
	update()

func update_cylider_points(value):
	CSGPlusGlobals.controller.cylinder_points = int(value)
	CSGPlusGlobals.controller.refresh_tool()
	update()

func update_snap_global(value):
	CSGPlusGlobals.controller.setting_global_positioner = value
	CSGPlusGlobals.controller.refresh_tool()
	update()

func update_offset_x(_value):
	update()

func update_offset_y(_value):
	update()

func update_offset_angle(_value):
	update()

func update_offset_scale_x(_value):
	update()

func update_offset_scale_y(_value):
	update()

func _on_edit_children_toggled(toggled_on: bool) -> void:
	CSGPlusGlobals.controller.edit_children = toggled_on
	CSGPlusGlobals.controller.refresh_targeting()
	update()

func setup_options():
	var materials_found = {}
	materials = []
	var names = []
	%TextureOption.clear()
	seek_material_files(RESOURCE_REFERENCE, materials_found)
	for data in materials_found.keys():
		materials.append(data)
		names.append(materials_found[data])
	CSGPlusGlobals.controller.material_renderer.take_snapshots(
		materials,
		func(images):
			for index in names.size():
				%TextureOption.add_item(names[index], index)
				%TextureOption.set_item_icon(index, images[index])
				if _user_selected_material:
					current_texture = _user_selected_material
	)

func seek_material_files(path: String, materials_found):
	var dir = DirAccess.open(path)
	for file in dir.get_files():
		if file.ends_with('.tres'):
			var resource = load(path + file)
			if resource is Material:
				var final = file
				if materials_found.has(final):
					final = path.substr(RESOURCE_REFERENCE.length()) + file
				materials_found[resource] = final

	for directory in dir.get_directories():
		if directory && directory[0] != '.':
			if (path + directory != 'res://addons' || %IncludeAddons.button_pressed):
				seek_material_files(path + directory + '/', materials_found)
			else:
				seek_material_files('res://addons/csg_plus/resources/material/levels/', materials_found)

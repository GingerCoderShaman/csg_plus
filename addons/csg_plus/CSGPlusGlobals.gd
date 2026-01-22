@tool
class_name CSGPlusGlobals

enum MODE {DEFAULT, POINT, LINE, FACE, CREATE}

const NODE_UNSELECT = 'NODE_ESCAPE'
const NODE_SELECTED = 'NODE_SELECT'
const NODE_HOLD = 'NODE_HOLD'

const TARGET_POINT_MATERIAL = preload('res://addons/csg_plus/resources/material/PointsMesh/Targeted.tres')
const HOVER_POINT_MATERIAL = preload('res://addons/csg_plus/resources/material/PointsMesh/Hover.tres')

const HOVER_LINE_MATERIAL = preload('res://addons/csg_plus/resources/material/LineMesh/Hover.tres')

const MoveGizmo = preload('res://addons/csg_plus/scene/gizmo/MoveGizmo.gd')
const OverlaySelectArea = preload('res://addons/csg_plus/scene/gizmo/OverlaySelectArea.gd')

const Line = preload('res://addons/csg_plus/structures/data/Line.gd')
const FaceInfo = preload('res://addons/csg_plus/structures/data/FaceInfo.gd')
const DynamicMesh = preload('res://addons/csg_plus/structures/data/DynamicMesh.gd')
const ReflectedNode = preload('res://addons/csg_plus/structures/visual/ReflectedNode.gd')
const TargetLine = preload('res://addons/csg_plus/structures/visual/TargetLine.gd')
const TargetPoint = preload('res://addons/csg_plus/structures/visual/TargetPoint.gd')
const VisualLine = preload('res://addons/csg_plus/structures/visual/VisualLine.gd')
const VisualPoint = preload('res://addons/csg_plus/structures/visual/VisualPoint.gd')
const LevelDefaultMaterial = preload('res://addons/csg_plus/resources/material/levels/DefaultMaterial.tres')

static var controller

static func create_controller(parent_node, mode_has_changed_callback, undo_redo, selectable_scene, scene_adder, scene_viewport):
	var CSGPlusController = load('res://addons/csg_plus/global/CSGPlusController.gd')
	controller = CSGPlusController.init_controller(mode_has_changed_callback, undo_redo, selectable_scene, scene_adder, scene_viewport)
	parent_node.add_child(controller)

static func destroy_controller(parent_node):
	parent_node.remove_child(controller)
	controller = null

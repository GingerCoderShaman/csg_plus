# CSGPlus 

CSG plus is a Godot plugin for the editor. It creates a new type of CSG that can be edited by points/lines/planes. It allows each plane to select textures. This is to expand level editing abilities. 
To enable CSG plus, add the addons folder into your project, and Godot engine project > project settings > plugins, Enable CSG Plus 

## Modes of editing 

CSG plus comes with 5 modes of editing,  

the default Godot mode where you manipulate whole objects.  

a point edits mode, where you can edit, add, or delete points on the polygon. 

a line edits mode, where you can manipulate lines on the object, add new across planes, or delete. 

and a face editor tool, which allow manipulation and texture by side changing. 

The tools also have some capability to create shapes dynamically. you can build off the worlds floor, or off existing CSGPlus Meshes. 

Since this project uses CSG as its base, all the capabilities of godet CSG are available for your use. 

it is recommended you use CSGCombiner3D(or a node3d to be swapped with it) and convert your level to VisualInstance3d via Bake Mesh Instances built into godot before you deliver levels to players. or export your level for further blender edits. 

## plans for project 

upcoming features are to include capabilities to transform any object with 3d Meshes (within reason for face count) into CSGPlusMesh. 

maybe slight improvements to visuals (functionality is more important) 

to be used as a base for a robot character editor. (editor tool might be released as part of the project for free) 

to be used in my game project as a level editor, and a robot character editor. 

to be a part of Godot assetlibs 

Full Demos showing off features 

 

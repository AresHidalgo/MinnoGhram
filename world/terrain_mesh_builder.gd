## Convierte el heightmap de un WorldState en una malla 3D + colisión.
## v0: una sola malla para todo el mundo. Los chunks, el LOD y el hilo separado
## (Bible sección 9) vienen después, cuando el tamaño del mundo lo exija.
class_name TerrainMeshBuilder
extends RefCounted


static func build_mesh(state: WorldState) -> ArrayMesh:
	var p := state.profile
	var n := state.size
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var offset := (n - 1) * p.cell_size_m * 0.5  # centrar el mundo en el origen
	for z in n - 1:
		for x in n - 1:
			var a := _vertex(state, x, z, offset)
			var b := _vertex(state, x + 1, z, offset)
			var c := _vertex(state, x, z + 1, offset)
			var d := _vertex(state, x + 1, z + 1, offset)
			_add(st, state, x, z, a)
			_add(st, state, x + 1, z, b)
			_add(st, state, x, z + 1, c)
			_add(st, state, x + 1, z, b)
			_add(st, state, x + 1, z + 1, d)
			_add(st, state, x, z + 1, c)

	st.generate_normals()
	return st.commit()


## Colisión física para que el personaje (CharacterBody3D) camine sobre el terreno.
## HeightMapShape3D usa celdas de 1 unidad: guardamos las alturas divididas por
## cell_size_m y el CollisionShape3D debe escalarse de forma UNIFORME por
## cell_size_m (ver collision_scale()). Así evitamos escalado no uniforme.
static func build_collision_shape(state: WorldState) -> HeightMapShape3D:
	var n := state.size
	var shape := HeightMapShape3D.new()
	shape.map_width = n
	shape.map_depth = n
	var data := PackedFloat32Array()
	data.resize(n * n)
	for i in n * n:
		data[i] = state.heightmap[i] * state.profile.height_scale_m / state.profile.cell_size_m
	shape.map_data = data
	return shape


static func collision_scale(state: WorldState) -> Vector3:
	return Vector3.ONE * state.profile.cell_size_m


static func _vertex(state: WorldState, x: int, z: int, offset: float) -> Vector3:
	var p := state.profile
	return Vector3(
		x * p.cell_size_m - offset,
		state.get_height01(x, z) * p.height_scale_m,
		z * p.cell_size_m - offset)


static func _add(st: SurfaceTool, state: WorldState, x: int, z: int, v: Vector3) -> void:
	st.set_color(TerrainColors.color_for(state.get_height01(x, z), state.profile.sea_level))
	st.add_vertex(v)

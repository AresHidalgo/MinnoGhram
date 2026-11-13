## Escena de prueba del generador: genera el mundo de una Seed y lo muestra en 3D.
##
## En el EDITOR: la isla aparece directamente en el visor 3D. Cambia "Seed Text"
## en el Inspector y se regenera al instante. Lo generado no se guarda en la escena.
## Al EJECUTAR (F6): R = Seed aleatoria nueva · P = guardar PNG del mapa en user://
## La Seed actual se imprime en el panel Salida.
@tool
extends Node3D

@export var profile: WorldProfile = preload("res://data/world_profiles/oppervlak.tres"):
	set(value):
		profile = value
		_regenerate_if_ready()
## Texto o número. Vacío = Seed aleatoria.
@export var seed_text: String = "minnoghram":
	set(value):
		seed_text = value
		_regenerate_if_ready()

var _state: WorldState
var _terrain: Node3D


func _ready() -> void:
	_setup_environment()
	_generate(_seed_from_inspector())


func _seed_from_inspector() -> int:
	return SeedHash.seed_from_text(seed_text) if seed_text != "" else _random_seed()


func _regenerate_if_ready() -> void:
	if is_node_ready() and profile != null:
		_generate(_seed_from_inspector())


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_generate(_random_seed())
			KEY_P:
				var path := "user://seed_%d.png" % _state.master_seed
				_state.to_image().save_png(path)
				print("Mapa guardado en ", ProjectSettings.globalize_path(path))


func _random_seed() -> int:
	# La única aleatoriedad "real" del juego: elegir la Seed maestra.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()


func _generate(master_seed: int) -> void:
	var t0 := Time.get_ticks_msec()
	_state = WorldGenerator.new().generate(master_seed, profile)
	print("Seed %d | tierra %.0f%% | intentos %s | checksum %d | %d ms" % [
		master_seed, _state.land_ratio * 100.0, _state.attempts, _state.checksum(),
		Time.get_ticks_msec() - t0])

	if _terrain:
		_terrain.queue_free()
	_terrain = Node3D.new()
	_terrain.name = "Terrain"
	add_child(_terrain)

	var body := StaticBody3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = TerrainMeshBuilder.build_mesh(_state)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	var col := CollisionShape3D.new()
	col.shape = TerrainMeshBuilder.build_collision_shape(_state)
	col.scale = TerrainMeshBuilder.collision_scale(_state)
	body.add_child(col)
	_terrain.add_child(body)

	# Plano de agua al nivel del mar.
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var extent := _state.size * profile.cell_size_m
	plane.size = Vector2(extent, extent) * 1.5
	water.mesh = plane
	water.position.y = profile.sea_level * profile.height_scale_m
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.15, 0.35, 0.55, 0.7)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.material_override = wmat
	_terrain.add_child(water)


func _setup_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.05, 0.06, 0.09)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.6)
	add_child(env)

	# Cámara isométrica aérea de vista general (no es la cámara de juego).
	# En el editor no hace falta: se usa la cámara del visor.
	if Engine.is_editor_hint():
		return
	var cam := Camera3D.new()
	var extent := profile.world_size_cells * profile.cell_size_m
	cam.position = Vector3(extent * 0.55, extent * 0.6, extent * 0.55)
	add_child(cam)
	cam.look_at(Vector3.ZERO)
	cam.far = extent * 4.0

## Visualizador de Seeds (03_Technical_Architecture.md, sección 11).
## Genera solo los datos (sin malla 3D) y guarda un PNG por Seed.
##   godot --headless --script res://tools/seed_visualizer.gd -- 1 2 3 dragon
## Las imágenes quedan en user://seed_previews/
extends SceneTree


func _init() -> void:
	var profile: WorldProfile = load("res://data/world_profiles/oppervlak.tres")
	var seeds := OS.get_cmdline_user_args()
	if seeds.is_empty():
		seeds = PackedStringArray(["1", "2", "3", "4"])
	DirAccess.make_dir_recursive_absolute("user://seed_previews")
	var gen := WorldGenerator.new()
	for text in seeds:
		var s := SeedHash.seed_from_text(text)
		var state := gen.generate(s, profile)
		var path := "user://seed_previews/%s.png" % text
		state.to_image().save_png(path)
		print("%s -> seed %d, tierra %.0f%%, %s" % [text, s, state.land_ratio * 100.0, ProjectSettings.globalize_path(path)])
	quit()

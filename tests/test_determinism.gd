## Prueba de determinismo. Ejecutar sin abrir el editor:
##   godot --headless --script res://tests/test_determinism.gd
## Sale con código 0 si todo pasa, 1 si algo falla.
extends SceneTree

## Huellas conocidas: si cambian, cambió el mundo de esas Seeds para TODOS los
## jugadores. Solo se actualizan a propósito (y subiendo SeedHash.HASH_VERSION).
const GOLDEN := {
	0: 1588303560,
	1: 1877000649,
	42: 2910168017,
	12345: 1500577519,
}

var _failures := 0


func _init() -> void:
	var profile: WorldProfile = load("res://data/world_profiles/oppervlak.tres")
	var gen := WorldGenerator.new()

	# 1. El hash propio da siempre lo mismo (valores de referencia de FNV-1a 32).
	_check(SeedHash.fnv1a_32("") == 2166136261, "FNV-1a de '' es el valor estándar")
	_check(SeedHash.fnv1a_32("a") == 3826002220, "FNV-1a de 'a' es el valor estándar")
	_check(SeedHash.seed_from_text("12345") == 12345, "Seed numérica se respeta")

	# 2. Sub-seeds distintas por etapa e intento.
	var s1 := SeedHash.derive(42, &"macro_relief")
	_check(s1 == SeedHash.derive(42, &"macro_relief"), "derive() es estable")
	_check(s1 != SeedHash.derive(42, &"biomes"), "etapas distintas -> sub-seeds distintas")
	_check(s1 != SeedHash.derive(42, &"macro_relief", 1), "intentos distintos -> sub-seeds distintas")

	# 3. Misma Seed -> mismo mundo; Seed distinta -> mundo distinto.
	for seed in [0, 1, 42, 12345, SeedHash.seed_from_text("minnoghram")]:
		var a := gen.generate(seed, profile)
		var b := gen.generate(seed, profile)
		_check(a.checksum() == b.checksum(), "Seed %d reproducible (checksum %d)" % [seed, a.checksum()])
		_check(a.land_ratio >= profile.min_land_ratio, "Seed %d tiene masa continental %.2f (intentos %s)" % [seed, a.land_ratio, a.attempts])
		if GOLDEN.has(seed):
			_check(a.checksum() == GOLDEN[seed], "Seed %d coincide con su huella conocida" % seed)
	_check(gen.generate(1, profile).checksum() != gen.generate(2, profile).checksum(), "Seeds distintas -> mundos distintos")

	print("\n%s" % ("TODO OK" if _failures == 0 else "%d FALLOS" % _failures))
	quit(0 if _failures == 0 else 1)


func _check(cond: bool, label: String) -> void:
	print(("  [OK]   " if cond else "  [FAIL] ") + label)
	if not cond:
		_failures += 1

extends Fluid2D
class_name PotionFluidPool

## Lives once on BaseLevel, like the level's Camera2D. Each new splash clears
## whatever fluid is currently in the pool before adding its own — so only
## one potion's worth of fluid ever exists on the board at a time. That's
## what lets this stay simple: no per-particle tagging needed, because
## there's never more than one quality active to be ambiguous about.
##
## This costs nothing gameplay-wise — peg meters are permanent once pushed
## (per the design doc), so a puddle disappearing doesn't undo what it
## already did to any peg it touched.

## Seconds after a splash appears before it starts fading.
@export var fade_delay: float = 5.0

## Seconds the fade itself takes once triggered.
@export var fade_duration: float = 1.0

var _quality: Alchemy.Quality
var _push_per_particle: float

## Increments on every register_splash(). Pegs compare it against the last id
## they were credited for, so each splash gives them a fresh one-time budget.
var splash_id: int = 0

var _age := 0.0
var _fading := false
var _fade_timer := 0.0
var _water_material: ShaderMaterial
var _base_alpha := 0.65  # the shader's own translucency, kept when tinting


func _ready() -> void:
	add_to_group("potion_fluid_pool")
	for child in get_children():
		if child is Fluid2DShaderRenderer and child.sub_viewport_container:
			_water_material = child.sub_viewport_container.material as ShaderMaterial
	if _water_material:
		var current = _water_material.get_shader_parameter("water_color")
		if current is Color:
			_base_alpha = current.a


## Tints the rendered water to the potion's color — the same
## Alchemy.color_for_quality() that Potion uses for its sprite, so the liquid
## always matches the potion type's quality.
func _set_color(color: Color) -> void:
	if _water_material:
		_water_material.set_shader_parameter("water_color", Color(color.r, color.g, color.b, _base_alpha))


## Opacity of the rendered water, 1 = fully visible. Driven through the water
## shader's `fade` uniform because the fluid is drawn on a CanvasLayer, which
## ignores this node's modulate.
func _set_opacity(opacity: float) -> void:
	if _water_material:
		_water_material.set_shader_parameter("fade", opacity)


## Called by potion.gd at the moment of shatter. Particles start at rest and
## fall/spread under gravity and collision alone — this build's Fluid2D
## confirmed does not expose particle velocity control, so there's no
## outward "burst" push at creation, just a dropped blob.
func register_splash(global_pos: Vector2, radius: float, quality: Alchemy.Quality, push_per_particle: float) -> void:
	_quality = quality
	_push_per_particle = push_per_particle
	splash_id += 1
	_age = 0.0
	_fading = false
	_set_opacity(1.0)
	_set_color(Alchemy.color_for_quality(quality))

	var local_center := to_local(global_pos)
	# create_circle_points() takes its radius in particle diameters, not pixels,
	# so convert the world-unit radius (each particle is 2 * particle_radius wide).
	var spacing: float = 2.0 * ProjectSettings.get_setting("physics/rapier/fluid/fluid_particle_radius_2d", 10.0)
	var new_points := create_circle_points(maxi(1, roundi(radius / spacing)))  # around local origin — offset below

	var offset_points := PackedVector2Array()
	for p in new_points:
		offset_points.append(p + local_center)
	points = offset_points  # replaces, not appends — the previous splash is gone


func _process(delta: float) -> void:
	if points.is_empty():
		return

	if _fading:
		# Fade the water's opacity along an eased curve while the particles keep
		# simulating untouched, then clear them once it's fully transparent.
		# (Removing particles one by one — or reassigning `points` each frame —
		# makes the blob visibly pop and resets the physics state.)
		_fade_timer += delta
		var t := clampf(_fade_timer / maxf(fade_duration, 0.001), 0.0, 1.0)
		_set_opacity(1.0 - smoothstep(0.0, 1.0, t))
		if t >= 1.0:
			points = PackedVector2Array()
			_fading = false
			_set_opacity(1.0)
		return

	_age += delta
	if _age >= fade_delay:
		_fading = true
		_fade_timer = 0.0


## Called by peg.gd. Real particle-density sampling, since there's only ever
## one quality in the pool to attribute it to.
func sample_push(global_pos: Vector2, sample_radius: float) -> Dictionary:
	if points.is_empty():
		return {}

	var local_pos := to_local(global_pos)
	var radius_sq := sample_radius * sample_radius
	var count := 0
	for p in points:
		if p.distance_squared_to(local_pos) <= radius_sq:
			count += 1

	if count == 0:
		return {}
	return {"quality": _quality, "push_per_particle": _push_per_particle, "count": count, "splash_id": splash_id}

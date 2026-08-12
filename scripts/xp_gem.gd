class_name ExperienceGem
extends Node2D

var value := 3
var velocity := Vector2.ZERO
var radius := 7.0


func setup(amount: int) -> void:
	value = amount
	rotation = randf() * TAU


func update_toward(player: Node2D, pickup_radius: float, delta: float) -> bool:
	var distance := global_position.distance_to(player.global_position)
	if distance < pickup_radius:
		var pull := remap(distance, 0.0, pickup_radius, 720.0, 160.0)
		velocity = velocity.move_toward(global_position.direction_to(player.global_position) * pull, 900.0 * delta)
		global_position += velocity * delta
	if distance < 22.0:
		queue_free()
		return true
	rotation += delta * 2.5
	return false


func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0, -radius), Vector2(radius * 0.75, 0),
		Vector2(0, radius), Vector2(-radius * 0.75, 0)
	])
	draw_colored_polygon(points, Color("#66e3a4"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("#d8ffe9"), 1.5)

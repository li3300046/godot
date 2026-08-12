class_name ChaserEnemy
extends Node2D

var target: Node2D
var speed := 85.0
var max_health := 22.0
var health := 22.0
var contact_damage := 12.0
var xp_value := 4
var radius := 15.0


func setup(player: Node2D, wave: int) -> void:
	target = player
	max_health = 18.0 + wave * 3.5
	health = max_health
	speed = 72.0 + minf(wave * 4.0, 75.0)
	contact_damage = 8.0 + wave * 1.2
	xp_value = 3 + wave / 3
	radius = 14.0 + minf(wave * 0.25, 5.0)


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var direction := global_position.direction_to(target.global_position)
		global_position += direction * speed * delta
	queue_redraw()


func hit(damage: float) -> bool:
	health -= damage
	queue_redraw()
	return health <= 0.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 3.0, Color("#4a2037"))
	draw_circle(Vector2.ZERO, radius, Color("#d84a66"))
	draw_circle(Vector2(-5, -3), 2.5, Color.WHITE)
	draw_circle(Vector2(5, -3), 2.5, Color.WHITE)
	draw_circle(Vector2(-5, -3), 1.2, Color("#241b2f"))
	draw_circle(Vector2(5, -3), 1.2, Color("#241b2f"))
	var bar_width := radius * 2.0
	draw_rect(Rect2(-bar_width / 2.0, -radius - 9.0, bar_width, 3.0), Color("#442631"))
	draw_rect(Rect2(-bar_width / 2.0, -radius - 9.0, bar_width * maxf(health, 0.0) / max_health, 3.0), Color("#70e58a"))

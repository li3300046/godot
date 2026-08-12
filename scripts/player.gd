class_name SurvivorPlayer
extends CharacterBody2D

signal died

var move_speed := 260.0
var max_health := 100.0
var health := 100.0
var pickup_radius := 105.0
var invincible_time := 0.0


func _ready() -> void:
	add_to_group("player")
	queue_redraw()


func _physics_process(delta: float) -> void:
	invincible_time = maxf(0.0, invincible_time - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()
	var view_size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 24.0, view_size.x - 24.0)
	global_position.y = clampf(global_position.y, 24.0, view_size.y - 24.0)
	queue_redraw()


func take_damage(amount: float) -> void:
	if invincible_time > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invincible_time = 0.45
	queue_redraw()
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)


func _draw() -> void:
	var flash := invincible_time > 0.0 and int(Time.get_ticks_msec() / 70) % 2 == 0
	var body_color := Color("#f8d66d") if not flash else Color.WHITE
	draw_circle(Vector2.ZERO, 20.0, Color("#3b2e2a"))
	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_circle(Vector2(-6, -4), 2.5, Color("#272125"))
	draw_circle(Vector2(6, -4), 2.5, Color("#272125"))
	draw_line(Vector2(-6, 6), Vector2(6, 6), Color("#7d3f38"), 2.0)

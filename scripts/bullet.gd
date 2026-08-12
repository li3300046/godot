class_name AutoBullet
extends Node2D

var direction := Vector2.RIGHT
var speed := 620.0
var damage := 12.0
var life_time := 1.4
var radius := 5.0
var pierce := 0
var hit_ids: Dictionary = {}


func setup(from: Vector2, aim_direction: Vector2, weapon_damage: float, pierce_count: int) -> void:
	global_position = from
	direction = aim_direction.normalized()
	damage = weapon_damage
	pierce = pierce_count
	rotation = direction.angle()


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()


func can_hit(enemy: Node) -> bool:
	return not hit_ids.has(enemy.get_instance_id())


func register_hit(enemy: Node) -> bool:
	hit_ids[enemy.get_instance_id()] = true
	if pierce <= 0:
		queue_free()
		return true
	pierce -= 1
	return false


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 3.0, Color(1.0, 0.75, 0.25, 0.25))
	draw_circle(Vector2.ZERO, radius, Color("#ffd15c"))

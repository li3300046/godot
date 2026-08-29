class_name SurvivorPlayer
extends CharacterBody2D

signal died

const PlayerVisualScene = preload("res://scenes/player_visual.tscn")

enum AnimationState {
	IDLE,
	MOVING,
	HURT
}

var move_speed := 260.0
var max_health := 100.0
var health := 100.0
var pickup_radius := 105.0
var invincible_time := 0.0
var animation_state := AnimationState.IDLE
var facing_direction := Vector2.DOWN

var body_sprite: Sprite2D
var aim_arrow: Sprite2D
var animation_player: AnimationPlayer
var state_label: Label


func _ready() -> void:
	add_to_group("player")
	var visual := PlayerVisualScene.instantiate()
	add_child(visual)
	body_sprite = visual.get_node("BodySprite")
	aim_arrow = visual.get_node("AimArrow")
	animation_player = visual.get_node("AnimationPlayer")
	state_label = visual.get_node("StateLabel")
	_set_animation_state(AnimationState.IDLE, true)
	queue_redraw()


func _physics_process(delta: float) -> void:
	invincible_time = maxf(0.0, invincible_time - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not input_vector.is_zero_approx():
		facing_direction = input_vector.normalized()
		body_sprite.flip_h = facing_direction.x < -0.05
	velocity = input_vector * move_speed
	move_and_slide()
	_update_animation_state(input_vector)
	var view_size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 24.0, view_size.x - 24.0)
	global_position.y = clampf(global_position.y, 24.0, view_size.y - 24.0)


func set_aim_direction(direction: Vector2) -> void:
	# angle() 把标准化方向向量转换为 Sprite2D 需要的旋转弧度。
	if direction.is_zero_approx():
		return
	aim_arrow.rotation = direction.normalized().angle()


func _update_animation_state(input_vector: Vector2) -> void:
	if invincible_time > 0.0:
		_set_animation_state(AnimationState.HURT)
	elif input_vector.is_zero_approx():
		_set_animation_state(AnimationState.IDLE)
	else:
		_set_animation_state(AnimationState.MOVING)


func _set_animation_state(next_state: AnimationState, force := false) -> void:
	if animation_state == next_state and not force:
		return
	animation_state = next_state
	match animation_state:
		AnimationState.IDLE:
			animation_player.play("idle")
			state_label.text = "IDLE"
		AnimationState.MOVING:
			animation_player.play("moving")
			state_label.text = "MOVING"
		AnimationState.HURT:
			animation_player.play("hurt")
			state_label.text = "HURT"


func take_damage(amount: float) -> void:
	if invincible_time > 0.0 or health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	invincible_time = 0.45
	_set_animation_state(AnimationState.HURT)
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)


func _draw() -> void:
	# 保留一层阴影；角色主体和朝向箭头由 player_visual.tscn 的 Sprite2D 绘制。
	draw_ellipse_shadow()


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0.0, 14.0), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 20.0, Color(0.05, 0.04, 0.08, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

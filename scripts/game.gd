extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const BulletScript = preload("res://scripts/bullet.gd")
const GemScript = preload("res://scripts/xp_gem.gd")
const HUDScript = preload("res://scripts/hud.gd")
const CharacterStatusScript = preload("res://scripts/character_status_ui.gd")
const QuickStatusScene = preload("res://scenes/ui/quick_status_card.tscn")

var player: SurvivorPlayer
var hud: GameHUD
var character_status_ui: CharacterStatusUI
# 不标注 QuickStatusCard：这个对象来自 PackedScene，避免 game.gd 在解析阶段
# 依赖新脚本的全局 class_name 注册顺序。
var quick_status_card
var enemies: Array[ChaserEnemy] = []
var bullets: Array[AutoBullet] = []
var gems: Array[ExperienceGem] = []

var wave := 1
var wave_duration := 30.0
var wave_time := 30.0
var spawn_timer := 0.0
var fire_timer := 0.0
var kills := 0
var level := 1
var xp := 0
var xp_needed := 12
var game_over := false
var choosing_upgrade := false

var weapon_damage := 13.0
var fire_interval := 0.52
var bullet_count := 1
var bullet_pierce := 0
var upgrade_options: Array[Dictionary] = []

var upgrades: Array[Dictionary] = [
	{"title": "强力弹头", "description": "伤害 +6", "id": "damage"},
	{"title": "快速扳机", "description": "攻击速度 +18%", "id": "fire_rate"},
	{"title": "多重射击", "description": "额外发射 1 枚子弹", "id": "multishot"},
	{"title": "穿透弹", "description": "子弹额外穿透 1 个敌人", "id": "pierce"},
	{"title": "轻便鞋", "description": "移动速度 +30", "id": "speed"},
	{"title": "健康体魄", "description": "最大生命 +20，并回复 20", "id": "health"},
	{"title": "经验磁铁", "description": "拾取范围 +45", "id": "pickup"},
	{"title": "急救包", "description": "回复 35 生命", "id": "heal"}
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input()
	_create_background()
	player = PlayerScript.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.global_position = get_viewport_rect().size * 0.5
	player.died.connect(_on_player_died)
	add_child(player)
	hud = HUDScript.new()
	hud.upgrade_chosen.connect(_on_upgrade_chosen)
	add_child(hud)
	character_status_ui = CharacterStatusScript.new()
	character_status_ui.configure(player, self)
	add_child(character_status_ui)
	# 混合 UI：实例化编辑器制作的 .tscn，再连接到代码创建的详细面板。
	quick_status_card = QuickStatusScene.instantiate()
	quick_status_card.configure(player, self)
	quick_status_card.details_requested.connect(character_status_ui.open_panel)
	add_child(quick_status_card)


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			get_tree().paused = false
			get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("pause_game") and not choosing_upgrade:
		get_tree().paused = not get_tree().paused
	if choosing_upgrade:
		for index in 3:
			if Input.is_key_pressed(KEY_1 + index):
				_on_upgrade_chosen(index)
				break
		return
	if get_tree().paused:
		return

	wave_time -= delta
	if wave_time <= 0.0:
		wave += 1
		wave_time = wave_duration
		player.heal(12.0)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = maxf(0.16, 0.72 - wave * 0.045)

	fire_timer -= delta
	if fire_timer <= 0.0 and not enemies.is_empty():
		_fire_weapon()
		fire_timer = fire_interval

	_update_gems(delta)
	_resolve_bullet_hits()
	_resolve_enemy_contact()
	_cleanup_arrays()
	hud.update_stats(player.health, player.max_health, xp, xp_needed, level, wave, wave_time, kills)


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#171827"))
	var grid := 64
	for x in range(0, int(size.x) + grid, grid):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.2, 0.22, 0.34, 0.3), 1.0)
	for y in range(0, int(size.y) + grid, grid):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.2, 0.22, 0.34, 0.3), 1.0)


func _create_background() -> void:
	queue_redraw()


func _spawn_enemy() -> void:
	var enemy: ChaserEnemy = EnemyScript.new()
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.setup(player, wave)
	var size := get_viewport_rect().size
	var side := randi() % 4
	match side:
		0: enemy.global_position = Vector2(randf_range(0, size.x), -30)
		1: enemy.global_position = Vector2(size.x + 30, randf_range(0, size.y))
		2: enemy.global_position = Vector2(randf_range(0, size.x), size.y + 30)
		_: enemy.global_position = Vector2(-30, randf_range(0, size.y))
	enemies.append(enemy)
	add_child(enemy)


func _fire_weapon() -> void:
	var nearest: ChaserEnemy
	var nearest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest == null:
		return
	var base_direction := player.global_position.direction_to(nearest.global_position)
	player.set_aim_direction(base_direction)
	var spread := deg_to_rad(10.0)
	for i in bullet_count:
		var offset := (i - (bullet_count - 1) / 2.0) * spread
		var bullet: AutoBullet = BulletScript.new()
		bullet.process_mode = Node.PROCESS_MODE_PAUSABLE
		bullet.setup(player.global_position, base_direction.rotated(offset), weapon_damage, bullet_pierce)
		bullets.append(bullet)
		add_child(bullet)


func _resolve_bullet_hits() -> void:
	for bullet in bullets:
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			continue
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
				continue
			if not bullet.can_hit(enemy):
				continue
			if bullet.global_position.distance_squared_to(enemy.global_position) <= pow(bullet.radius + enemy.radius, 2):
				var dead := enemy.hit(bullet.damage)
				bullet.register_hit(enemy)
				if dead:
					_kill_enemy(enemy)
				if bullet.is_queued_for_deletion():
					break


func _resolve_enemy_contact() -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_squared_to(player.global_position) <= pow(enemy.radius + 18.0, 2):
			player.take_damage(enemy.contact_damage)
			enemy.global_position += player.global_position.direction_to(enemy.global_position) * 28.0


func _kill_enemy(enemy: ChaserEnemy) -> void:
	var gem: ExperienceGem = GemScript.new()
	gem.process_mode = Node.PROCESS_MODE_PAUSABLE
	gem.global_position = enemy.global_position
	gem.setup(enemy.xp_value)
	gems.append(gem)
	add_child(gem)
	kills += 1
	enemy.queue_free()


func _update_gems(delta: float) -> void:
	for gem in gems:
		if is_instance_valid(gem) and not gem.is_queued_for_deletion():
			if gem.update_toward(player, player.pickup_radius, delta):
				_gain_xp(gem.value)


func _gain_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_needed and not choosing_upgrade:
		xp -= xp_needed
		level += 1
		xp_needed = int(xp_needed * 1.35 + 5)
		_show_upgrade()


func _show_upgrade() -> void:
	choosing_upgrade = true
	character_status_ui.close_panel()
	get_tree().paused = true
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_options = upgrades.duplicate()
	upgrade_options.shuffle()
	upgrade_options.resize(3)
	hud.show_upgrades(upgrade_options)


func _on_upgrade_chosen(index: int) -> void:
	if not choosing_upgrade or index < 0 or index >= upgrade_options.size():
		return
	var id: String = upgrade_options[index].id
	match id:
		"damage": weapon_damage += 6.0
		"fire_rate": fire_interval = maxf(0.12, fire_interval * 0.82)
		"multishot": bullet_count += 1
		"pierce": bullet_pierce += 1
		"speed": player.move_speed += 30.0
		"health":
			player.max_health += 20.0
			player.heal(20.0)
		"pickup": player.pickup_radius += 45.0
		"heal": player.heal(35.0)
	choosing_upgrade = false
	hud.hide_panel()
	get_tree().paused = false


func _cleanup_arrays() -> void:
	enemies = enemies.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())
	bullets = bullets.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())
	gems = gems.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())


func _on_player_died() -> void:
	game_over = true
	get_tree().paused = true
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.show_game_over(kills, wave)


func _setup_input() -> void:
	var actions := {
		"move_left": [KEY_A, KEY_LEFT, KEY_J],
		"move_right": [KEY_D, KEY_RIGHT, KEY_L],
		"move_up": [KEY_W, KEY_UP, KEY_I],
		"move_down": [KEY_S, KEY_DOWN, KEY_K],
		"restart": [KEY_R],
		"pause_game": [KEY_ESCAPE]
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

class_name GameHUD
extends CanvasLayer

signal upgrade_chosen(index: int)
signal restart_requested

var health_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var wave_label: Label
var timer_label: Label
var kills_label: Label
var center_panel: PanelContainer
var center_title: Label
var choice_buttons: Array[Button] = []


func _ready() -> void:
	_build_hud()


func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := VBoxContainer.new()
	top.position = Vector2(20, 16)
	top.size = Vector2(310, 96)
	root.add_child(top)
	health_bar = _make_bar(Color("#ef5571"))
	xp_bar = _make_bar(Color("#64dba2"))
	top.add_child(health_bar)
	top.add_child(xp_bar)
	level_label = Label.new()
	top.add_child(level_label)

	var stats := VBoxContainer.new()
	stats.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stats.position = Vector2(-190, 16)
	stats.size = Vector2(170, 100)
	stats.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(stats)
	wave_label = Label.new()
	timer_label = Label.new()
	kills_label = Label.new()
	for label in [wave_label, timer_label, kills_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats.add_child(label)

	center_panel = PanelContainer.new()
	center_panel.set_anchors_preset(Control.PRESET_CENTER)
	center_panel.position = Vector2(-260, -160)
	center_panel.size = Vector2(520, 320)
	root.add_child(center_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center_panel.add_child(box)
	center_title = Label.new()
	center_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_title.add_theme_font_size_override("font_size", 28)
	box.add_child(center_title)
	for i in 3:
		var button := Button.new()
		button.custom_minimum_size.y = 64
		button.pressed.connect(_on_choice.bind(i))
		choice_buttons.append(button)
		box.add_child(button)
	center_panel.hide()


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(310, 22)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func update_stats(health: float, max_health: float, xp: int, xp_needed: int, level: int, wave: int, time_left: float, kills: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	xp_bar.max_value = xp_needed
	xp_bar.value = xp
	level_label.text = "等级 %d   生命 %.0f / %.0f" % [level, health, max_health]
	wave_label.text = "第 %d 波" % wave
	timer_label.text = "剩余 %02d 秒" % ceili(time_left)
	kills_label.text = "击败 %d" % kills


func show_upgrades(options: Array[Dictionary]) -> void:
	center_title.text = "升级！选择一项强化"
	for i in choice_buttons.size():
		choice_buttons[i].text = "%d. %s\n%s" % [i + 1, options[i].title, options[i].description]
		choice_buttons[i].show()
	center_panel.show()


func show_game_over(kills: int, wave: int) -> void:
	center_title.text = "战斗结束\n坚持到第 %d 波 · 击败 %d 个敌人" % [wave, kills]
	for i in choice_buttons.size():
		choice_buttons[i].hide()
	choice_buttons[0].text = "按 R 重新开始"
	center_panel.show()


func hide_panel() -> void:
	center_panel.hide()


func _on_choice(index: int) -> void:
	upgrade_chosen.emit(index)

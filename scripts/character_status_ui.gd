class_name CharacterStatusUI
extends CanvasLayer

## 角色状态 UI 教学模块
## 展示：九宫格素材、按钮状态、Tooltip、页签、滑条、复选框、
## OptionButton、禁用状态，以及通过 gui_input 实现面板拖拽。

const ASSET_PATH := "res://assets/kenney_ui/"

var player: SurvivorPlayer
var game: Node
var panel: NinePatchRect
var content_status: VBoxContainer
var content_cases: VBoxContainer
var stat_labels: Dictionary = {}
var add_buttons: Array[Button] = []
var available_points := 3
var points_label: Label
var advanced_box: VBoxContainer
var preview_bar: ProgressBar
var interaction_log: Label
var dragging := false
var drag_offset := Vector2.ZERO


func configure(player_node: SurvivorPlayer, game_node: Node) -> void:
	player = player_node
	game = game_node


func _ready() -> void:
	layer = 2
	_build_interface()
	_set_custom_cursor()


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not panel.visible:
		return
	stat_labels.health.text = "%.0f / %.0f" % [player.health, player.max_health]
	stat_labels.speed.text = "%.0f" % player.move_speed
	stat_labels.pickup.text = "%.0f px" % player.pickup_radius
	stat_labels.damage.text = "%.0f" % game.weapon_damage
	stat_labels.fire_rate.text = "%.2f 秒" % game.fire_interval
	stat_labels.multishot.text = "%d 发" % game.bullet_count
	points_label.text = "可分配点数：%d" % available_points
	for button in add_buttons:
		button.disabled = available_points <= 0


func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var open_button := _make_button("角色状态  [C]", false)
	open_button.position = Vector2(20, 120)
	open_button.size = Vector2(190, 49)
	open_button.tooltip_text = "点击打开角色面板，也可以按键盘 C"
	open_button.mouse_filter = Control.MOUSE_FILTER_STOP
	open_button.pressed.connect(toggle_panel)
	root.add_child(open_button)

	panel = NinePatchRect.new()
	panel.texture = load(ASSET_PATH + "panel_blue.png")
	panel.patch_margin_left = 22
	panel.patch_margin_top = 22
	panel.patch_margin_right = 22
	panel.patch_margin_bottom = 22
	panel.position = Vector2(665, 75)
	panel.size = Vector2(455, 530)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var main_box := VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 9)
	margin.add_child(main_box)

	var title_row := HBoxContainer.new()
	title_row.custom_minimum_size.y = 46
	title_row.gui_input.connect(_on_title_gui_input)
	title_row.mouse_default_cursor_shape = Control.CURSOR_MOVE
	main_box.add_child(title_row)
	var title := Label.new()
	title.text = "角色档案 · 土豆学徒"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#fff3c4"))
	title_row.add_child(title)
	var close_button := _make_square_button("×", false)
	close_button.tooltip_text = "关闭面板"
	close_button.pressed.connect(close_panel)
	title_row.add_child(close_button)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 12)
	main_box.add_child(summary)
	var portrait := NinePatchRect.new()
	portrait.texture = load(ASSET_PATH + "panelInset_beigeLight.png")
	portrait.patch_margin_left = 14
	portrait.patch_margin_top = 14
	portrait.patch_margin_right = 14
	portrait.patch_margin_bottom = 14
	portrait.custom_minimum_size = Vector2(86, 86)
	summary.add_child(portrait)
	var face := Label.new()
	face.text = "🥔"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face.add_theme_font_size_override("font_size", 40)
	portrait.add_child(face)
	var summary_text := VBoxContainer.new()
	summary_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(summary_text)
	var class_label := Label.new()
	class_label.text = "职业：生存者    等级：动态读取"
	summary_text.add_child(class_label)
	var hint := Label.new()
	hint.text = "悬停属性查看 Tooltip\n拖动标题栏可移动此窗口"
	hint.add_theme_color_override("font_color", Color("#d5e7ff"))
	summary_text.add_child(hint)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	main_box.add_child(tabs)
	var status_tab := _make_button("角色属性", true)
	var cases_tab := _make_button("交互案例", false)
	status_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cases_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_tab.pressed.connect(_switch_tab.bind(0))
	cases_tab.pressed.connect(_switch_tab.bind(1))
	tabs.add_child(status_tab)
	tabs.add_child(cases_tab)

	var content_margin := MarginContainer.new()
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(content_margin)
	content_status = VBoxContainer.new()
	content_status.add_theme_constant_override("separation", 6)
	content_margin.add_child(content_status)
	content_cases = VBoxContainer.new()
	content_cases.add_theme_constant_override("separation", 9)
	content_margin.add_child(content_cases)
	content_cases.hide()

	_build_status_tab()
	_build_cases_tab()
	panel.hide()


func _build_status_tab() -> void:
	points_label = Label.new()
	points_label.add_theme_color_override("font_color", Color("#ffe49a"))
	content_status.add_child(points_label)
	_add_stat_row("生命", "health", "当前生命 / 最大生命。点击 + 会提高最大生命并治疗。", "health")
	_add_stat_row("伤害", "damage", "自动武器每颗子弹造成的伤害。", "damage")
	_add_stat_row("移动", "speed", "玩家每秒移动的像素距离。", "speed")
	_add_stat_row("拾取", "pickup", "经验晶体开始吸附的半径。", "pickup")
	_add_stat_row("射击间隔", "fire_rate", "两次自动射击之间的秒数，越低越快。")
	_add_stat_row("多重射击", "multishot", "每次攻击同时发射的子弹数量。")

	var separator := HSeparator.new()
	content_status.add_child(separator)
	var advanced_toggle := CheckButton.new()
	advanced_toggle.text = "显示进阶属性"
	advanced_toggle.tooltip_text = "toggled 信号适合开关设置"
	advanced_toggle.toggled.connect(_on_advanced_toggled)
	content_status.add_child(advanced_toggle)
	advanced_box = VBoxContainer.new()
	content_status.add_child(advanced_box)
	var advanced := Label.new()
	advanced.text = "穿透：动态读取\n受伤无敌：0.45 秒\n波次难度：随时间增长"
	advanced.add_theme_color_override("font_color", Color("#c8d5e8"))
	advanced_box.add_child(advanced)
	advanced_box.hide()


func _add_stat_row(title: String, key: String, tooltip: String, upgrade_id := "") -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 36
	row.tooltip_text = tooltip
	content_status.add_child(row)
	var name_label := Label.new()
	name_label.text = title
	name_label.custom_minimum_size.x = 115
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = "--"
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	stat_labels[key] = value_label
	if not upgrade_id.is_empty():
		var add_button := _make_square_button("+", true)
		add_button.tooltip_text = "消耗 1 点进行强化"
		add_button.pressed.connect(_spend_point.bind(upgrade_id))
		add_buttons.append(add_button)
		row.add_child(add_button)


func _build_cases_tab() -> void:
	var description := Label.new()
	description.text = "下面的控件用于观察鼠标事件和常见信号："
	content_cases.add_child(description)

	var slider_title := Label.new()
	slider_title.text = "HSlider：拖动生命预览"
	content_cases.add_child(slider_title)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 68
	slider.step = 1
	slider.tooltip_text = "拖动会连续触发 value_changed(value)"
	slider.value_changed.connect(_on_preview_changed)
	content_cases.add_child(slider)
	preview_bar = ProgressBar.new()
	preview_bar.max_value = 100
	preview_bar.value = 68
	preview_bar.custom_minimum_size.y = 22
	content_cases.add_child(preview_bar)

	var selector_row := HBoxContainer.new()
	content_cases.add_child(selector_row)
	var selector_label := Label.new()
	selector_label.text = "OptionButton："
	selector_row.add_child(selector_label)
	var selector := OptionButton.new()
	selector.add_item("战士主题")
	selector.add_item("游侠主题")
	selector.add_item("工程师主题")
	selector.item_selected.connect(_on_theme_selected)
	selector_row.add_child(selector)

	var check := CheckBox.new()
	check.text = "启用交互反馈"
	check.button_pressed = true
	check.tooltip_text = "CheckBox 适合多项可同时开启的设置"
	check.toggled.connect(_on_tooltip_toggled)
	content_cases.add_child(check)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	content_cases.add_child(action_row)
	var test_button := _make_button("点击测试", true)
	test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	test_button.pressed.connect(_on_test_clicked)
	action_row.add_child(test_button)
	var reset_button := _make_button("重置案例", false)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.pressed.connect(_on_reset_cases.bind(slider, selector, check))
	action_row.add_child(reset_button)

	interaction_log = Label.new()
	interaction_log.text = "事件日志：等待鼠标操作…"
	interaction_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_log.add_theme_color_override("font_color", Color("#ffe49a"))
	content_cases.add_child(interaction_log)


func _make_button(text: String, blue: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 45
	var color_name := "blue" if blue else "grey"
	button.add_theme_stylebox_override("normal", _texture_style("buttonLong_%s.png" % color_name, 12))
	button.add_theme_stylebox_override("hover", _texture_style("buttonLong_%s.png" % color_name, 12))
	button.add_theme_stylebox_override("pressed", _texture_style("buttonLong_%s_pressed.png" % color_name, 12))
	button.add_theme_stylebox_override("disabled", _texture_style("buttonLong_grey.png", 12))
	button.add_theme_color_override("font_color", Color("#fff8dc"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#fff0af"))
	return button


func _make_square_button(text: String, blue: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(45, 45)
	var color_name := "blue" if blue else "beige"
	button.add_theme_stylebox_override("normal", _texture_style("buttonSquare_%s.png" % color_name, 8))
	button.add_theme_stylebox_override("hover", _texture_style("buttonSquare_%s.png" % color_name, 8))
	button.add_theme_stylebox_override("pressed", _texture_style("buttonSquare_%s_pressed.png" % color_name, 8))
	button.add_theme_stylebox_override("disabled", _texture_style("buttonSquare_beige.png", 8))
	button.add_theme_color_override("font_color", Color("#3b3026"))
	button.add_theme_font_size_override("font_size", 20)
	return button


func _texture_style(file_name: String, margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(ASSET_PATH + file_name)
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func toggle_panel() -> void:
	panel.visible = not panel.visible


func open_panel() -> void:
	panel.show()


func close_panel() -> void:
	panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		toggle_panel()


func _switch_tab(index: int) -> void:
	content_status.visible = index == 0
	content_cases.visible = index == 1


func _spend_point(id: String) -> void:
	if available_points <= 0:
		return
	available_points -= 1
	match id:
		"health":
			player.max_health += 10
			player.heal(10)
		"damage": game.weapon_damage += 3
		"speed": player.move_speed += 15
		"pickup": player.pickup_radius += 20


func _on_advanced_toggled(enabled: bool) -> void:
	advanced_box.visible = enabled


func _on_preview_changed(value: float) -> void:
	preview_bar.value = value
	interaction_log.text = "事件日志：滑条 value_changed → %.0f" % value


func _on_theme_selected(index: int) -> void:
	var names := ["战士", "游侠", "工程师"]
	interaction_log.text = "事件日志：item_selected → %s主题" % names[index]


func _on_tooltip_toggled(enabled: bool) -> void:
	interaction_log.text = "事件日志：toggled → %s" % ("开启" if enabled else "关闭")


func _on_test_clicked() -> void:
	interaction_log.text = "事件日志：Button.pressed → 点击成功！"


func _on_reset_cases(slider: HSlider, selector: OptionButton, check: CheckBox) -> void:
	slider.value = 68
	selector.select(0)
	check.button_pressed = true
	interaction_log.text = "事件日志：案例控件已恢复默认值"


func _on_title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		drag_offset = event.position
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative
		var view_size := get_viewport().get_visible_rect().size
		panel.position.x = clampf(panel.position.x, 0, view_size.x - panel.size.x)
		panel.position.y = clampf(panel.position.y, 0, view_size.y - panel.size.y)


func _set_custom_cursor() -> void:
	var cursor: Texture2D = load(ASSET_PATH + "cursorHand_blue.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(3, 2))

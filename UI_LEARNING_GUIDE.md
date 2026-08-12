# Godot 素材化 UI 学习指南

## 1. 素材如何进入 Godot

图片放进项目目录后，Godot 会自动导入，并可通过：

```gdscript
var texture = load("res://assets/kenney_ui/panel_blue.png")
```

加载。`res://` 代表包含 `project.godot` 的项目根目录。

本示例素材来自 Kenney UI Pack (RPG Expansion)，许可证为 CC0。许可证副本位于
`assets/kenney_ui/LICENSE_KENNEY.txt`。

## 2. 面板为什么使用 NinePatchRect

直接拉伸一张带边框的图片，会导致四个角和边框一起变形。`NinePatchRect`
把图片划分成九个区域：

```text
固定角 | 横向拉伸 | 固定角
-------+----------+-------
纵向拉 | 中心拉伸 | 纵向拉
固定角 | 横向拉伸 | 固定角
```

示例在 `character_status_ui.gd` 中设置：

```gdscript
panel.patch_margin_left = 22
panel.patch_margin_top = 22
panel.patch_margin_right = 22
panel.patch_margin_bottom = 22
```

四个角保持原尺寸，中间区域适应面板大小。

## 3. 一张按钮图如何变成可交互按钮

Button 自己负责输入和信号，`StyleBoxTexture` 负责外观：

```gdscript
button.add_theme_stylebox_override("normal", normal_style)
button.add_theme_stylebox_override("hover", hover_style)
button.add_theme_stylebox_override("pressed", pressed_style)
button.add_theme_stylebox_override("disabled", disabled_style)
```

这样逻辑和美术状态分离。实际辅助函数是
`character_status_ui.gd` 中的 `_make_button()` 和 `_texture_style()`。

## 4. 常见 Control 布局节点

- `MarginContainer`：给内容增加安全边距。
- `VBoxContainer`：子控件从上到下排列。
- `HBoxContainer`：子控件从左到右排列。
- `NinePatchRect`：可拉伸的素材面板。
- `Label`：显示文本。
- `Button`：点击操作。
- `HSlider`：连续数值输入。
- `CheckBox` / `CheckButton`：开关。
- `OptionButton`：单选下拉菜单。
- `ProgressBar`：展示比例。

Container 会自动管理子控件的位置和尺寸。把控件放入 Container 后，不要再依赖
子控件的 `position` 手动排版，而应使用 `custom_minimum_size`、`size_flags_*`
和 Container 的 separation/margin。

## 5. 鼠标交互依靠信号

```gdscript
button.pressed.connect(_on_button_pressed)
check_box.toggled.connect(_on_toggled)
slider.value_changed.connect(_on_value_changed)
option_button.item_selected.connect(_on_item_selected)
```

信号的好处是 UI 控件不需要知道游戏的完整流程，只需在发生操作时通知接收者。

## 6. Tooltip 与 Mouse Filter

```gdscript
control.tooltip_text = "鼠标悬停时显示的说明"
```

`mouse_filter` 决定鼠标事件如何传播：

- `STOP`：控件接收事件，并阻止事件继续传给后面的控件。
- `PASS`：控件接收事件，然后继续传播。
- `IGNORE`：控件完全忽略鼠标。

全屏 UI 根节点通常设为 `IGNORE`，实际按钮和面板设为 `STOP`，否则透明的全屏
Control 可能挡住游戏区域的鼠标输入。

## 7. 拖拽窗口

标题栏监听 `gui_input`：

```gdscript
title_row.gui_input.connect(_on_title_gui_input)
```

鼠标左键按下时进入拖动状态，收到 `InputEventMouseMotion` 后使用
`event.relative` 修改面板位置。示例还通过 `clampf()` 防止窗口被拖出屏幕。

## 8. UI 如何读取角色状态

游戏创建 UI 后传入角色和游戏引用：

```gdscript
character_status_ui.configure(player, self)
```

UI 在 `_process()` 中读取生命、速度、伤害等数值。点击属性旁边的 `+` 后，
UI 修改对应属性，下一帧显示会自动更新。

更大型的项目建议改成“角色属性变化时发出信号”，避免 UI 每帧查询。

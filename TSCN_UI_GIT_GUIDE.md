# `.tscn` UI 与代码 UI 混合学习步骤

这个示例同时保留了两种 UI：

- `scenes/ui/quick_status_card.tscn`：在 Godot 编辑器中可视化搭建的快速状态卡。
- `scripts/character_status_ui.gd`：运行时完全通过代码创建的详细角色面板。

快速卡片的“详细”按钮会打开代码 UI，因此能直观看到两者协作。

## 一、在编辑器中查看这个 `.tscn`

1. 在 Godot 左下角“文件系统”中展开 `scenes/ui`。
2. 双击 `quick_status_card.tscn`。
3. 左上角场景树会显示：

```text
QuickStatusCard (CanvasLayer)
└─ Panel (PanelContainer)
   └─ Margin (MarginContainer)
	  └─ Rows (VBoxContainer)
		 ├─ Header (HBoxContainer)
		 │  ├─ Title (Label)
		 │  └─ DetailsButton (Button)
		 ├─ HealthBar (ProgressBar)
		 └─ Stats (Label)
```

4. 选择任一节点，在右侧 Inspector 修改文字、颜色、尺寸等属性。
5. 按 `Ctrl+S` 保存，然后运行主项目。

## 二、从零创建类似 UI 的步骤

1. 菜单选择“场景 → 新建场景 → 其他节点”，根节点选择 `CanvasLayer`。
2. 将根节点命名为 `QuickStatusCard`。
3. 添加 `PanelContainer`，用 Layout/Transform 设置卡片位置和尺寸。
4. 在 Panel 下依次加入 `MarginContainer` 和 `VBoxContainer`。
5. 在 VBox 中加入 Label、ProgressBar、Button 等控件。
6. 使用 Inspector 的 Theme Overrides 修改颜色、字号和 StyleBox。
7. 保存为 `res://scenes/ui/quick_status_card.tscn`。
8. 给根节点挂载 `quick_status_card.gd`。

## 三、`.tscn` 如何与脚本配合

`.tscn` 保存节点树和静态外观；脚本通过节点路径取得控件：

```gdscript
@onready var health_bar = $Panel/Margin/Rows/HealthBar
```

脚本只更新动态数据：

```gdscript
health_bar.max_value = player.max_health
health_bar.value = player.health
```

按钮也存在于 `.tscn`，但点击行为由脚本连接：

```gdscript
details_button.pressed.connect(_on_details_pressed)
```

## 四、主游戏如何实例化 `.tscn`

`game.gd` 先预加载场景：

```gdscript
const QuickStatusScene = preload("res://scenes/ui/quick_status_card.tscn")
```

然后创建实例、注入数据引用并加入场景树：

```gdscript
quick_status_card = QuickStatusScene.instantiate()
quick_status_card.configure(player, self)
add_child(quick_status_card)
```

最后通过自定义信号连接已有的代码 UI：

```gdscript
quick_status_card.details_requested.connect(character_status_ui.open_panel)
```

关系如下：

```text
quick_status_card.tscn（节点与外观）
		   ↓ 挂载
quick_status_card.gd（动态数据与按钮信号）
		   ↓ details_requested
character_status_ui.gd（纯代码详细面板）
```

## 五、观察 `.tscn` 在 Git 中的变化

当前修改特意没有提交。先运行：

```powershell
git -C C:\work\godot\demo status --short
git -C C:\work\godot\demo diff -- scenes/ui/quick_status_card.tscn
```

因为这是新文件，普通 `git diff` 默认不会显示未跟踪文件内容。可以先暂存：

```powershell
git -C C:\work\godot\demo add scenes/ui/quick_status_card.tscn
git -C C:\work\godot\demo diff --cached -- scenes/ui/quick_status_card.tscn
```

暂存不会提交，只是让 Git 开始追踪它。如果要取消暂存：

```powershell
git -C C:\work\godot\demo restore --staged scenes/ui/quick_status_card.tscn
```

在 Inspector 中把 Title 的 Text 从“场景 UI · 快速状态”改成别的内容并保存，
再次运行 `git diff`，会看到类似：

```diff
-text = "场景 UI · 快速状态"
+text = "我的角色状态"
```

调整颜色、边距或节点名称也会成为普通文本 diff。因此 `.tscn` 很适合 Git，
但多人同时调整同一个大型场景时仍可能发生文本冲突。通常把 UI 拆成多个小场景，
会比所有界面都塞进 `main.tscn` 更容易协作。

## 六、什么时候用哪种方式

- 固定布局、需要设计师反复调位置和外观：优先 `.tscn`。
- 大量重复控件、根据数据动态生成：代码创建更方便。
- 实际项目通常混合使用：`.tscn` 做结构和样式，脚本负责数据、动态生成和行为。

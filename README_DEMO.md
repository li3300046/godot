# Arena Survivor 学习 Demo

这是一个用 Godot 4 编写的类《土豆兄弟》基础玩法 Demo，不依赖外部素材。

## 操作

- `WASD` / 方向键：移动
- 武器会自动瞄准并攻击最近的敌人
- 击败敌人后拾取绿色经验晶体
- 升级时按 `1 / 2 / 3` 选择强化
- `R`：游戏结束后重新开始
- `Esc`：暂停/继续
- `C`：打开/关闭角色状态与 UI 交互教学面板

## 模块

- `scripts/game.gd`：整局流程、波次、计时、实体调度和碰撞结算
- `scripts/player.gd`：玩家移动、属性、受伤与绘制
- `scripts/enemy.gd`：敌人追踪、生命与绘制
- `scripts/bullet.gd`：子弹移动、伤害、穿透
- `scripts/xp_gem.gd`：经验掉落与吸附
- `scripts/hud.gd`：HUD、暂停/结算和升级三选一
- `scripts/character_status_ui.gd`：素材化角色状态面板与鼠标交互案例

## UI 公共素材

`assets/kenney_ui/` 中的面板、按钮、图标和鼠标指针来自
[Kenney UI Pack (RPG Expansion)](https://kenney.nl/assets/ui-pack-rpg-expansion)，
许可证为 Creative Commons CC0。原始许可证副本保存在
`assets/kenney_ui/LICENSE_KENNEY.txt`。

本 UI 演示了：

- `NinePatchRect`：用小尺寸面板素材无失真地拉伸大面板
- `StyleBoxTexture`：给 Button 设置普通、悬停、按下和禁用状态
- `tooltip_text`：鼠标悬停说明
- `pressed`、`toggled`、`value_changed`、`item_selected` 信号
- `HSlider`、`CheckBox`、`CheckButton`、`OptionButton`
- `gui_input`：鼠标拖动窗口
- 按钮禁用状态与动态角色属性绑定

主场景是 `main.tscn`。

更详细的素材、九宫格、布局容器和鼠标信号说明见 `UI_LEARNING_GUIDE.md`。

`.tscn` UI、纯代码 UI 的混合方式及 Git diff 练习见 `TSCN_UI_GIT_GUIDE.md`。

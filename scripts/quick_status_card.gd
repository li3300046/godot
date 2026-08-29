class_name QuickStatusCard
extends CanvasLayer

## 这个脚本不创建控件，只操作 quick_status_card.tscn 已经创建好的节点。
## 这正是“场景搭外观、代码填数据”的混合 UI 方式。

signal details_requested

@onready var health_bar: ProgressBar = $Panel/Margin/Rows/HealthBar
@onready var stats_label: Label = $Panel/Margin/Rows/Stats
@onready var details_button: Button = $Panel/Margin/Rows/Header/DetailsButton

var player: SurvivorPlayer
var game: Node


func configure(player_node: SurvivorPlayer, game_node: Node) -> void:
	player = player_node
	game = game_node


func _ready() -> void:
	details_button.pressed.connect(_on_details_pressed)


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(game):
		return
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	stats_label.text = "生命 %.0f/%.0f    伤害 %.0f    波次 %d" % [
		player.health, player.max_health, game.weapon_damage, game.wave
	]


func _on_details_pressed() -> void:
	details_requested.emit()

# AnimationPlayer、Sprite2D、动画状态与方向向量示例

这个示例把玩家的视觉节点放在 `scenes/player_visual.tscn`，把状态判断和方向计算放在 `scripts/player.gd`。

## 运行时可以观察什么

- 不按方向键时，玩家显示 `IDLE`，精灵轻微呼吸。
- 按 `WASD` 或方向键移动时，状态变成 `MOVING`，精灵上下弹跳。
- 碰到敌人受伤时，状态短暂变成 `HURT`，精灵红白闪烁。
- 玩家头上的箭头指向自动攻击目标；向左移动时精灵会水平翻转。

## 1. Sprite2D

`player_visual.tscn` 中有两个 `Sprite2D`：

- `BodySprite` 显示玩家图像。
- `AimArrow` 显示自动攻击的朝向。

这比 `_draw()` 更适合使用纹理、翻转精灵以及在 `AnimationPlayer` 中制作属性轨道。

## 2. AnimationPlayer

`AnimationPlayer` 保存三个动画：

- `idle`：循环改变 `BodySprite.scale`，形成呼吸效果。
- `moving`：循环改变 `position` 和 `scale`，形成移动弹跳。
- `hurt`：循环改变 `modulate`，形成受伤闪烁。

动画只负责“属性如何随时间变化”，脚本负责“什么时候播放哪段动画”。

## 3. 动画状态

`player.gd` 使用枚举定义有限状态：

```gdscript
enum AnimationState { IDLE, MOVING, HURT }
```

每个物理帧按优先级选择状态：受伤优先，其次判断输入向量是否为零。`_set_animation_state()` 只在状态改变时调用 `AnimationPlayer.play()`，避免每帧从头播放动画。

## 4. 向量和方向计算

- `Input.get_vector(...)` 返回长度不超过 1 的二维输入向量，所以斜向移动不会更快。
- `input_vector.normalized()` 得到纯方向，用 `x` 的正负判断角色朝左还是朝右。
- `direction_to()` 在玩家与最近敌人的位置之间计算标准化方向。
- `direction.angle()` 把方向向量转换为弧度，赋给 `AimArrow.rotation`。
- 子弹继续使用 `direction * speed * delta` 把方向、速度和帧时间转换为本帧位移。

完整的数据流是：

`按键 -> 输入向量 -> velocity -> MOVING/IDLE -> AnimationPlayer`

`玩家位置 + 敌人位置 -> direction_to() -> 箭头旋转 + 子弹移动`

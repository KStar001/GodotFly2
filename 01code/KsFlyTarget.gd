#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsFlyTarget
# 飞行道具：从右往左匀速飞行，供蜻蜓点水借力使用
# 加入 fly_target 组，FootBox 检测到后通知 KsInput
# 不与玩家物理碰撞，命中后由 KsInput._ConsumeFlyTarget() 销毁
#---------------------------------------------------------------------------------------------------
# 配置参数
const ConfigFlySpeed: float = 0.0 #4.0      # 飞行速度（米/秒，向左为负X）
const ConfigLifeTime: float = 20.0     # 最大存活时间（秒），超时自动销毁
#---------------------------------------------------------------------------------------------------
var CurLifeTimer: float = 0.0
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 给 Area3D 子节点加组（FootBox 感知到的是 Area3D，不是根节点）
	var AreaNode: Area3D = $Area3D
	if AreaNode != null:
		AreaNode.add_to_group("fly_target")
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	# 向左飞行
	position.x -= ConfigFlySpeed * delta
	# 超时销毁
	CurLifeTimer += delta
	if CurLifeTimer >= ConfigLifeTime:
		queue_free()
#---------------------------------------------------------------------------------------------------

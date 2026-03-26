#---------------------------------------------------------------------------------------------------
extends CharacterBody3D
class_name KsPlayer
#---------------------------------------------------------------------------------------------------
# 配置参数
const ConfigMoveSpeed: float = 5.0         # 向前速度（米/秒，3D单位）
const ConfigJumpSpeed: float = 8.0         # 跳跃初速度（向上）
const ConfigGravity: float = 20.0          # 重力加速度
const ConfigBounceSpeed: float = 5.0       # 被动落地弹起速度
const ConfigSpikeJumpSpeed: float = 12.0   # 突木桩击中后强制弹起速度
#---------------------------------------------------------------------------------------------------
# 当前垂直速度（水平速度固定，不单独存储）
var CurVerticalSpeed: float = 0.0
# 是否可以跳跃
var CurCanJump: bool = false
#---------------------------------------------------------------------------------------------------
# 节点引用（在场景中赋值）
@onready var NodeAnim: AnimationPlayer = $AnimationPlayer
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	KsWorld.SetMainPlayer(self)
#---------------------------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	_UpdateGravity(delta)
	_UpdateMove(delta)
	_UpdateJumpState()
#---------------------------------------------------------------------------------------------------
# 更新重力
func _UpdateGravity(delta: float) -> void:
	if not is_on_floor():
		CurVerticalSpeed -= ConfigGravity * delta
#---------------------------------------------------------------------------------------------------
# 更新移动（X轴前进，Y轴垂直，Z轴锁死为0）
func _UpdateMove(delta: float) -> void:
	velocity = Vector3(ConfigMoveSpeed, CurVerticalSpeed, 0.0)
	move_and_slide()
	# 落地后清零垂直速度
	if is_on_floor():
		CurVerticalSpeed = 0.0
	# 撞到头顶时垂直速度瞬间归零
	if is_on_ceiling():
		CurVerticalSpeed = 0.0
#---------------------------------------------------------------------------------------------------
# 更新跳跃状态
func _UpdateJumpState() -> void:
	CurCanJump = is_on_floor()
#---------------------------------------------------------------------------------------------------
# 执行跳跃
func DoJump() -> void:
	if not CurCanJump:
		return
	CurVerticalSpeed = ConfigJumpSpeed
	CurCanJump = false
#---------------------------------------------------------------------------------------------------
# 被动落地弹起
func DoBounce() -> void:
	CurVerticalSpeed = ConfigBounceSpeed
	# TODO: 扣血逻辑
#---------------------------------------------------------------------------------------------------
# 突木桩击中后强制弹起
func DoSpikeJump() -> void:
	CurVerticalSpeed = ConfigSpikeJumpSpeed
	CurCanJump = false
#---------------------------------------------------------------------------------------------------

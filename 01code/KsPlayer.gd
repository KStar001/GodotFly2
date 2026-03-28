#---------------------------------------------------------------------------------------------------
extends CharacterBody3D
class_name KsPlayer
#---------------------------------------------------------------------------------------------------
# 配置参数
const ConfigMoveSpeed: float = 3.0         # 向前速度（米/秒）
const ConfigJumpSpeed: float = 8.0         # 跳跃初速度
const ConfigGravity: float = 10.0          # 重力加速度
const ConfigBounceSpeed: float = 5.0       # 被动落地弹起速度
const ConfigSpikeJumpSpeed: float = 12.0   # 突木桩击中后强制弹起速度
const ConfigMaxYSpeedValue: float = -3.0   # Y轴速度下限（下落速度上限，负值=向下）
#---------------------------------------------------------------------------------------------------
# 角色状态枚举
enum EActorState
{
	ActorState_Run,        # 跑步（地面，始终前进）
	ActorState_JumpUp,     # 上升中
	ActorState_JumpDown,   # 下降中
	ActorState_CastSkill,  # 施放技能中
	ActorState_Hit,        # 受击中
	ActorState_Dead,       # 死亡
}
#---------------------------------------------------------------------------------------------------
# 当前角色状态
var CurActorState: EActorState = EActorState.ActorState_Run
# 当前正在施放的技能ID（-1=无技能）
var CurSkillId: int = -1
# 当前垂直速度
var CurVerticalSpeed: float = 0.0
# 是否可以跳跃
var CurCanJump: bool = false
# 技能叠加/锁定垂直速度
var CurSkillVelocityY: float = 0.0
# 技能叠加/锁定水平速度
var CurSkillVelocityX: float = 0.0
# 当前技能是否锁定水平速度（true=最终X轴速度=CurSkillVelocityX）
var CurSkillVelocityXLock: bool = false
# 当前技能是否锁定垂直速度（true=最终Y轴速度=CurSkillVelocityY，且不受下落速度上限限制）
var CurSkillVelocityYLock: bool = false
#---------------------------------------------------------------------------------------------------
# 子组件
var CompSkill: KsActorCompSkill = null
var CompAnim: KsActorCompAnimation = null
#---------------------------------------------------------------------------------------------------
@onready var NodeAnim: AnimationPlayer = $AnimationPlayer
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 初始化技能组件
	CompSkill = KsActorCompSkill.new()
	CompSkill.RefPlayer = self
	add_child(CompSkill)
	# 初始化动画组件
	CompAnim = KsActorCompAnimation.new()
	CompAnim.RefPlayer = self
	CompAnim.NodeAnim = NodeAnim
	add_child(CompAnim)
	KsWorld.SetMainPlayer(self)
#---------------------------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	_UpdateGravity(delta)
	_UpdateMove(delta)
	_UpdateJumpState()
	_UpdateActorState()
#---------------------------------------------------------------------------------------------------
# 更新重力（Y轴被锁定时不受重力影响）
func _UpdateGravity(delta: float) -> void:
	if CurSkillVelocityYLock:
		return
	if not is_on_floor():
		CurVerticalSpeed -= ConfigGravity * delta
#---------------------------------------------------------------------------------------------------
# 更新移动（X轴前进，Y轴垂直，Z轴锁死为0）
func _UpdateMove(delta: float) -> void:
	# 计算最终X轴速度
	var FinalVelocityX: float
	if CurSkillVelocityXLock:
		FinalVelocityX = CurSkillVelocityX
	else:
		FinalVelocityX = ConfigMoveSpeed + CurSkillVelocityX

	# 计算最终Y轴速度
	var FinalVelocityY: float
	if CurSkillVelocityYLock:
		# 锁定时直接取技能值，不受下落速度上限限制
		FinalVelocityY = CurSkillVelocityY
	else:
		# 限制下落速度上限（上升速度不限制）
		CurVerticalSpeed = max(CurVerticalSpeed, ConfigMaxYSpeedValue)
		FinalVelocityY = CurVerticalSpeed + CurSkillVelocityY

	velocity = Vector3(FinalVelocityX, FinalVelocityY, 0.0)
	move_and_slide()
	if is_on_floor():
		CurVerticalSpeed = 0.0
		CurSkillVelocityY = 0.0
	if is_on_ceiling():
		CurVerticalSpeed = 0.0
#---------------------------------------------------------------------------------------------------
# 更新跳跃状态
func _UpdateJumpState() -> void:
	CurCanJump = is_on_floor()
#---------------------------------------------------------------------------------------------------
# 每帧根据物理状态更新角色状态枚举
func _UpdateActorState() -> void:
	# 施放技能中或受击/死亡状态不被物理状态覆盖
	if CurActorState == EActorState.ActorState_CastSkill:
		return
	if CurActorState == EActorState.ActorState_Hit:
		return
	if CurActorState == EActorState.ActorState_Dead:
		return
	if is_on_floor():
		ChangeActorState(EActorState.ActorState_Run)
	elif CurVerticalSpeed > 0.0:
		ChangeActorState(EActorState.ActorState_JumpUp)
	else:
		ChangeActorState(EActorState.ActorState_JumpDown)
#---------------------------------------------------------------------------------------------------
# 统一状态变更入口
func ChangeActorState(NewState: EActorState, SkillId: int = -1) -> void:
	if CurActorState == NewState and CurSkillId == SkillId:
		return
	CurActorState = NewState
	CurSkillId = SkillId
	if CompAnim != null:
		CompAnim.OnActorStateChanged(CurActorState, CurSkillId)
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
	if CompAnim != null:
		CompAnim.PlayLandAnim()
	# TODO: 扣血逻辑
#---------------------------------------------------------------------------------------------------
# 突木桩击中后强制弹起
func DoSpikeJump() -> void:
	CurVerticalSpeed = ConfigSpikeJumpSpeed
	CurCanJump = false
#---------------------------------------------------------------------------------------------------
# 尝试施放技能（由 KsInput / KsWorld 调用）
func TryCastSkill(SkillId: int) -> bool:
	if CompSkill == null:
		return false
	var SkillData: KsTableSkill.SkillItem = KsTableSkill.GetSkillById(SkillId)
	if SkillData == null:
		return false
	return CompSkill.TryCastSkill(SkillData)
#---------------------------------------------------------------------------------------------------
# 技能开始回调（由 KsActorCompSkill 调用）
func OnSkillBegin(SkillData: KsTableSkill.SkillItem) -> void:
	ChangeActorState(EActorState.ActorState_CastSkill, SkillData.SkillId)
	# VelocityYClear=true：施放瞬间清零Y轴速度
	if SkillData.VelocityYClear:
		CurVerticalSpeed = 0.0
	# 根据技能类型执行通用效果
	match SkillData.SkillType:
		0: _ExecSkillA(SkillData)
		1: _ExecSkillB(SkillData)
		2: _ExecSkillC(SkillData)
#---------------------------------------------------------------------------------------------------
# 技能每帧更新回调（由 KsActorCompSkill 调用）
func OnSkillUpdate(SkillData: KsTableSkill.SkillItem, Delta: float) -> void:
	pass
#---------------------------------------------------------------------------------------------------
# 技能结束回调（由 KsActorCompSkill 调用）
func OnSkillEnd(SkillData: KsTableSkill.SkillItem) -> void:
	CurSkillId = -1
	CurSkillVelocityX = 0.0
	CurSkillVelocityY = 0.0
	CurSkillVelocityXLock = false
	CurSkillVelocityYLock = false
	# 恢复到物理驱动状态（_UpdateActorState 下一帧会自动接管）
	ChangeActorState(EActorState.ActorState_Run)
#---------------------------------------------------------------------------------------------------
# A类技能通用逻辑（闪避无敌帧）
func _ExecSkillA(SkillData: KsTableSkill.SkillItem) -> void:
	CurSkillVelocityX     = SkillData.VelocityX
	CurSkillVelocityXLock = SkillData.VelocityXLock
	CurSkillVelocityY     = SkillData.VelocityY
	CurSkillVelocityYLock = SkillData.VelocityYLock
	# TODO: 关闭受击碰撞层（无敌帧）
#---------------------------------------------------------------------------------------------------
# B类技能通用逻辑（跳跃借力）
func _ExecSkillB(SkillData: KsTableSkill.SkillItem) -> void:
	CurSkillVelocityX     = SkillData.VelocityX
	CurSkillVelocityXLock = SkillData.VelocityXLock
	CurSkillVelocityY     = SkillData.VelocityY
	CurSkillVelocityYLock = SkillData.VelocityYLock
	CurCanJump = false
#---------------------------------------------------------------------------------------------------
# C类技能通用逻辑（功法BUFF）
func _ExecSkillC(SkillData: KsTableSkill.SkillItem) -> void:
	CurSkillVelocityX     = SkillData.VelocityX
	CurSkillVelocityXLock = SkillData.VelocityXLock
	CurSkillVelocityY     = SkillData.VelocityY
	CurSkillVelocityYLock = SkillData.VelocityYLock
	# TODO: 根据 SkillData.BuffType 添加对应BUFF
#---------------------------------------------------------------------------------------------------

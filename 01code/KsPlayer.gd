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
const ConfigMaxHp: int = 10                # 最大血量（滴数）
const ConfigHitInvincibleTime: float = 1.5 # 受击无敌帧时长（秒）
const ConfigHitAnimTime: float = 0.8       # 受击动画状态持续时长（秒）
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
# 当前正在施放的技能ID（-1=无技能，多技能同时施放时取最新一个用于状态显示）
var CurSkillId: int = -1
# 当前垂直速度（物理层，受重力影响）
var CurVerticalSpeed: float = 0.0
# 是否可以跳跃
var CurCanJump: bool = false
# 当前血量
var CurHp: int = ConfigMaxHp
# 受击动画计时器（>0表示正在受击状态中）
var _CurHitAnimTimer: float = 0.0
# 受击无敌帧计时器（>0表示无敌帧有效）
var _CurHitInvincibleTimer: float = 0.0
#---------------------------------------------------------------------------------------------------
# 子组件
var CompSkill: KsActorCompSkill = null
var CompAnim: KsActorCompAnimation = null
var CompSkillFx: KsActorCompSkillFx = null
var CompBuff: KsActorCompBuff = null
#---------------------------------------------------------------------------------------------------
@onready var NodeAnim: AnimationPlayer = $AnimationPlayer
@onready var NodeFootBox: Area3D = $FootBox
@onready var NodeHitBox: Area3D = $HitBox
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
	# 初始化技能特效组件
	CompSkillFx = KsActorCompSkillFx.new()
	add_child(CompSkillFx)
	# 初始化Buff组件
	CompBuff = KsActorCompBuff.new()
	add_child(CompBuff)
	CompBuff.RefModelNode = $Knight
	# 连接 FootBox / HitBox 信号
	NodeFootBox.area_entered.connect(_OnFootBoxAreaEntered)
	NodeFootBox.area_exited.connect(_OnFootBoxAreaExited)
	NodeHitBox.area_entered.connect(_OnHitBoxAreaEntered)
	KsWorld.SetMainPlayer(self)
#---------------------------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	_UpdateTimers(delta)
	_UpdateGravity(delta)
	_UpdateMove(delta)
	_UpdateJumpState()
	_UpdateActorState()
#---------------------------------------------------------------------------------------------------
# 更新各类计时器
func _UpdateTimers(delta: float) -> void:
	# 受击动画计时
	if _CurHitAnimTimer > 0.0:
		_CurHitAnimTimer -= delta
		if _CurHitAnimTimer <= 0.0:
			_CurHitAnimTimer = 0.0
			# 受击动画结束，强制清除Hit状态，让 _UpdateActorState 下一帧修正为正确状态
			if CurActorState == EActorState.ActorState_Hit:
				CurActorState = EActorState.ActorState_Run
				if CompAnim != null:
					CompAnim.CurAnimName = ""  # 强制让动画组件重新刷新
					CompAnim.OnActorStateChanged(CurActorState, CurSkillId)
	# 受击无敌帧计时
	if _CurHitInvincibleTimer > 0.0:
		_CurHitInvincibleTimer -= delta
		if _CurHitInvincibleTimer <= 0.0:
			_CurHitInvincibleTimer = 0.0
			CompBuff.RemoveInvincible("hit_invincible")
#---------------------------------------------------------------------------------------------------
# 更新重力
# 只要没有任何技能锁定Y轴，就正常受重力
func _UpdateGravity(delta: float) -> void:
	if _CalcVelocityYLock():
		return
	if not is_on_floor():
		CurVerticalSpeed -= ConfigGravity * delta
#---------------------------------------------------------------------------------------------------
# 从三个技能槽合并计算最终X/Y速度
# 优先级：lock > 叠加非零值 > 不影响（零值）
func _CalcFinalVelocity() -> Vector2:
	# --- X轴 ---
	var FinalX: float
	var LockX: bool = false
	var LockXValue: float = 0.0
	var AddX: float = 0.0
	for SkillData in _GetActiveSkills():
		if SkillData.VelocityXLock:
			LockX = true
			LockXValue = SkillData.VelocityX
		elif SkillData.VelocityX != 0.0:
			AddX += SkillData.VelocityX
	if LockX:
		FinalX = LockXValue
	else:
		FinalX = ConfigMoveSpeed + AddX

	# --- Y轴 ---
	var FinalY: float
	var LockY: bool = false
	var LockYValue: float = 0.0
	var AddY: float = 0.0
	for SkillData in _GetActiveSkills():
		if SkillData.VelocityYLock:
			LockY = true
			LockYValue = SkillData.VelocityY
		elif SkillData.VelocityY != 0.0:
			AddY += SkillData.VelocityY
	if LockY:
		FinalY = LockYValue
	else:
		CurVerticalSpeed = max(CurVerticalSpeed, ConfigMaxYSpeedValue)
		FinalY = CurVerticalSpeed + AddY

	return Vector2(FinalX, FinalY)
#---------------------------------------------------------------------------------------------------
# 是否有任意技能锁定Y轴
func _CalcVelocityYLock() -> bool:
	for SkillData in _GetActiveSkills():
		if SkillData.VelocityYLock:
			return true
	return false
#---------------------------------------------------------------------------------------------------
# 获取当前所有激活中的技能数据列表（A/B/C顺序，null跳过）
func _GetActiveSkills() -> Array:
	var Result: Array = []
	if CompSkill == null:
		return Result
	if CompSkill.CurSkillDataA != null: Result.append(CompSkill.CurSkillDataA)
	if CompSkill.CurSkillDataB != null: Result.append(CompSkill.CurSkillDataB)
	if CompSkill.CurSkillDataC != null: Result.append(CompSkill.CurSkillDataC)
	return Result
#---------------------------------------------------------------------------------------------------
# 更新移动（X轴前进，Y轴垂直，Z轴锁死为0）
func _UpdateMove(delta: float) -> void:
	var FinalVel: Vector2 = _CalcFinalVelocity()
	velocity = Vector3(FinalVel.x, FinalVel.y, 0.0)
	move_and_slide()
	if is_on_floor():
		CurVerticalSpeed = 0.0
	if is_on_ceiling():
		CurVerticalSpeed = 0.0
#---------------------------------------------------------------------------------------------------
# 更新跳跃状态
func _UpdateJumpState() -> void:
	CurCanJump = is_on_floor()
#---------------------------------------------------------------------------------------------------
# 每帧根据物理状态更新角色状态枚举
func _UpdateActorState() -> void:
	if CurActorState == EActorState.ActorState_Hit:
		return
	if CurActorState == EActorState.ActorState_Dead:
		return
	# 有技能在执行中
	if CompSkill != null and CompSkill.IsAnyCasting():
		ChangeActorState(EActorState.ActorState_CastSkill, CurSkillId)
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
	CurSkillId = SkillData.SkillId
	# VelocityYClear=true：施放瞬间清零Y轴物理速度
	if SkillData.VelocityYClear:
		CurVerticalSpeed = 0.0
	# 显示技能名
	if KsWorld.CurUIHud != null and KsWorld.CurUIHud.NodeSkillName != null:
		KsWorld.CurUIHud.NodeSkillName.ShowSkillName(SkillData.SkillName)
	# 播放序列帧特效
	if CompSkillFx != null:
		CompSkillFx.OnSkillBegin(SkillData)
	# 无敌/霸体状态
	if SkillData.IsWuDi and CompBuff != null:
		CompBuff.AddInvincible("skill_" + str(SkillData.SkillId))
	if SkillData.IsBaTi and CompBuff != null:
		CompBuff.AddArmor("skill_" + str(SkillData.SkillId))
	# A类专用：无敌帧
	if SkillData.SkillType == 0:
		CurCanJump = false
		# TODO: 关闭受击碰撞层
	# B类专用
	elif SkillData.SkillType == 1:
		CurCanJump = false
	# C类专用
	elif SkillData.SkillType == 2:
		pass
		# TODO: 根据 BuffType 添加BUFF
#---------------------------------------------------------------------------------------------------
# 技能每帧更新回调（由 KsActorCompSkill 调用）
func OnSkillUpdate(SkillData: KsTableSkill.SkillItem, Delta: float) -> void:
	pass
#---------------------------------------------------------------------------------------------------
# 技能结束回调（由 KsActorCompSkill 调用）
func OnSkillEnd(SkillData: KsTableSkill.SkillItem) -> void:
	# 隐藏对应槽的序列帧特效
	if CompSkillFx != null:
		CompSkillFx.OnSkillEnd(SkillData)
	# 移除无敌/霸体状态
	if SkillData.IsWuDi and CompBuff != null:
		CompBuff.RemoveInvincible("skill_" + str(SkillData.SkillId))
	if SkillData.IsBaTi and CompBuff != null:
		CompBuff.RemoveArmor("skill_" + str(SkillData.SkillId))
	# 若已无任何技能，清空 CurSkillId
	if CompSkill != null and not CompSkill.IsAnyCasting():
		CurSkillId = -1
#---------------------------------------------------------------------------------------------------
# 受击处理（由 HitBox 碰撞回调调用）
# 根据当前 Buff 状态决定惩罚程度
func TakeHit() -> void:
	if CurActorState == EActorState.ActorState_Dead:
		return
	# 无敌状态：什么惩罚都没有
	if CompBuff != null and CompBuff.IsInvincible():
		return
	# 霸体状态：扣血 + 无敌帧，无受击动画
	if CompBuff != null and CompBuff.IsArmor():
		_ApplyHpDamage()
		_StartHitInvincible()
		return
	# 普通状态：扣血 + 受击动画 + 无敌帧
	_ApplyHpDamage()
	_StartHitAnim()
	_StartHitInvincible()
#---------------------------------------------------------------------------------------------------
# 扣血并检查死亡
func _ApplyHpDamage() -> void:
	CurHp -= 1
	# TODO: 通知 HUD 更新血量显示
	if CurHp <= 0:
		CurHp = 0
		_DoDie()
#---------------------------------------------------------------------------------------------------
# 开始受击动画状态
func _StartHitAnim() -> void:
	_CurHitAnimTimer = ConfigHitAnimTime
	ChangeActorState(EActorState.ActorState_Hit)
#---------------------------------------------------------------------------------------------------
# 开始受击无敌帧
func _StartHitInvincible() -> void:
	_CurHitInvincibleTimer = ConfigHitInvincibleTime
	if CompBuff != null:
		CompBuff.AddInvincible("hit_invincible")
#---------------------------------------------------------------------------------------------------
# 死亡处理
func _DoDie() -> void:
	if CompBuff != null:
		CompBuff.ClearAll()
	ChangeActorState(EActorState.ActorState_Dead)
	# TODO: 通知 KsWorld 触发通关失败流程
#---------------------------------------------------------------------------------------------------
# HitBox 信号回调：有碰撞体进入受击区域
func _OnHitBoxAreaEntered(area: Area3D) -> void:
	# 飞行道具：销毁 + 受击
	if area.is_in_group("fly_target"):
		var Root = area.get_parent()
		if Root != null and Root.has_method("Consume"):
			Root.Consume()
		TakeHit()
		return
	# 敌方攻击：走受击逻辑
	if area.is_in_group("enemy_attack"):
		TakeHit()
#---------------------------------------------------------------------------------------------------
# FootBox 信号回调：飞行道具进入脚底区域
func _OnFootBoxAreaEntered(area: Area3D) -> void:
	if not area.is_in_group("fly_target"):
		return
	var Input: KsInput = KsWorld.GetInput()
	if Input != null:
		Input.OnFlyTargetEntered(area)
#---------------------------------------------------------------------------------------------------
# FootBox 信号回调：飞行道具离开脚底区域
func _OnFootBoxAreaExited(area: Area3D) -> void:
	if not area.is_in_group("fly_target"):
		return
	var Input: KsInput = KsWorld.GetInput()
	if Input != null:
		Input.OnFlyTargetExited(area)
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
extends Node
class_name KsInput
#---------------------------------------------------------------------------------------------------
# 输入缓冲机制
# 负责接收所有玩家输入指令，优先立即执行；不满足条件时缓存一段时间，条件满足后自动触发。
# 指令分4类：Jump / SkillA / SkillB / SkillC
# 各类独立缓冲时长，同类指令覆盖（刷新计时）。
# 实时输入优先，缓冲指令次之。
#---------------------------------------------------------------------------------------------------
# 指令类型枚举
enum ECmdType
{
	Jump,    # 跳跃（第4类，0.1秒缓冲）
	SkillA,  # A类技能（闪避无敌帧）
	SkillB,  # B类技能（蜻蜓点水/借力）
	SkillC,  # C类技能（功法BUFF）
}
#---------------------------------------------------------------------------------------------------
# 各指令类型的缓冲时长（秒）
const ConfigBufferTime: Dictionary = {
	ECmdType.Jump:   0.1,
	ECmdType.SkillA: 0.5,
	ECmdType.SkillB: 0.5,
	ECmdType.SkillC: 0.5,
}
#---------------------------------------------------------------------------------------------------
# 缓冲槽结构：key = ECmdType，value = 到期时间（秒，基于 Time.get_ticks_msec()）
# -1 表示无缓冲
var _CurBufferExpire: Dictionary = {
	ECmdType.Jump:   -1.0,
	ECmdType.SkillA: -1.0,
	ECmdType.SkillB: -1.0,
	ECmdType.SkillC: -1.0,
}
# 缓冲槽记录的具体 SkillId（-1=未指定，走类型遍历）
var _CurBufferSkillId: Dictionary = {
	ECmdType.SkillA: -1,
	ECmdType.SkillB: -1,
	ECmdType.SkillC: -1,
}
#---------------------------------------------------------------------------------------------------
# 外部引用（由 KsWorld 赋值）
var RefPlayer: KsPlayer = null
# 脚底可踩飞行道具列表（FootBox 信号驱动，蜻蜓点水借力用）
var _FlyTargetList: Array = []
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	pass
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	_UpdateBufferedCmds()
#---------------------------------------------------------------------------------------------------
# 每帧检查缓冲槽，按优先级尝试执行
func _UpdateBufferedCmds() -> void:
	var NowSec: float = Time.get_ticks_msec() / 1000.0
	for CmdType in _CurBufferExpire.keys():
		var ExpireTime: float = _CurBufferExpire[CmdType]
		if ExpireTime < 0.0:
			continue
		# 缓冲已过期，丢弃
		if NowSec > ExpireTime:
			_ClearBuffer(CmdType)
			continue
		# 尝试执行（缓冲指令）
		if _TryExecuteCmd(CmdType):
			_ClearBuffer(CmdType)
#---------------------------------------------------------------------------------------------------
# 外部调用：玩家按下某个指令按钮（Jump/SkillA/B/C 类型级别）
# 实时优先：先尝试立即执行，失败再写入缓冲
func OnCmdPressed(CmdType: ECmdType) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	if _TryExecuteCmd(CmdType):
		_ClearBuffer(CmdType)
		return
	_WriteBuffer(CmdType)
#---------------------------------------------------------------------------------------------------
# 外部调用：玩家按下具体技能按钮（按 SkillId 施放，不走类型遍历）
func OnSkillIdPressed(SkillId: int) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	if RefPlayer == null:
		return
	var SkillData: KsTableSkill.SkillItem = KsTableSkill.GetSkillById(SkillId)
	if SkillData == null:
		return
	# CD冷却中，什么都不做
	if RefPlayer.CompSkill == null or not RefPlayer.CompSkill.IsSkillReady(SkillData.SkillType):
		return
	# 需要借力目标的技能（如蜻蜓点水）：写入缓冲，同时立即检查当前是否已有目标
	if SkillData.NeedTarget:
		_WriteBufferSkillId(SkillData.SkillType, SkillId)
		# 写入缓冲后立即尝试一次（应对"先踩到道具再按按钮"的情况）
		OnConditionMet(_SkillTypeToCmdType(SkillData.SkillType))
		return
	# 普通技能：实时优先，尝试立刻施放
	if RefPlayer.TryCastSkill(SkillId):
		var CmdType: ECmdType = _SkillTypeToCmdType(SkillData.SkillType)
		_ClearBuffer(CmdType)
		return
	# 施放失败（条件不满足），写入缓冲
	_WriteBufferSkillId(SkillData.SkillType, SkillId)
#---------------------------------------------------------------------------------------------------
# 外部调用：某个条件刚刚满足时（如进入可踩目标范围），立即检查对应缓冲
func OnConditionMet(CmdType: ECmdType) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	var NowSec: float = Time.get_ticks_msec() / 1000.0
	var ExpireTime: float = _CurBufferExpire[CmdType]
	if ExpireTime < 0.0 or NowSec > ExpireTime:
		return
	# 条件刚满足，立刻检查是否能执行
	if _TryExecuteCmd(CmdType):
		_ClearBuffer(CmdType)
#---------------------------------------------------------------------------------------------------
# 尝试执行指令，返回是否成功
func _TryExecuteCmd(CmdType: ECmdType) -> bool:
	if RefPlayer == null:
		return false
	match CmdType:
		ECmdType.Jump:
			return _TryExecJump()
		ECmdType.SkillA:
			return _TryExecSkillA()
		ECmdType.SkillB:
			return _TryExecSkillB()
		ECmdType.SkillC:
			return _TryExecSkillC()
	return false
#---------------------------------------------------------------------------------------------------
func _TryExecJump() -> bool:
	if not RefPlayer.CurCanJump:
		return false
	RefPlayer.DoJump()
	return true
#---------------------------------------------------------------------------------------------------
func _TryExecSkillA() -> bool:
	var BufferedId: int = _CurBufferSkillId.get(ECmdType.SkillA, -1)
	if BufferedId > 0:
		return RefPlayer != null and RefPlayer.TryCastSkill(BufferedId)
	return _TryCastFirstReadySkillByType(0)
#---------------------------------------------------------------------------------------------------
func _TryExecSkillB() -> bool:
	var BufferedId: int = _CurBufferSkillId.get(ECmdType.SkillB, -1)
	var SkillId: int = BufferedId if BufferedId > 0 else _GetFirstReadySkillIdByType(1)
	if SkillId <= 0:
		return false
	var SkillData: KsTableSkill.SkillItem = KsTableSkill.GetSkillById(SkillId)
	if SkillData == null:
		return false
	# 需要借力目标的技能（蜻蜓点水），检查脚底是否有可踩道具
	if SkillData.NeedTarget:
		if not _HasValidFlyTarget():
			return false
		if RefPlayer != null and RefPlayer.TryCastSkill(SkillId):
			_ConsumeFlyTarget()
			return true
		return false
	# 普通B类技能（梯云纵等），直接施放
	if RefPlayer != null:
		return RefPlayer.TryCastSkill(SkillId)
	return false
#---------------------------------------------------------------------------------------------------
func _TryExecSkillC() -> bool:
	var BufferedId: int = _CurBufferSkillId.get(ECmdType.SkillC, -1)
	if BufferedId > 0:
		return RefPlayer != null and RefPlayer.TryCastSkill(BufferedId)
	return _TryCastFirstReadySkillByType(2)
#---------------------------------------------------------------------------------------------------
# 按技能类型找第一个CD就绪的技能施放
func _TryCastFirstReadySkillByType(SkillType: int) -> bool:
	if RefPlayer == null:
		return false
	var AllSkills: Array = KsTableSkill.GetAllSkillsByType(SkillType)
	for SkillData in AllSkills:
		if RefPlayer.TryCastSkill(SkillData.SkillId):
			return true
	return false
#---------------------------------------------------------------------------------------------------
# 按技能类型找第一个CD就绪的技能ID（只查询，不施放）
func _GetFirstReadySkillIdByType(SkillType: int) -> int:
	if RefPlayer == null:
		return -1
	var AllSkills: Array = KsTableSkill.GetAllSkillsByType(SkillType)
	for SkillData in AllSkills:
		if RefPlayer.CompSkill != null and RefPlayer.CompSkill.IsSkillReady(SkillData.SkillType):
			return SkillData.SkillId
	return -1
#---------------------------------------------------------------------------------------------------
# 写入缓冲（覆盖同类旧指令，刷新到期时间）
func _WriteBuffer(CmdType: ECmdType) -> void:
	var NowSec: float = Time.get_ticks_msec() / 1000.0
	_CurBufferExpire[CmdType] = NowSec + ConfigBufferTime[CmdType]
#---------------------------------------------------------------------------------------------------
# 清除缓冲
func _ClearBuffer(CmdType: ECmdType) -> void:
	_CurBufferExpire[CmdType] = -1.0
	if _CurBufferSkillId.has(CmdType):
		_CurBufferSkillId[CmdType] = -1
#---------------------------------------------------------------------------------------------------
# 写入具体 SkillId 的缓冲（覆盖同类旧指令）
func _WriteBufferSkillId(SkillType: int, SkillId: int) -> void:
	var CmdType: ECmdType = _SkillTypeToCmdType(SkillType)
	_WriteBuffer(CmdType)
	_CurBufferSkillId[CmdType] = SkillId
#---------------------------------------------------------------------------------------------------
# 技能类型转指令类型
func _SkillTypeToCmdType(SkillType: int) -> ECmdType:
	match SkillType:
		0: return ECmdType.SkillA
		1: return ECmdType.SkillB
		2: return ECmdType.SkillC
	return ECmdType.SkillA
#---------------------------------------------------------------------------------------------------
# 获取debug信息字符串（供HUD显示）
func GetDebugText() -> String:
	var NowSec: float = Time.get_ticks_msec() / 1000.0
	var Lines: Array[String] = []
	Lines.append("[InputBuffer]")
	for CmdType in _CurBufferExpire.keys():
		var ExpireTime: float = _CurBufferExpire[CmdType]
		var CmdName: String = ECmdType.keys()[CmdType]
		if ExpireTime < 0.0 or NowSec > ExpireTime:
			Lines.append("  %s: -" % CmdName)
		else:
			var Remain: float = snappedf(ExpireTime - NowSec, 0.01)
			Lines.append("  %s: %.2fs" % [CmdName, Remain])
	return "\n".join(Lines)
#---------------------------------------------------------------------------------------------------
# FootBox 回调：飞行道具进入脚底范围
func OnFlyTargetEntered(area: Area3D) -> void:
	if not _FlyTargetList.has(area):
		_FlyTargetList.append(area)
	# 立刻检查 SkillB 缓冲是否可以触发
	OnConditionMet(ECmdType.SkillB)
#---------------------------------------------------------------------------------------------------
# FootBox 回调：飞行道具离开脚底范围
func OnFlyTargetExited(area: Area3D) -> void:
	_FlyTargetList.erase(area)
#---------------------------------------------------------------------------------------------------
# 是否有有效的飞行目标（过滤已销毁节点）
func _HasValidFlyTarget() -> bool:
	_FlyTargetList = _FlyTargetList.filter(func(a): return is_instance_valid(a))
	return _FlyTargetList.size() > 0
#---------------------------------------------------------------------------------------------------
# 消耗第一个飞行目标（触发蜻蜓点水时销毁道具）
func _ConsumeFlyTarget() -> void:
	_FlyTargetList = _FlyTargetList.filter(func(a): return is_instance_valid(a))
	if _FlyTargetList.size() > 0:
		var AreaNode = _FlyTargetList[0]
		_FlyTargetList.remove_at(0)
		# 调用根节点的 Consume() 销毁整个道具
		var Root = AreaNode.get_parent()
		if Root != null and Root.has_method("Consume"):
			Root.Consume()
		elif is_instance_valid(AreaNode):
			AreaNode.queue_free()
#---------------------------------------------------------------------------------------------------

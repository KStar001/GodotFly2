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
#---------------------------------------------------------------------------------------------------
# 外部引用（由 KsWorld 赋值）
var RefPlayer: KsPlayer = null
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
# 外部调用：玩家按下某个指令按钮
# 实时优先：先尝试立即执行，失败再写入缓冲
func OnCmdPressed(CmdType: ECmdType) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	# 实时输入，优先立即执行
	if _TryExecuteCmd(CmdType):
		_ClearBuffer(CmdType)  # 如果之前有缓冲也一并清掉
		return
	# 执行失败，写入缓冲（同类覆盖，刷新计时）
	_WriteBuffer(CmdType)
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
	# TODO: A类技能施放条件（CD判断等）
	return false
#---------------------------------------------------------------------------------------------------
func _TryExecSkillB() -> bool:
	# 梯云纵（1002）：无需借力目标，只判断CD
	return RefPlayer.TryCastSkill(1002)
#---------------------------------------------------------------------------------------------------
func _TryExecSkillC() -> bool:
	# TODO: C类技能施放条件（CD判断等）
	return false
#---------------------------------------------------------------------------------------------------
# 写入缓冲（覆盖同类旧指令，刷新到期时间）
func _WriteBuffer(CmdType: ECmdType) -> void:
	var NowSec: float = Time.get_ticks_msec() / 1000.0
	_CurBufferExpire[CmdType] = NowSec + ConfigBufferTime[CmdType]
#---------------------------------------------------------------------------------------------------
# 清除缓冲
func _ClearBuffer(CmdType: ECmdType) -> void:
	_CurBufferExpire[CmdType] = -1.0
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

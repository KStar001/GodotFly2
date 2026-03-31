#---------------------------------------------------------------------------------------------------
extends Node
class_name KsActorCompSkill
# 技能组件：管理三条CD轴、技能生命周期调度、每帧回调 KsPlayer
# A/B/C 三类各有独立槽，互不干扰，可同时施放
# 挂在 KsPlayer 节点下，通过 RefPlayer 引用父级
#---------------------------------------------------------------------------------------------------
# 三条独立CD轴剩余时间
var CurCdA: float = 0.0
var CurCdB: float = 0.0
var CurCdC: float = 0.0
# 三个独立技能槽（null = 该类无技能在执行）
var CurSkillDataA: KsTableSkill.SkillItem = null
var CurSkillDataB: KsTableSkill.SkillItem = null
var CurSkillDataC: KsTableSkill.SkillItem = null
# 三个独立技能计时器
var CurSkillTimerA: float = 0.0
var CurSkillTimerB: float = 0.0
var CurSkillTimerC: float = 0.0
# 玩家引用（由 KsPlayer 在 _ready 中赋值）
var RefPlayer: KsPlayer = null
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if KsWorld.CurGameStep != KsWorld.EGameStep.StepGaming:
		return
	_UpdateCd(delta)
	_UpdateSkill(delta)
#---------------------------------------------------------------------------------------------------
# 更新三条CD轴倒计时
func _UpdateCd(delta: float) -> void:
	if CurCdA > 0.0: CurCdA = max(0.0, CurCdA - delta)
	if CurCdB > 0.0: CurCdB = max(0.0, CurCdB - delta)
	if CurCdC > 0.0: CurCdC = max(0.0, CurCdC - delta)
#---------------------------------------------------------------------------------------------------
# 更新三个槽的技能计时，到期则结束
func _UpdateSkill(delta: float) -> void:
	if CurSkillDataA != null:
		CurSkillTimerA += delta
		if RefPlayer != null: RefPlayer.OnSkillUpdate(CurSkillDataA, delta)
		if CurSkillTimerA >= CurSkillDataA.Duration: _EndSkill(0)
	if CurSkillDataB != null:
		CurSkillTimerB += delta
		if RefPlayer != null: RefPlayer.OnSkillUpdate(CurSkillDataB, delta)
		if CurSkillTimerB >= CurSkillDataB.Duration: _EndSkill(1)
	if CurSkillDataC != null:
		CurSkillTimerC += delta
		if RefPlayer != null: RefPlayer.OnSkillUpdate(CurSkillDataC, delta)
		if CurSkillTimerC >= CurSkillDataC.Duration: _EndSkill(2)
#---------------------------------------------------------------------------------------------------
# 尝试施放技能，返回是否成功
func TryCastSkill(SkillData: KsTableSkill.SkillItem) -> bool:
	if SkillData == null:
		return false
	if not IsSkillReady(SkillData.SkillType):
		return false
	# 同类槽有技能正在执行，先结束它
	if _GetCurSkillData(SkillData.SkillType) != null:
		_EndSkill(SkillData.SkillType)
	# 写入CD和槽位
	_ApplyCd(SkillData)
	_SetCurSkillData(SkillData.SkillType, SkillData)
	_SetCurSkillTimer(SkillData.SkillType, 0.0)
	if RefPlayer != null:
		RefPlayer.OnSkillBegin(SkillData)
	return true
#---------------------------------------------------------------------------------------------------
# 技能结束（SkillType: 0=A 1=B 2=C）
func _EndSkill(SkillType: int) -> void:
	var EndData: KsTableSkill.SkillItem = _GetCurSkillData(SkillType)
	if EndData == null:
		return
	_SetCurSkillData(SkillType, null)
	_SetCurSkillTimer(SkillType, 0.0)
	if RefPlayer != null:
		RefPlayer.OnSkillEnd(EndData)
#---------------------------------------------------------------------------------------------------
# 写入CD
func _ApplyCd(SkillData: KsTableSkill.SkillItem) -> void:
	match SkillData.SkillType:
		0: CurCdA = SkillData.CdDuration
		1: CurCdB = SkillData.CdDuration
		2: CurCdC = SkillData.CdDuration
#---------------------------------------------------------------------------------------------------
# 获取槽位数据
func _GetCurSkillData(SkillType: int) -> KsTableSkill.SkillItem:
	match SkillType:
		0: return CurSkillDataA
		1: return CurSkillDataB
		2: return CurSkillDataC
	return null
#---------------------------------------------------------------------------------------------------
# 设置槽位数据
func _SetCurSkillData(SkillType: int, Data: KsTableSkill.SkillItem) -> void:
	match SkillType:
		0: CurSkillDataA = Data
		1: CurSkillDataB = Data
		2: CurSkillDataC = Data
#---------------------------------------------------------------------------------------------------
# 获取槽位计时器
func _GetCurSkillTimer(SkillType: int) -> float:
	match SkillType:
		0: return CurSkillTimerA
		1: return CurSkillTimerB
		2: return CurSkillTimerC
	return 0.0
#---------------------------------------------------------------------------------------------------
# 设置槽位计时器
func _SetCurSkillTimer(SkillType: int, Value: float) -> void:
	match SkillType:
		0: CurSkillTimerA = Value
		1: CurSkillTimerB = Value
		2: CurSkillTimerC = Value
#---------------------------------------------------------------------------------------------------
# 查询对应类型技能是否CD好了
func IsSkillReady(SkillType: int) -> bool:
	match SkillType:
		0: return CurCdA <= 0.0
		1: return CurCdB <= 0.0
		2: return CurCdC <= 0.0
	return false
#---------------------------------------------------------------------------------------------------
# 获取对应类型CD剩余时间
func GetCdRemain(SkillType: int) -> float:
	match SkillType:
		0: return CurCdA
		1: return CurCdB
		2: return CurCdC
	return 0.0
#---------------------------------------------------------------------------------------------------
# 是否有任意技能正在执行
func IsAnyCasting() -> bool:
	return CurSkillDataA != null or CurSkillDataB != null or CurSkillDataC != null
#---------------------------------------------------------------------------------------------------
# 调试文本
func GetDebugText() -> String:
	var CdText = "CD A:%.1f B:%.1f C:%.1f" % [CurCdA, CurCdB, CurCdC]
	var Lines: Array[String] = [CdText]
	if CurSkillDataA != null:
		Lines.append("技能A: %s (%.1f/%.1f)" % [CurSkillDataA.SkillName, CurSkillTimerA, CurSkillDataA.Duration])
	if CurSkillDataB != null:
		Lines.append("技能B: %s (%.1f/%.1f)" % [CurSkillDataB.SkillName, CurSkillTimerB, CurSkillDataB.Duration])
	if CurSkillDataC != null:
		Lines.append("技能C: %s (%.1f/%.1f)" % [CurSkillDataC.SkillName, CurSkillTimerC, CurSkillDataC.Duration])
	return "\n".join(Lines)
#---------------------------------------------------------------------------------------------------

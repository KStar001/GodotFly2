#---------------------------------------------------------------------------------------------------
extends Node
class_name KsActorCompSkill
# 技能组件：管理三条CD轴、技能生命周期调度、每帧回调 KsPlayer
# 挂在 KsPlayer 节点下，通过 RefPlayer 引用父级
#---------------------------------------------------------------------------------------------------
# 三条独立CD轴剩余时间
var CurCdA: float = 0.0   # A类技能CD
var CurCdB: float = 0.0   # B类技能CD
var CurCdC: float = 0.0   # C类技能CD
# 当前正在执行的技能数据（null = 无技能在执行）
var CurSkillData: KsTableSkill.SkillItem = null
# 当前技能已执行时长
var CurSkillTimer: float = 0.0
# 玩家引用（由 KsPlayer 在 _ready 中赋值）
var RefPlayer: KsPlayer = null
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	_UpdateCd(delta)
	_UpdateSkill(delta)
#---------------------------------------------------------------------------------------------------
# 更新三条CD轴倒计时
func _UpdateCd(delta: float) -> void:
	if CurCdA > 0.0:
		CurCdA = max(0.0, CurCdA - delta)
	if CurCdB > 0.0:
		CurCdB = max(0.0, CurCdB - delta)
	if CurCdC > 0.0:
		CurCdC = max(0.0, CurCdC - delta)
#---------------------------------------------------------------------------------------------------
# 更新当前技能持续时长，时间到则结束技能
func _UpdateSkill(delta: float) -> void:
	if CurSkillData == null:
		return
	CurSkillTimer += delta
	# 每帧回调 KsPlayer
	if RefPlayer != null:
		RefPlayer.OnSkillUpdate(CurSkillData, delta)
	# Duration 到了，技能结束
	if CurSkillTimer >= CurSkillData.Duration:
		_EndSkill()
#---------------------------------------------------------------------------------------------------
# 尝试施放技能，返回是否成功
func TryCastSkill(SkillData: KsTableSkill.SkillItem) -> bool:
	if SkillData == null:
		return false
	# 判断对应CD是否冷却完毕
	if not IsSkillReady(SkillData.SkillType):
		return false
	# 如果有技能正在执行，先强制结束
	if CurSkillData != null:
		_EndSkill()
	# 写入CD
	_ApplyCd(SkillData)
	# 开始技能
	CurSkillData = SkillData
	CurSkillTimer = 0.0
	# 回调 KsPlayer 执行技能效果
	if RefPlayer != null:
		RefPlayer.OnSkillBegin(SkillData)
	return true
#---------------------------------------------------------------------------------------------------
# 技能结束（Duration到期或外部强制结束）
func _EndSkill() -> void:
	if CurSkillData == null:
		return
	var EndData: KsTableSkill.SkillItem = CurSkillData
	CurSkillData = null
	CurSkillTimer = 0.0
	# 回调 KsPlayer 清理技能效果
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
# 调试文本
func GetDebugText() -> String:
	var CdText = "CD A:%.1f B:%.1f C:%.1f" % [CurCdA, CurCdB, CurCdC]
	var SkillText = "技能: 无"
	if CurSkillData != null:
		SkillText = "技能: %s (%.1f/%.1f)" % [CurSkillData.SkillName, CurSkillTimer, CurSkillData.Duration]
	return CdText + "\n" + SkillText
#---------------------------------------------------------------------------------------------------

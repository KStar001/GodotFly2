#---------------------------------------------------------------------------------------------------
# 动画组件：监听 KsPlayer 状态枚举，自动驱动 AnimationPlayer
# 切换动画时统一使用 0.2 秒融合（AnimationPlayer.play with blend_time）
#---------------------------------------------------------------------------------------------------
class_name KsActorCompAnimation
extends Node
#---------------------------------------------------------------------------------------------------
# 动画名常量
const AnimWalk:      String = "Movement/Walking_A"
const AnimRun:       String = "Movement/Running_A"
const AnimJumpStart: String = "Movement/Jump_Start"
const AnimJumpIdle:  String = "Movement/Jump_Idle"
const AnimJumpLand:  String = "Movement/Jump_Land"
const AnimIdle:      String = "General/Idle_B"
const AnimHit:       String = "General/Hit_A"
const AnimDeath:     String = "General/Death_A"

# 动画融合时长（秒）
const BlendTime: float = 0.2
#---------------------------------------------------------------------------------------------------
# 引用
var RefPlayer: KsPlayer = null
var NodeAnim: AnimationPlayer = null
#---------------------------------------------------------------------------------------------------
# 内部状态
var CurAnimName: String = ""
var CurActorState: KsPlayer.EActorState = KsPlayer.EActorState.ActorState_Run
var CurSkillId: int = -1
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	pass
#---------------------------------------------------------------------------------------------------
# 由 KsPlayer.ChangeActorState() 调用，通知状态变更
func OnActorStateChanged(NewState: KsPlayer.EActorState, NewSkillId: int) -> void:
	CurActorState = NewState
	CurSkillId = NewSkillId
	_RefreshAnim()
#---------------------------------------------------------------------------------------------------
# 根据当前状态决定播放哪个动画
func _RefreshAnim() -> void:
	if NodeAnim == null:
		return
	var TargetAnim: String = _GetTargetAnim()
	if TargetAnim == CurAnimName:
		return
	CurAnimName = TargetAnim
	NodeAnim.play(CurAnimName, BlendTime)
#---------------------------------------------------------------------------------------------------
# 根据状态枚举返回对应动画名
func _GetTargetAnim() -> String:
	match CurActorState:
		KsPlayer.EActorState.ActorState_Run:
			return AnimRun
		KsPlayer.EActorState.ActorState_JumpUp:
			return AnimJumpStart
		KsPlayer.EActorState.ActorState_JumpDown:
			return AnimJumpIdle
		KsPlayer.EActorState.ActorState_CastSkill:
			# 施放技能期间暂时复用 JumpIdle，后续可按 SkillId 细化
			return AnimJumpIdle
		KsPlayer.EActorState.ActorState_Hit:
			return AnimHit
		KsPlayer.EActorState.ActorState_Dead:
			return AnimDeath
	return AnimIdle
#---------------------------------------------------------------------------------------------------
# 外部调用：播放落地动画（一次性，播完后状态机自动接管）
func PlayLandAnim() -> void:
	if NodeAnim == null:
		return
	CurAnimName = AnimJumpLand
	NodeAnim.play(AnimJumpLand, BlendTime)
	# 落地动画播完后，连接一次性信号切回 Run
	if not NodeAnim.animation_finished.is_connected(_OnLandAnimFinished):
		NodeAnim.animation_finished.connect(_OnLandAnimFinished, CONNECT_ONE_SHOT)
#---------------------------------------------------------------------------------------------------
func _OnLandAnimFinished(AnimName: String) -> void:
	if AnimName == AnimJumpLand:
		CurAnimName = ""  # 清空，让 _RefreshAnim 下次能正常切换
		_RefreshAnim()
#---------------------------------------------------------------------------------------------------

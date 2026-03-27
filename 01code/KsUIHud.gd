#---------------------------------------------------------------------------------------------------
extends CanvasLayer
class_name KsUIHud
#---------------------------------------------------------------------------------------------------
# 按钮原始文字
const LabelJump: String    = "跳跃"
const LabelSkillB: String  = "梯云纵"
const LabelSkillC: String  = "御风术"
#---------------------------------------------------------------------------------------------------
# 节点引用
@onready var NodeJumpButton: Button       = $JumpButton
@onready var NodeSkillBButton: Button     = $SkillBButton
@onready var NodeSkillCButton: Button     = $SkillCButton
@onready var NodeDebugLabel: Label        = $DebugLabel
@onready var NodeStoryTestButton: Button  = $StoryTestButton
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	KsWorld.SetMainUIHud(self)
	NodeStoryTestButton.pressed.connect(_OnStoryTestButtonPressed)
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	_UpdateSkillButtonLabel()
#---------------------------------------------------------------------------------------------------
# 技能施放期间，对应按钮显示剩余时长；其余按钮恢复原始文字
func _UpdateSkillButtonLabel() -> void:
	# 默认先全部恢复原始文字
	NodeJumpButton.text   = LabelJump
	NodeSkillBButton.text = LabelSkillB
	NodeSkillCButton.text = LabelSkillC

	if KsWorld.CurPlayer == null:
		return
	var CompSkill: KsActorCompSkill = KsWorld.CurPlayer.CompSkill
	if CompSkill == null or CompSkill.CurSkillData == null:
		return

	# 计算剩余时长
	var Remain: float = max(0.0, CompSkill.CurSkillData.Duration - CompSkill.CurSkillTimer)
	var RemainText: String = "%.1f" % Remain

	# 根据技能类型决定显示在哪个按钮上
	# SkillType: 0=A类闪避(JumpButton) 1=B类跳跃(SkillBButton) 2=C类功法(SkillCButton)
	match CompSkill.CurSkillData.SkillType:
		0: NodeJumpButton.text   = RemainText
		1: NodeSkillBButton.text = RemainText
		2: NodeSkillCButton.text = RemainText
#---------------------------------------------------------------------------------------------------
# 剧情测试按钮：触发剧情1
func _OnStoryTestButtonPressed() -> void:
	if KsWorld.StoryManager == null:
		return
	if KsWorld.StoryManager.IsPlaying():
		return
	KsWorld.StoryManager.PlayStory(1, func(): print("KsUIHud: 剧情1播放完毕"))
#---------------------------------------------------------------------------------------------------
# 更新调试文本
func UpdateDebugText(Text: String) -> void:
	NodeDebugLabel.text = Text
#---------------------------------------------------------------------------------------------------

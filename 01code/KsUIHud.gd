#---------------------------------------------------------------------------------------------------
extends CanvasLayer
class_name KsUIHud
#---------------------------------------------------------------------------------------------------
# UI槽位尺寸（与 KsSkillButton 默认尺寸一致）
const ConfigSlotSize: Vector2 = Vector2(160.0, 160.0)
#---------------------------------------------------------------------------------------------------
# A类技能ID列表（左下角，上2下3）
const SkillIdsA: Array[int] = [1001, 1005, 0, 0, 0]
# B类技能ID列表（右下角，上2下3）
const SkillIdsB: Array[int] = [1002, 1003, 0, 0, 0]
# C类技能ID列表（B类上方，一排3个）
const SkillIdsC: Array[int] = [1004, 0, 0]
#---------------------------------------------------------------------------------------------------
# 按钮节点引用列表
var _BtnsA: Array[KsSkillButton] = []
var _BtnsB: Array[KsSkillButton] = []
var _BtnsC: Array[KsSkillButton] = []
#---------------------------------------------------------------------------------------------------
@onready var NodeSafePanel: Control = $SafePanel
@onready var NodeContentRoot: Control = $SafePanel/ContentRoot
@onready var NodeDebugLabel: Label = $SafePanel/ContentRoot/TopRight/DebugLabel
@onready var NodeStoryTestButton: Button = $SafePanel/ContentRoot/BottomLeft/LeftLayout/StoryTestButton
@onready var NodeA_RowTop: HBoxContainer = $SafePanel/ContentRoot/BottomLeft/LeftLayout/SkillGroupA/RowTop
@onready var NodeA_RowBottom: HBoxContainer = $SafePanel/ContentRoot/BottomLeft/LeftLayout/SkillGroupA/RowBottom
@onready var NodeB_RowTop: HBoxContainer = $SafePanel/ContentRoot/BottomRight/RightLayout/SkillGroupB/RowTop
@onready var NodeB_RowBottom: HBoxContainer = $SafePanel/ContentRoot/BottomRight/RightLayout/SkillGroupB/RowBottom
@onready var NodeC_Row: HBoxContainer = $SafePanel/ContentRoot/BottomRight/RightLayout/SkillGroupC/Row
var NodeSkillName: KsUISkillName = null
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	KsWorld.SetMainUIHud(self)
	_BuildSkillButtons()
	NodeStoryTestButton.pressed.connect(_OnStoryTestButtonPressed)
	# 创建技能名显示控件
	NodeSkillName = KsUISkillName.new()
	NodeContentRoot.add_child(NodeSkillName)
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	_UpdateSkillButtons()
	_UpdateDebugLabel()
#---------------------------------------------------------------------------------------------------
# 构建所有技能按钮（容器化，相对布局）
func _BuildSkillButtons() -> void:
	_BtnsA = []
	_BtnsB = []
	_BtnsC = []
	_BtnsA.append_array(_CreateButtonsInRow(NodeA_RowTop, [SkillIdsA[0], SkillIdsA[1]]))
	_BtnsA.append_array(_CreateButtonsInRow(NodeA_RowBottom, [SkillIdsA[2], SkillIdsA[3], SkillIdsA[4]]))
	_BtnsB.append_array(_CreateButtonsInRow(NodeB_RowTop, [SkillIdsB[0], SkillIdsB[1]]))
	_BtnsB.append_array(_CreateButtonsInRow(NodeB_RowBottom, [SkillIdsB[2], SkillIdsB[3], SkillIdsB[4]]))
	_BtnsC.append_array(_CreateButtonsInRow(NodeC_Row, [SkillIdsC[0], SkillIdsC[1], SkillIdsC[2]]))
#---------------------------------------------------------------------------------------------------
# 在指定行容器中按顺序创建技能按钮（保留空槽）
func _CreateButtonsInRow(RowNode: HBoxContainer, SkillIds: Array[int]) -> Array[KsSkillButton]:
	var Result: Array[KsSkillButton] = []
	for SkillId in SkillIds:
		var Btn: KsSkillButton = KsSkillButton.new()
		Btn.custom_minimum_size = ConfigSlotSize
		Btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		Btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		RowNode.add_child(Btn)
		if SkillId > 0:
			Btn.Setup(SkillId)
			var CapturedId: int = SkillId
			Btn.OnPressed = func(): _OnSkillPressed(CapturedId)
		else:
			Btn.visible = false
		Result.append(Btn)
	return Result
#---------------------------------------------------------------------------------------------------
# 每帧刷新所有按钮状态
func _UpdateSkillButtons() -> void:
	for Btn in _BtnsA:
		if Btn.visible: Btn.UpdateState()
	for Btn in _BtnsB:
		if Btn.visible: Btn.UpdateState()
	for Btn in _BtnsC:
		if Btn.visible: Btn.UpdateState()
#---------------------------------------------------------------------------------------------------
# 技能按下回调
func _OnSkillPressed(SkillId: int) -> void:
	if KsWorld.CompInput == null:
		return
	KsWorld.CompInput.OnSkillIdPressed(SkillId)
#---------------------------------------------------------------------------------------------------
# 剧情测试按钮
func _OnStoryTestButtonPressed() -> void:
	if KsWorld.StoryManager == null:
		return
	if KsWorld.StoryManager.IsPlaying():
		return
	KsWorld.StoryManager.PlayStory(1, func(): print("KsUIHud: 剧情1播放完毕"))
#---------------------------------------------------------------------------------------------------
# 更新调试文本
func _UpdateDebugLabel() -> void:
	if KsWorld.CompInput == null:
		return
	var Text: String = KsWorld.CompInput.GetDebugText()
	if KsWorld.CurPlayer != null:
		Text += "\nHP: " + str(KsWorld.CurPlayer.CurHp) + " / " + str(KsWorld.CurPlayer.ConfigMaxHp)
	NodeDebugLabel.text = Text
#---------------------------------------------------------------------------------------------------
# 供 KsWorld.SetMainUIHud 绑定跳跃按钮（跳跃不是技能，单独保留）
var NodeJumpButton: Button = null
var NodeSkillBButton: Button = null  # 兼容旧引用，实际不用
var NodeSkillCButton: Button = null  # 兼容旧引用，实际不用
#---------------------------------------------------------------------------------------------------
# 更新调试文本（外部调用接口，保持兼容）
func UpdateDebugText(Text: String) -> void:
	NodeDebugLabel.text = Text
#---------------------------------------------------------------------------------------------------

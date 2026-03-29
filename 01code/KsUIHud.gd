#---------------------------------------------------------------------------------------------------
extends CanvasLayer
class_name KsUIHud
#---------------------------------------------------------------------------------------------------
# 屏幕基准尺寸
const ScreenW: float = 1920.0
const ScreenH: float = 1080.0
# 按钮尺寸与间距
const BtnSize: float = 160.0
const BtnGap: float = 10.0
# 底部安全区留白
const PadBottom: float = 40.0
# 左右边距
const PadSide: float = 20.0
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
@onready var NodeDebugLabel: Label = $DebugLabel
@onready var NodeStoryTestButton: Button = $StoryTestButton
var NodeSkillName: KsUISkillName = null
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	KsWorld.SetMainUIHud(self)
	_BuildSkillButtons()
	NodeStoryTestButton.pressed.connect(_OnStoryTestButtonPressed)
	# 创建技能名显示控件
	NodeSkillName = KsUISkillName.new()
	add_child(NodeSkillName)
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	_UpdateSkillButtons()
	_UpdateDebugLabel()
#---------------------------------------------------------------------------------------------------
# 构建所有技能按钮
func _BuildSkillButtons() -> void:
	_BtnsA = _CreateButtonGroup(SkillIdsA, _CalcPositionsLeft())
	_BtnsB = _CreateButtonGroup(SkillIdsB, _CalcPositionsRight())
	_BtnsC = _CreateButtonGroup(SkillIdsC, _CalcPositionsC())
#---------------------------------------------------------------------------------------------------
# 批量创建按钮组，positions 对应每个槽位的左上角坐标
func _CreateButtonGroup(SkillIds: Array[int], Positions: Array[Vector2]) -> Array[KsSkillButton]:
	var Result: Array[KsSkillButton] = []
	for i in range(SkillIds.size()):
		var Btn = KsSkillButton.new()
		add_child(Btn)
		Btn.position = Positions[i]
		var SkillId: int = SkillIds[i]
		if SkillId > 0:
			Btn.Setup(SkillId)
			# 捕获 SkillId 到闭包
			var CapturedId: int = SkillId
			Btn.OnPressed = func(): _OnSkillPressed(CapturedId)
		else:
			Btn.visible = false  # 空槽隐藏
		Result.append(Btn)
	return Result
#---------------------------------------------------------------------------------------------------
# A类（左下角）：上2下3，上排居中对齐下排
# 下排3个：最左起，上排2个居中
func _CalcPositionsLeft() -> Array[Vector2]:
	var Positions: Array[Vector2] = []
	var BaseY_Bottom: float = ScreenH - PadBottom - BtnSize               # 下排Y
	var BaseY_Top: float    = BaseY_Bottom - BtnGap - BtnSize             # 上排Y
	# 下排3个 X坐标
	var Row2StartX: float = PadSide
	for i in range(3):
		Positions.append(Vector2(Row2StartX + i * (BtnSize + BtnGap), BaseY_Bottom))
	# 上排2个 X坐标（与下排3个居中对齐：下排总宽 = 3*160+2*10=500，上排总宽=2*160+1*10=330，偏移=(500-330)/2=85）
	var Row1OffsetX: float = (3 * BtnSize + 2 * BtnGap - (2 * BtnSize + BtnGap)) / 2.0
	for i in range(2):
		Positions.append(Vector2(Row2StartX + Row1OffsetX + i * (BtnSize + BtnGap), BaseY_Top))
	# 返回顺序：上2在前，下3在后（对应 SkillIdsA[0~4]）
	var Reordered: Array[Vector2] = []
	Reordered.append(Positions[3])  # 上左
	Reordered.append(Positions[4])  # 上右
	Reordered.append(Positions[0])  # 下左
	Reordered.append(Positions[1])  # 下中
	Reordered.append(Positions[2])  # 下右
	return Reordered
#---------------------------------------------------------------------------------------------------
# B类（右下角）：上2下3，镜像A类
func _CalcPositionsRight() -> Array[Vector2]:
	var Positions: Array[Vector2] = []
	var BaseY_Bottom: float = ScreenH - PadBottom - BtnSize
	var BaseY_Top: float    = BaseY_Bottom - BtnGap - BtnSize
	# 下排3个 X坐标（从右边算起）
	var Row2EndX: float = ScreenW - PadSide - BtnSize
	for i in range(3):
		Positions.append(Vector2(Row2EndX - i * (BtnSize + BtnGap), BaseY_Bottom))
	# 上排2个 X坐标
	var Row1OffsetX: float = (3 * BtnSize + 2 * BtnGap - (2 * BtnSize + BtnGap)) / 2.0
	for i in range(2):
		Positions.append(Vector2(Row2EndX - BtnSize - BtnGap - Row1OffsetX - i * (BtnSize + BtnGap) + BtnGap, BaseY_Top))
	# 返回顺序：上2在前，下3在后
	var Reordered: Array[Vector2] = []
	Reordered.append(Positions[4])  # 上右
	Reordered.append(Positions[3])  # 上左
	Reordered.append(Positions[2])  # 下右
	Reordered.append(Positions[1])  # 下中
	Reordered.append(Positions[0])  # 下左
	return Reordered
#---------------------------------------------------------------------------------------------------
# C类（B类上方）：一排3个，右对齐
func _CalcPositionsC() -> Array[Vector2]:
	var Positions: Array[Vector2] = []
	# B类上排的Y坐标
	var BBaseY_Bottom: float = ScreenH - PadBottom - BtnSize
	var BBaseY_Top: float    = BBaseY_Bottom - BtnGap - BtnSize
	var CBaseY: float        = BBaseY_Top - BtnGap - BtnSize
	# 右对齐：最右按钮右边缘与B类下排最右按钮对齐
	var RightEdge: float = ScreenW - PadSide
	for i in range(3):
		var X: float = RightEdge - (i + 1) * BtnSize - i * BtnGap
		Positions.append(Vector2(X, CBaseY))
	# 翻转为从左到右
	Positions.reverse()
	return Positions
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
	if KsWorld.CurPlayer != null and KsWorld.CurPlayer.CompSkill != null:
		Text += "\n" + KsWorld.CurPlayer.CompSkill.GetDebugText()
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

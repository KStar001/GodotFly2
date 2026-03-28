#---------------------------------------------------------------------------------------------------
# 技能按钮控件
# 显示技能图标、名称、类型底色、CD遮罩、持续时间进度条
# 通过 Setup(SkillId) 初始化，每帧调用 UpdateState() 刷新显示
#---------------------------------------------------------------------------------------------------
class_name KsSkillButton
extends Control
#---------------------------------------------------------------------------------------------------
# 三种类型底色（A/B/C类）
const ColorTypeA: Color = Color("#E8613A")  # 橙红：闪避类
const ColorTypeB: Color = Color("#3AAEE8")  # 蓝绿：跳跃类
const ColorTypeC: Color = Color("#A85FE8")  # 紫金：功法类

# 按钮尺寸
const BtnSize: Vector2 = Vector2(160, 160)
# CD遮罩颜色
const CdOverlayColor: Color = Color(0.0, 0.0, 0.0, 0.6)
#---------------------------------------------------------------------------------------------------
# 绑定的技能ID（-1=未绑定）
var CurSkillId: int = -1
# 缓存技能数据
var CurSkillData: KsTableSkill.SkillItem = null
#---------------------------------------------------------------------------------------------------
# 子节点
var _NodeBg: ColorRect = null        # 底色背景
var _NodeIcon: TextureRect = null    # 技能图标
var _NodeName: Label = null          # 技能名字
var _NodeCdOverlay: ColorRect = null # CD遮罩（从上往下收缩）
var _NodeCdLabel: Label = null       # CD剩余秒数
var _NodeDurBar: ColorRect = null    # 持续时间进度条（底部）
var _NodeTouch: Button = null        # 透明点击区域
#---------------------------------------------------------------------------------------------------
# 外部回调：按钮被按下时触发
var OnPressed: Callable = Callable()
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	custom_minimum_size = BtnSize
	size = BtnSize
	_BuildNodes()
#---------------------------------------------------------------------------------------------------
func _BuildNodes() -> void:
	# 底色背景
	_NodeBg = ColorRect.new()
	_NodeBg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_NodeBg.color = Color("#444444")
	add_child(_NodeBg)

	# 技能图标
	_NodeIcon = TextureRect.new()
	_NodeIcon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_NodeIcon.offset_top = 8.0
	_NodeIcon.offset_bottom = -36.0
	_NodeIcon.offset_left = 8.0
	_NodeIcon.offset_right = -8.0
	_NodeIcon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_NodeIcon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	add_child(_NodeIcon)

	# 技能名字（底部）
	_NodeName = Label.new()
	_NodeName.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_NodeName.offset_top = -32.0
	_NodeName.offset_bottom = 0.0
	_NodeName.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_NodeName.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_NodeName.add_theme_font_size_override("font_size", 20)
	_NodeName.add_theme_color_override("font_color", Color.WHITE)
	add_child(_NodeName)

	# CD遮罩（全覆盖，高度动态缩小）
	_NodeCdOverlay = ColorRect.new()
	_NodeCdOverlay.color = CdOverlayColor
	_NodeCdOverlay.position = Vector2(0, 0)
	_NodeCdOverlay.size = BtnSize
	_NodeCdOverlay.visible = false
	add_child(_NodeCdOverlay)

	# CD剩余秒数（遮罩中央）
	_NodeCdLabel = Label.new()
	_NodeCdLabel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_NodeCdLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_NodeCdLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_NodeCdLabel.add_theme_font_size_override("font_size", 36)
	_NodeCdLabel.add_theme_color_override("font_color", Color.WHITE)
	_NodeCdLabel.visible = false
	add_child(_NodeCdLabel)

	# 持续时间进度条（底部细条）
	_NodeDurBar = ColorRect.new()
	_NodeDurBar.color = Color(1.0, 1.0, 0.3, 0.9)  # 黄色
	_NodeDurBar.position = Vector2(0, BtnSize.y - 8)
	_NodeDurBar.size = Vector2(BtnSize.x, 8)
	_NodeDurBar.visible = false
	add_child(_NodeDurBar)

	# 透明点击区域（最顶层）
	_NodeTouch = Button.new()
	_NodeTouch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_NodeTouch.flat = true
	_NodeTouch.modulate = Color(1, 1, 1, 0)
	_NodeTouch.pressed.connect(_OnTouchPressed)
	add_child(_NodeTouch)
#---------------------------------------------------------------------------------------------------
# 绑定技能，初始化显示
func Setup(SkillId: int) -> void:
	CurSkillId = SkillId
	CurSkillData = KsTableSkill.GetSkillById(SkillId)
	if CurSkillData == null:
		return
	# 底色
	match CurSkillData.SkillType:
		0: _NodeBg.color = ColorTypeA
		1: _NodeBg.color = ColorTypeB
		2: _NodeBg.color = ColorTypeC
	# 名字
	_NodeName.text = CurSkillData.SkillName
	# 图标
	if not CurSkillData.SkillIcon.is_empty():
		var IconPath = "res://04skillimg/" + CurSkillData.SkillIcon + ".png"
		var Tex = load(IconPath)
		if Tex != null:
			_NodeIcon.texture = Tex
#---------------------------------------------------------------------------------------------------
# 每帧刷新状态（由 KsUIHud._process 调用）
func UpdateState() -> void:
	if CurSkillData == null or KsWorld.CurPlayer == null:
		return
	var CompSkill: KsActorCompSkill = KsWorld.CurPlayer.CompSkill
	if CompSkill == null:
		return

	var SkillType: int = CurSkillData.SkillType

	# --- CD状态 ---
	var CdRemain: float = CompSkill.GetCdRemain(SkillType)
	var IsOnCd: bool = CdRemain > 0.0
	if IsOnCd:
		# 遮罩高度 = 按钮高度 * CD剩余比例
		var CdRatio: float = CdRemain / CurSkillData.CdDuration
		var OverlayH: float = BtnSize.y * CdRatio
		_NodeCdOverlay.position = Vector2(0, BtnSize.y - OverlayH)
		_NodeCdOverlay.size = Vector2(BtnSize.x, OverlayH)
		_NodeCdOverlay.visible = true
		_NodeCdLabel.text = "%.1f" % CdRemain
		_NodeCdLabel.visible = true
	else:
		_NodeCdOverlay.visible = false
		_NodeCdLabel.visible = false

	# --- 持续时间进度条 ---
	var CurSkillSlot: KsTableSkill.SkillItem = CompSkill._GetCurSkillData(SkillType)
	var IsActive: bool = (CurSkillSlot != null and CurSkillSlot.SkillId == CurSkillId)
	if IsActive:
		var Timer: float = CompSkill._GetCurSkillTimer(SkillType)
		var DurRatio: float = 1.0 - clampf(Timer / CurSkillData.Duration, 0.0, 1.0)
		_NodeDurBar.size = Vector2(BtnSize.x * DurRatio, 8)
		_NodeDurBar.visible = true
	else:
		_NodeDurBar.visible = false
#---------------------------------------------------------------------------------------------------
func _OnTouchPressed() -> void:
	if OnPressed.is_valid():
		OnPressed.call()
#---------------------------------------------------------------------------------------------------

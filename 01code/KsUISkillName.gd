#---------------------------------------------------------------------------------------------------
extends Control
class_name KsUISkillName
# 技能名显示控件
# 技能施放成功时在屏幕右侧中间显示技能名，停留后淡出消失
# 最多同时显示 3 条，新条目从底部插入，旧条目向上推
#---------------------------------------------------------------------------------------------------
const ConfigFontSize: int = 48          # 字号
const ConfigStayTime: float = 0.8       # 停留时间（秒）
const ConfigFadeTime: float = 0.3       # 淡出时间（秒）
const ConfigMaxCount: int = 3           # 最多同时显示条数
const ConfigLineHeight: float = 64.0    # 每行高度
const ConfigRightMargin: float = 24.0   # 距屏幕右边缘距离
#---------------------------------------------------------------------------------------------------
# 用两个平行数组代替内嵌 class，避免编辑器解析崩溃
var _LabelNodes: Array = []   # Array[Label]
var _Timers: Array = []        # Array[float]，正值=停留中，负值=淡出中
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	var ToRemoveIdx: Array = []
	for i in _Timers.size():
		_Timers[i] -= delta
		var Lbl: Label = _LabelNodes[i]
		if _Timers[i] >= 0.0:
			Lbl.modulate.a = 1.0
		else:
			var FadeProgress: float = -_Timers[i] / ConfigFadeTime
			Lbl.modulate.a = 1.0 - clampf(FadeProgress, 0.0, 1.0)
			if FadeProgress >= 1.0:
				ToRemoveIdx.append(i)
	# 从后往前删，避免索引偏移
	for i in range(ToRemoveIdx.size() - 1, -1, -1):
		var Idx: int = ToRemoveIdx[i]
		_LabelNodes[Idx].queue_free()
		_LabelNodes.remove_at(Idx)
		_Timers.remove_at(Idx)
	_UpdatePositions()
#---------------------------------------------------------------------------------------------------
func ShowSkillName(SkillName: String) -> void:
	# 超出最大数量时移除最旧的
	while _LabelNodes.size() >= ConfigMaxCount:
		_LabelNodes[0].queue_free()
		_LabelNodes.remove_at(0)
		_Timers.remove_at(0)
	var Lbl: Label = _CreateLabel(SkillName)
	add_child(Lbl)
	_LabelNodes.append(Lbl)
	_Timers.append(ConfigStayTime)
	_UpdatePositions()
#---------------------------------------------------------------------------------------------------
func _CreateLabel(SkillName: String) -> Label:
	var Lbl = Label.new()
	Lbl.text = SkillName
	Lbl.add_theme_font_size_override("font_size", ConfigFontSize)
	Lbl.add_theme_color_override("font_color", Color.WHITE)
	Lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	Lbl.add_theme_constant_override("shadow_offset_x", 2)
	Lbl.add_theme_constant_override("shadow_offset_y", 2)
	Lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Lbl.modulate.a = 1.0
	return Lbl
#---------------------------------------------------------------------------------------------------
func _UpdatePositions() -> void:
	var ScreenH: float = get_viewport_rect().size.y
	var ScreenW: float = get_viewport_rect().size.x
	var TotalH: float = _LabelNodes.size() * ConfigLineHeight
	var StartY: float = (ScreenH - TotalH) / 2.0
	for i in _LabelNodes.size():
		var Lbl: Label = _LabelNodes[i]
		Lbl.size = Vector2(400.0, ConfigLineHeight)
		Lbl.position = Vector2(ScreenW - 400.0 - ConfigRightMargin, StartY + i * ConfigLineHeight)
#---------------------------------------------------------------------------------------------------

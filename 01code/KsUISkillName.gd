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
# 单条记录
class SkillNameEntry:
	var NodeLabel: Label = null
	var CurTimer: float = 0.0           # 计时器（正值=停留中，负值=淡出中）
#---------------------------------------------------------------------------------------------------
var _Entries: Array = []  # Array[SkillNameEntry]
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 铺满全屏，自身不拦截鼠标
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	var ToRemove: Array = []
	for Entry in _Entries:
		Entry.CurTimer -= delta
		if Entry.CurTimer >= 0.0:
			# 停留阶段，完全不透明
			Entry.NodeLabel.modulate.a = 1.0
		else:
			# 淡出阶段
			var FadeProgress: float = -Entry.CurTimer / ConfigFadeTime
			Entry.NodeLabel.modulate.a = 1.0 - clampf(FadeProgress, 0.0, 1.0)
			if FadeProgress >= 1.0:
				ToRemove.append(Entry)
	for Entry in ToRemove:
		Entry.NodeLabel.queue_free()
		_Entries.erase(Entry)
	_UpdatePositions()
#---------------------------------------------------------------------------------------------------
# 外部调用：显示一个技能名
func ShowSkillName(SkillName: String) -> void:
	# 超出最大数量时移除最旧的
	while _Entries.size() >= ConfigMaxCount:
		var Oldest = _Entries[0]
		Oldest.NodeLabel.queue_free()
		_Entries.remove_at(0)
	# 创建新条目
	var Entry = SkillNameEntry.new()
	Entry.CurTimer = ConfigStayTime
	Entry.NodeLabel = _CreateLabel(SkillName)
	add_child(Entry.NodeLabel)
	_Entries.append(Entry)
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
# 更新所有条目的位置（右侧中间，多条从下往上排列）
func _UpdatePositions() -> void:
	var ScreenH: float = get_viewport_rect().size.y
	var ScreenW: float = get_viewport_rect().size.x
	var TotalH: float = _Entries.size() * ConfigLineHeight
	# 最底部条目的Y坐标（整体垂直居中）
	var StartY: float = (ScreenH - TotalH) / 2.0
	for i in _Entries.size():
		var Entry = _Entries[i]
		var Lbl = Entry.NodeLabel
		Lbl.size = Vector2(400.0, ConfigLineHeight)
		Lbl.position = Vector2(ScreenW - 400.0 - ConfigRightMargin, StartY + i * ConfigLineHeight)
#---------------------------------------------------------------------------------------------------

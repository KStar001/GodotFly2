#---------------------------------------------------------------------------------------------------
extends CanvasLayer
class_name KsUIStory
# 剧情显示层
# 职责：根据 KsStoryManager 的指令显示静态图或过场对话框
# 点击屏幕任意位置触发 TrySkipStep
#---------------------------------------------------------------------------------------------------
# 节点引用
@onready var NodeBg: ColorRect              = $NodeBg
@onready var NodeImage: TextureRect         = $NodeImage
@onready var NodeDialogBox: Panel           = $NodeDialogBox
@onready var NodeSpeaker: Label             = $NodeDialogBox/NodeSpeaker
@onready var NodeText: Label                = $NodeDialogBox/NodeText
@onready var NodePortraitLeft: TextureRect  = $NodePortraitLeft
@onready var NodePortraitRight: TextureRect = $NodePortraitRight
#---------------------------------------------------------------------------------------------------
# 逐字显示相关
const ConfigTextSpeed: float = 0.04        # 每个字的显示间隔（秒）
var _FullText: String = ""                 # 完整文字内容
var _CurCharIndex: int = 0                 # 当前已显示到第几个字
var _TextTimer: float = 0.0               # 逐字计时器
var _IsTyping: bool = false               # 是否正在逐字播放
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 默认隐藏
	visible = false
	KsWorld.SetMainUIStory(self)
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _IsTyping:
		_UpdateTyping(delta)
#---------------------------------------------------------------------------------------------------
# 逐字显示更新
func _UpdateTyping(delta: float) -> void:
	_TextTimer += delta
	while _TextTimer >= ConfigTextSpeed and _CurCharIndex < _FullText.length():
		_TextTimer -= ConfigTextSpeed
		_CurCharIndex += 1
		NodeText.text = _FullText.left(_CurCharIndex)
	if _CurCharIndex >= _FullText.length():
		_IsTyping = false
#---------------------------------------------------------------------------------------------------
# 点击屏幕任意位置（兼容触屏和鼠标）
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var IsClick: bool = false
	if event is InputEventScreenTouch and event.pressed:
		IsClick = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		IsClick = true
	if not IsClick:
		return
	# 如果文字还没打完，先跳过逐字直接显示全文
	if _IsTyping:
		_FinishTyping()
	else:
		KsWorld.StoryManager.TrySkipStep()
	get_viewport().set_input_as_handled()
#---------------------------------------------------------------------------------------------------
# 显示当前步骤（由 KsStoryManager 调用）
func ShowStep(Step: KsTableStory.StoryItem) -> void:
	visible = true
	match Step.Type:
		"image":
			_ShowImage(Step)
		"dialog":
			_ShowDialog(Step)
#---------------------------------------------------------------------------------------------------
# 显示静态图
func _ShowImage(Step: KsTableStory.StoryItem) -> void:
	# 加载图片
	var ImgPath: String = "res://21otherres/story/" + Step.ImageRes
	var Tex = load(ImgPath) as Texture2D
	if Tex != null:
		NodeImage.texture = Tex
		NodeImage.visible = true
	else:
		printerr("KsUIStory: 找不到图片 " + ImgPath)
		NodeImage.visible = false
	# 旁白文字（text不为空时显示在对话框，无立绘）
	if Step.Text.is_empty():
		NodeDialogBox.visible = false
		NodePortraitLeft.visible = false
		NodePortraitRight.visible = false
	else:
		NodePortraitLeft.visible = false
		NodePortraitRight.visible = false
		NodeSpeaker.text = ""
		_StartTyping(Step.Text)
		NodeDialogBox.visible = true
#---------------------------------------------------------------------------------------------------
# 显示过场对话框
func _ShowDialog(Step: KsTableStory.StoryItem) -> void:
	# 立绘：有 image 字段时加载，放左侧（后续可按 speaker 决定左右）
	if not Step.ImageRes.is_empty():
		var PortraitPath: String = "res://21otherres/portrait/" + Step.ImageRes + ".png"
		var Tex = load(PortraitPath) as Texture2D
		if Tex != null:
			NodePortraitLeft.texture = Tex
			NodePortraitLeft.visible = true
		else:
			printerr("KsUIStory: 找不到立绘 " + PortraitPath)
			NodePortraitLeft.visible = false
	else:
		NodePortraitLeft.visible = false
	NodePortraitRight.visible = false
	# 说话人 + 文字
	NodeSpeaker.text = Step.Speaker
	_StartTyping(Step.Text)
	NodeDialogBox.visible = true
#---------------------------------------------------------------------------------------------------
# 开始逐字显示
func _StartTyping(Text: String) -> void:
	_FullText     = Text
	_CurCharIndex = 0
	_TextTimer    = 0.0
	_IsTyping     = true
	NodeText.text = ""
#---------------------------------------------------------------------------------------------------
# 跳过逐字，直接显示全文
func _FinishTyping() -> void:
	_IsTyping     = false
	_CurCharIndex = _FullText.length()
	NodeText.text = _FullText
#---------------------------------------------------------------------------------------------------
# 隐藏整个剧情界面（由 KsStoryManager 在剧情结束时调用）
func HideStory() -> void:
	visible = false
	NodeImage.texture       = null
	NodePortraitLeft.texture  = null
	NodePortraitRight.texture = null
	NodeText.text    = ""
	NodeSpeaker.text = ""
#---------------------------------------------------------------------------------------------------

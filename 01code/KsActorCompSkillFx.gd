#---------------------------------------------------------------------------------------------------
# 技能序列帧特效组件
# 挂在 KsPlayer 下，管理三个独立的 AnimatedSprite3D 节点（分别对应 A/B/C 三类技能槽）
# A/B/C 三类技能可同时施放，各自的序列帧动画互不干扰
# Billboard 模式，始终朝向摄像机
#---------------------------------------------------------------------------------------------------
class_name KsActorCompSkillFx
extends Node
#---------------------------------------------------------------------------------------------------
# 三个独立的 AnimatedSprite3D 节点，对应 A/B/C 三槽
var _SpriteNodeA: AnimatedSprite3D = null
var _SpriteNodeB: AnimatedSprite3D = null
var _SpriteNodeC: AnimatedSprite3D = null
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	_SpriteNodeA = _CreateSpriteNode("SkillFxA")
	_SpriteNodeB = _CreateSpriteNode("SkillFxB")
	_SpriteNodeC = _CreateSpriteNode("SkillFxC")
#---------------------------------------------------------------------------------------------------
# 创建一个 AnimatedSprite3D 子节点并挂到 KsPlayer 下
func _CreateSpriteNode(NodeName: String) -> AnimatedSprite3D:
	var Node = AnimatedSprite3D.new()
	Node.name = NodeName
	Node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	Node.visible = false
	get_parent().add_child(Node)
	return Node
#---------------------------------------------------------------------------------------------------
# 根据技能类型（SkillType）返回对应的 Sprite 节点
# SkillType: 0=A类, 1=B类, 2=C类
func _GetSpriteNode(SkillType: int) -> AnimatedSprite3D:
	match SkillType:
		0: return _SpriteNodeA
		1: return _SpriteNodeB
		2: return _SpriteNodeC
	return null
#---------------------------------------------------------------------------------------------------
# 技能开始：加载资源、设置偏移、播放动画
# SkillData.SkillType 决定使用哪个槽的节点
func OnSkillBegin(SkillData: KsTableSkill.SkillItem) -> void:
	var SpriteNode = _GetSpriteNode(SkillData.SkillType)
	if SpriteNode == null:
		return
	# 没有配特效资源，直接隐藏
	if SkillData.FxResPath.is_empty():
		SpriteNode.visible = false
		return
	# 加载 SpriteFrames 资源
	var FinalResPath = "res://04skillimg/" + SkillData.FxResPath + ".tres"
	var Frames = load(FinalResPath)
	if Frames == null:
		printerr("KsActorCompSkillFx: 无法加载资源 " + SkillData.FxResPath)
		SpriteNode.visible = false
		return
	# 设置偏移
	SpriteNode.position = Vector3(SkillData.FxOffsetX, SkillData.FxOffsetY, SkillData.FxOffsetZ)
	# 设置帧资源并播放
	SpriteNode.sprite_frames = Frames
	SpriteNode.visible = true
	SpriteNode.play("default")
	# 非循环：播完自动隐藏
	if not SkillData.FxLoop:
		if not SpriteNode.animation_finished.is_connected(_OnAnimFinishedA) and SkillData.SkillType == 0:
			SpriteNode.animation_finished.connect(_OnAnimFinishedA)
		elif not SpriteNode.animation_finished.is_connected(_OnAnimFinishedB) and SkillData.SkillType == 1:
			SpriteNode.animation_finished.connect(_OnAnimFinishedB)
		elif not SpriteNode.animation_finished.is_connected(_OnAnimFinishedC) and SkillData.SkillType == 2:
			SpriteNode.animation_finished.connect(_OnAnimFinishedC)
	else:
		# 循环模式：断开非循环信号（防止残留）
		_DisconnectFinishSignal(SkillData.SkillType)
#---------------------------------------------------------------------------------------------------
# 技能结束：隐藏对应槽的特效
func OnSkillEnd(SkillData: KsTableSkill.SkillItem) -> void:
	var SpriteNode = _GetSpriteNode(SkillData.SkillType)
	if SpriteNode == null:
		return
	_DisconnectFinishSignal(SkillData.SkillType)
	SpriteNode.stop()
	SpriteNode.visible = false
#---------------------------------------------------------------------------------------------------
# 断开指定槽的 animation_finished 信号
func _DisconnectFinishSignal(SkillType: int) -> void:
	match SkillType:
		0:
			if _SpriteNodeA != null and _SpriteNodeA.animation_finished.is_connected(_OnAnimFinishedA):
				_SpriteNodeA.animation_finished.disconnect(_OnAnimFinishedA)
		1:
			if _SpriteNodeB != null and _SpriteNodeB.animation_finished.is_connected(_OnAnimFinishedB):
				_SpriteNodeB.animation_finished.disconnect(_OnAnimFinishedB)
		2:
			if _SpriteNodeC != null and _SpriteNodeC.animation_finished.is_connected(_OnAnimFinishedC):
				_SpriteNodeC.animation_finished.disconnect(_OnAnimFinishedC)
#---------------------------------------------------------------------------------------------------
# 三个槽各自的非循环播完回调
func _OnAnimFinishedA() -> void:
	if _SpriteNodeA != null:
		_SpriteNodeA.visible = false

func _OnAnimFinishedB() -> void:
	if _SpriteNodeB != null:
		_SpriteNodeB.visible = false

func _OnAnimFinishedC() -> void:
	if _SpriteNodeC != null:
		_SpriteNodeC.visible = false
#---------------------------------------------------------------------------------------------------

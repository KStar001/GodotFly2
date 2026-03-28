#---------------------------------------------------------------------------------------------------
# 技能序列帧特效组件
# 挂在 KsPlayer 下，管理一个 AnimatedSprite3D 节点
# 技能开始时显示并播放对应序列帧，技能结束时隐藏
# Billboard 模式，始终朝向摄像机
#---------------------------------------------------------------------------------------------------
class_name KsActorCompSkillFx
extends Node
#---------------------------------------------------------------------------------------------------
# 内部 AnimatedSprite3D 节点
var _SpriteNode: AnimatedSprite3D = null
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 创建 AnimatedSprite3D 子节点
	_SpriteNode = AnimatedSprite3D.new()
	_SpriteNode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_SpriteNode.visible = false
	# 默认朝向摄像机（+Z 方向）
	get_parent().add_child(_SpriteNode)
#---------------------------------------------------------------------------------------------------
# 技能开始：加载资源、设置偏移、播放动画
func OnSkillBegin(SkillData: KsTableSkill.SkillItem) -> void:
	if _SpriteNode == null:
		return
	# 没有配特效资源，直接隐藏
	if SkillData.FxResPath.is_empty():
		_SpriteNode.visible = false
		return
	# 加载 SpriteFrames 资源
	var FinalResPath = "res://04skillimg/" + SkillData.FxResPath + ".tres"
	var Frames = load(FinalResPath)
	if Frames == null:
		printerr("KsActorCompSkillFx: 无法加载资源 " + SkillData.FxResPath)
		_SpriteNode.visible = false
		return
	# 设置偏移
	_SpriteNode.position = Vector3(SkillData.FxOffsetX, SkillData.FxOffsetY, SkillData.FxOffsetZ)
	# 设置帧资源
	_SpriteNode.sprite_frames = Frames
	# 播放（SpriteFrames 里默认动画名为 "default"）
	_SpriteNode.visible = true
	if SkillData.FxLoop:
		_SpriteNode.play("default")
	else:
		_SpriteNode.play("default")
		# 非循环：播完自动隐藏
		if not _SpriteNode.animation_finished.is_connected(_OnAnimFinished):
			_SpriteNode.animation_finished.connect(_OnAnimFinished)
	# 非循环模式下播放完后不需要持续信号，循环时断开
	if SkillData.FxLoop and _SpriteNode.animation_finished.is_connected(_OnAnimFinished):
		_SpriteNode.animation_finished.disconnect(_OnAnimFinished)
#---------------------------------------------------------------------------------------------------
# 技能结束：隐藏特效
func OnSkillEnd() -> void:
	if _SpriteNode == null:
		return
	_SpriteNode.stop()
	_SpriteNode.visible = false
#---------------------------------------------------------------------------------------------------
# 非循环动画播完后自动隐藏
func _OnAnimFinished() -> void:
	if _SpriteNode != null:
		_SpriteNode.visible = false
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsEnemyFly
# 飞行敌人：向指定方向匀速飞行
# - 能作为蜻蜓点水的垫脚石（Area3D 加入 fly_target 组）
# - 命中玩家 HitBox 或被玩家脚底踩中时立即销毁
# - 离开屏幕后自动销毁
#---------------------------------------------------------------------------------------------------
@export var EnemyId: int = 2002
#---------------------------------------------------------------------------------------------------
@onready var NodeSprite: AnimatedSprite3D = $Sprite
@onready var NodeArea: Area3D = $Area3D
@onready var NodeShape: CollisionShape3D = $Area3D/CollisionShape3D
#---------------------------------------------------------------------------------------------------
var _EnemyData: KsTableEnemy.EnemyItem = null
const ConfigDestroyDistX: float = 60.0  # 超过起点此距离后自动销毁
var _StartPosX: float = 0.0
var _IsConsumed: bool = false            # 防止重复销毁
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	_EnemyData = KsTableEnemy.GetEnemyById(EnemyId)
	if _EnemyData == null:
		return
	_StartPosX = global_position.x
	_InitVisual()
	_InitCollision()
	# fly_target：供 FootBox 检测（蜻蜓点水垫脚石）
	# enemy_attack：供 HitBox 检测（对玩家造成伤害）
	NodeArea.add_to_group("fly_target")
	NodeArea.add_to_group("enemy_attack")
#---------------------------------------------------------------------------------------------------
func _InitVisual() -> void:
	var FinalResPath = "res://03actorimg/" + _EnemyData.FxResPath + ".tres"
	var Frames = load(FinalResPath)
	if Frames == null:
		printerr("KsEnemyFly: 无法加载资源 " + FinalResPath)
		return
	NodeSprite.sprite_frames = Frames
	NodeSprite.scale = Vector3(_EnemyData.FxScale, _EnemyData.FxScale, _EnemyData.FxScale)
	NodeSprite.position = Vector3(_EnemyData.FxOffsetX, _EnemyData.FxOffsetY, 0.0)
	NodeSprite.play("default")
#---------------------------------------------------------------------------------------------------
func _InitCollision() -> void:
	var Shape = BoxShape3D.new()
	Shape.size = Vector3(_EnemyData.AreaWidth, _EnemyData.AreaHeight, 4.0)
	NodeShape.shape = Shape
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _EnemyData == null or _IsConsumed:
		return
	# 匀速飞行
	global_position.x += _EnemyData.FlySpeedX * delta
	global_position.y += _EnemyData.FlySpeedY * delta
	# 超出范围自动销毁
	if abs(global_position.x - _StartPosX) > ConfigDestroyDistX:
		queue_free()
#---------------------------------------------------------------------------------------------------
# 被踩到（FootBox 触发蜻蜓点水）或命中玩家 HitBox 时调用，立即销毁自身
func Consume() -> void:
	if _IsConsumed:
		return
	_IsConsumed = true
	queue_free()
#---------------------------------------------------------------------------------------------------
func GetDamage() -> int:
	if _EnemyData == null:
		return 1
	return max(_EnemyData.Damage, 1)
#---------------------------------------------------------------------------------------------------

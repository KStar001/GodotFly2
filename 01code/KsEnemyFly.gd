#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsEnemyFly
# 飞行道具：向指定方向匀速飞行，离开屏幕或命中玩家后销毁
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
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	_EnemyData = KsTableEnemy.GetEnemyById(EnemyId)
	if _EnemyData == null:
		return
	_StartPosX = global_position.x
	_InitVisual()
	_InitCollision()
	NodeArea.area_entered.connect(_OnAreaEntered)
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
	if _EnemyData == null:
		return
	# 匀速飞行
	global_position.x += _EnemyData.FlySpeedX * delta
	global_position.y += _EnemyData.FlySpeedY * delta
	# 超出范围自动销毁
	if abs(global_position.x - _StartPosX) > ConfigDestroyDistX:
		queue_free()
#---------------------------------------------------------------------------------------------------
func _OnAreaEntered(area: Area3D) -> void:
	if not area.is_in_group("player_hitbox"):
		return
	if KsWorld.CurPlayer != null:
		KsWorld.CurPlayer.TakeHit()
	queue_free()
#---------------------------------------------------------------------------------------------------

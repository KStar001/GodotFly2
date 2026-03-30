#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsEnemyTrap
# 机关陷阱：位置固定，通过 EnemyId 读取配置表初始化外观和碰撞区域
#---------------------------------------------------------------------------------------------------
@export var EnemyId: int = 2001
#---------------------------------------------------------------------------------------------------
@onready var NodeSprite: AnimatedSprite3D = $Sprite
@onready var NodeArea: Area3D = $Area3D
@onready var NodeShape: CollisionShape3D = $Area3D/CollisionShape3D
#---------------------------------------------------------------------------------------------------
var _EnemyData: KsTableEnemy.EnemyItem = null
var _DamageTimer: float = 0.0     # 持续伤害计时器
var _HasTriggered: bool = false   # 接触触发类型是否已触发
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	_EnemyData = KsTableEnemy.GetEnemyById(EnemyId)
	if _EnemyData == null:
		return
	_InitVisual()
	_InitCollision()
	NodeArea.area_entered.connect(_OnAreaEntered)
#---------------------------------------------------------------------------------------------------
func _InitVisual() -> void:
	var FinalResPath = "res://03actorimg/" + _EnemyData.FxResPath + ".tres"
	var Frames = load(FinalResPath)
	if Frames == null:
		printerr("KsEnemyTrap: 无法加载资源 " + FinalResPath)
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
	if _EnemyData.TrapTriggerType == 0:
		_UpdateDamageInterval(delta)
#---------------------------------------------------------------------------------------------------
func _UpdateDamageInterval(delta: float) -> void:
	if _DamageTimer > 0.0:
		_DamageTimer -= delta
#---------------------------------------------------------------------------------------------------
func _OnAreaEntered(area: Area3D) -> void:
	if _EnemyData == null:
		return
	if not area.is_in_group("player_hitbox"):
		return
	if _EnemyData.TrapTriggerType == 0:
		# 持续伤害：间隔到了才触发
		if _DamageTimer <= 0.0:
			_DamageTimer = _EnemyData.TrapInterval
			_DealDamage()
	elif _EnemyData.TrapTriggerType == 1:
		# 接触触发一次
		if not _HasTriggered:
			_HasTriggered = true
			_DealDamage()
#---------------------------------------------------------------------------------------------------
func _DealDamage() -> void:
	if KsWorld.CurPlayer != null:
		KsWorld.CurPlayer.TakeHit()
#---------------------------------------------------------------------------------------------------

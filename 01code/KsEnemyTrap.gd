#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsEnemyTrap
# 机关陷阱：位置固定，不能作为蜻蜓点水的垫脚石，命中玩家后不销毁
# - TrapTriggerType=0：持续伤害，每隔 TrapInterval 秒造成一次伤害（每帧检测重叠）
# - TrapTriggerType=1：接触触发一次，之后不再触发（area_entered 信号驱动）
#---------------------------------------------------------------------------------------------------
@export var EnemyId: int = 2001
#---------------------------------------------------------------------------------------------------
@onready var NodeSprite: AnimatedSprite3D = $Sprite
@onready var NodeArea: Area3D = $Area3D
@onready var NodeShape: CollisionShape3D = $Area3D/CollisionShape3D
#---------------------------------------------------------------------------------------------------
var _EnemyData: KsTableEnemy.EnemyItem = null
var _DamageTimer: float = 0.0   # 持续伤害冷却计时器（>0时不能再触发伤害）
var _HasTriggered: bool = false # TrapTriggerType=1：是否已触发过
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	_EnemyData = KsTableEnemy.GetEnemyById(EnemyId)
	if _EnemyData == null:
		return
	_InitVisual()
	_InitCollision()
	# 不加入 enemy_attack 组，避免与 KsPlayer 的通用受击通道重复触发
	# 仅由本脚本根据 TrapTriggerType 控制伤害时机
	# TrapTriggerType=1：靠 area_entered 事件驱动
	if _EnemyData.TrapTriggerType == 1:
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
func _physics_process(delta: float) -> void:
	if _EnemyData == null:
		return
	# TrapTriggerType=0（持续伤害）：每帧检测重叠 + CD倒计时
	if _EnemyData.TrapTriggerType == 0:
		if _DamageTimer > 0.0:
			_DamageTimer -= delta
		else:
			_CheckContinuousDamage()
#---------------------------------------------------------------------------------------------------
# 持续伤害：检测当前帧是否与 player_hitbox 重叠，重叠则触发一次伤害并重置CD
func _CheckContinuousDamage() -> void:
	var Overlaps = NodeArea.get_overlapping_areas()
	for Area in Overlaps:
		if Area.is_in_group("player_hitbox"):
			_DamageTimer = _EnemyData.TrapInterval
			_DealDamage()
			return
#---------------------------------------------------------------------------------------------------
# TrapTriggerType=1：area_entered 回调，接触一次后不再触发
func _OnAreaEntered(area: Area3D) -> void:
	if not area.is_in_group("player_hitbox"):
		return
	if not _HasTriggered:
		_HasTriggered = true
		_DealDamage()
#---------------------------------------------------------------------------------------------------
func _DealDamage() -> void:
	if KsWorld.CurPlayer != null:
		KsWorld.CurPlayer.TakeHit(GetDamage())
#---------------------------------------------------------------------------------------------------
func GetDamage() -> int:
	if _EnemyData == null:
		return 1
	return max(_EnemyData.Damage, 1)
#---------------------------------------------------------------------------------------------------

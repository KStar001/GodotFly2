#---------------------------------------------------------------------------------------------------
extends Camera3D
class_name KsCamera
#---------------------------------------------------------------------------------------------------
# 配置参数
const ConfigOffsetX: float = 0.0      # 摄像机相对玩家X偏移（横板游戏通常跟随X）
const ConfigOffsetY: float = 2.0      # 摄像机相对玩家Y偏移（稍微偏上）
const ConfigOffsetZ: float = 12.0     # 摄像机距离玩家的Z距离（拉远看侧视图）
const ConfigFollowSpeed: float = 5.0  # 摄像机跟随平滑速度
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	KsWorld.SetMainCamera(self)
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if KsWorld.CurPlayer == null:
		return
	_UpdateFollow(delta)
#---------------------------------------------------------------------------------------------------
func _UpdateFollow(delta: float) -> void:
	var PlayerPos: Vector3 = KsWorld.CurPlayer.global_position
	# 只跟随X轴（横向前进），Y和Z固定偏移
	var DestPos: Vector3 = Vector3(
		PlayerPos.x + ConfigOffsetX,
		PlayerPos.y + ConfigOffsetY,
		PlayerPos.z + ConfigOffsetZ
	)
	global_position = global_position.lerp(DestPos, ConfigFollowSpeed * delta)
	# 始终看向玩家
	look_at(Vector3(PlayerPos.x, PlayerPos.y + 1.0, PlayerPos.z), Vector3.UP)
#---------------------------------------------------------------------------------------------------

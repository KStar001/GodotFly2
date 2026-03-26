#---------------------------------------------------------------------------------------------------
extends Camera3D
class_name KsCamera
#---------------------------------------------------------------------------------------------------
# 配置参数
# 透视摄像机拉远+小FOV，视觉上接近正交但保留轻微纵深感
const ConfigFov: float = 20.0             # FOV越小越接近正交（默认75，这里用20）
const ConfigOffsetX: float = 3.5          # 摄像机在X轴超前玩家的距离（让玩家位于屏幕左侧1/3处）
const ConfigOffsetY: float = 3.0          # 摄像机相对玩家Y偏移（稍微偏上）
const ConfigOffsetZ: float = 30.0         # 摄像机距离玩家Z距离（拉远配合小FOV）
const ConfigFollowSpeed: float = 5.0      # 摄像机跟随平滑速度
const ConfigLookAtOffsetY: float = 1.5    # 看向玩家时的Y偏移（看向躯干而非脚底）
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	fov = ConfigFov
	KsWorld.SetMainCamera(self)
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if KsWorld.CurPlayer == null:
		return
	_UpdateFollow(delta)
#---------------------------------------------------------------------------------------------------
func _UpdateFollow(delta: float) -> void:
	var PlayerPos: Vector3 = KsWorld.CurPlayer.global_position
	# X轴超前玩家一段距离，使玩家位于屏幕左侧1/3处
	var DestPos: Vector3 = Vector3(
		PlayerPos.x + ConfigOffsetX,
		PlayerPos.y + ConfigOffsetY,
		PlayerPos.z + ConfigOffsetZ
	)
	global_position = global_position.lerp(DestPos, ConfigFollowSpeed * delta)
	# 看向玩家躯干位置
	look_at(Vector3(PlayerPos.x, PlayerPos.y + ConfigLookAtOffsetY, PlayerPos.z), Vector3.UP)
#---------------------------------------------------------------------------------------------------

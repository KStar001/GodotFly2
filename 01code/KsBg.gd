#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsBg
#---------------------------------------------------------------------------------------------------
# 配置参数
# 各层视差系数：值越小=移动越慢=感觉越远
const ConfigParallaxBottom: float = 0.05   # 底层（灌木）- 最远，移动最慢
const ConfigParallaxMid: float = 0.2       # 中层（树冠/水母）
const ConfigParallaxTop: float = 0.4       # 高层（云）- 最近，移动最快
# Y轴视差系数（垂直移动幅度比水平小）
const ConfigParallaxYScale: float = 0.4    # Y轴视差 = X轴视差 × 此系数
#---------------------------------------------------------------------------------------------------
@onready var LayerBottom: Node3D = $LayerBottom
@onready var LayerMid: Node3D = $LayerMid
@onready var LayerTop: Node3D = $LayerTop
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if KsWorld.CurCamera == null:
		return
	_UpdateParallax()
#---------------------------------------------------------------------------------------------------
func _UpdateParallax() -> void:
	var CamPos: Vector3 = KsWorld.CurCamera.global_position
	_SetLayerPos(LayerBottom, CamPos, ConfigParallaxBottom)
	_SetLayerPos(LayerMid,    CamPos, ConfigParallaxMid)
	_SetLayerPos(LayerTop,    CamPos, ConfigParallaxTop)
#---------------------------------------------------------------------------------------------------
func _SetLayerPos(Layer: Node3D, CamPos: Vector3, Parallax: float) -> void:
	Layer.global_position.x = CamPos.x * Parallax
	Layer.global_position.y = CamPos.y * Parallax * ConfigParallaxYScale
	# Z轴不变，保持原始深度位置
#---------------------------------------------------------------------------------------------------

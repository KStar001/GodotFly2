#---------------------------------------------------------------------------------------------------
extends Node
class_name KsActorCompBuff
# Buff组件：维护无敌状态和霸体状态，并驱动对应的模型视觉效果
# 使用来源数组记录状态，只要数组不为空就处于对应状态
# 优先级：无敌（金黄色+闪烁）> 霸体（红色）> 普通（白色）
# 颜色效果通过覆盖所有 MeshInstance3D 的 surface_material_override 实现
#---------------------------------------------------------------------------------------------------
const ConfigColorNormal: Color = Color(1.0, 1.0, 1.0, 1.0)      # 普通：白色（原色）
const ConfigColorInvincible: Color = Color(1.0, 0.85, 0.1, 1.0)  # 无敌：金黄色
const ConfigColorArmor: Color = Color(1.0, 0.2, 0.2, 1.0)        # 霸体：红色
const ConfigFlickerInterval: float = 0.08                         # 闪烁间隔（秒）
#---------------------------------------------------------------------------------------------------
var _InvincibleSources: Array = []  # 无敌来源列表（Array[String]）
var _ArmorSources: Array = []       # 霸体来源列表（Array[String]）
# 外部赋值：模型根节点（用于递归收集 MeshInstance3D）
var RefModelNode: Node3D = null
# 收集到的所有 MeshInstance3D（Array[MeshInstance3D]）
var _MeshList: Array = []
# 叠色材质（运行时创建，覆盖到所有 mesh surface）
var _OverlayMat: StandardMaterial3D = null
# 闪烁计时器
var _FlickerTimer: float = 0.0
var _FlickerVisible: bool = true
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	_OverlayMat = StandardMaterial3D.new()
	_OverlayMat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_OverlayMat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	_OverlayMat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_OverlayMat.albedo_color = ConfigColorNormal
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if RefModelNode == null:
		return
	# 延迟收集（等 RefModelNode 的子树都 ready 之后）
	if _MeshList.is_empty():
		_CollectMeshes(RefModelNode)
		if _MeshList.is_empty():
			return
	_UpdateVisual(delta)
#---------------------------------------------------------------------------------------------------
# 递归收集所有 MeshInstance3D
func _CollectMeshes(TargetNode: Node3D) -> void:
	if TargetNode is MeshInstance3D:
		_MeshList.append(TargetNode)
	for Child in TargetNode.get_children():
		_CollectMeshes(Child)
#---------------------------------------------------------------------------------------------------
# 把叠色材质覆盖到所有 mesh 的所有 surface
func _ApplyOverlayMat() -> void:
	for Mesh in _MeshList:
		var M: MeshInstance3D = Mesh as MeshInstance3D
		for i in M.get_surface_override_material_count():
			M.set_surface_override_material(i, _OverlayMat)
#---------------------------------------------------------------------------------------------------
# 移除叠色材质覆盖（恢复原始材质）
func _RemoveOverlayMat() -> void:
	for Mesh in _MeshList:
		var M: MeshInstance3D = Mesh as MeshInstance3D
		for i in M.get_surface_override_material_count():
			M.set_surface_override_material(i, null)
#---------------------------------------------------------------------------------------------------
# 每帧更新视觉效果
func _UpdateVisual(delta: float) -> void:
	if IsInvincible():
		# 无敌：金黄色 + 闪烁（交替显示/隐藏）
		_FlickerTimer -= delta
		if _FlickerTimer <= 0.0:
			_FlickerTimer = ConfigFlickerInterval
			_FlickerVisible = not _FlickerVisible
		_SetModelVisible(_FlickerVisible)
		_OverlayMat.albedo_color = ConfigColorInvincible
		_ApplyOverlayMat()
	elif IsArmor():
		# 霸体：红色，不闪烁
		_ResetFlicker()
		_SetModelVisible(true)
		_OverlayMat.albedo_color = ConfigColorArmor
		_ApplyOverlayMat()
	else:
		# 普通：移除覆盖材质，恢复原始材质
		_ResetFlicker()
		_SetModelVisible(true)
		_RemoveOverlayMat()
#---------------------------------------------------------------------------------------------------
func _SetModelVisible(Visible: bool) -> void:
	if RefModelNode != null:
		RefModelNode.visible = Visible
#---------------------------------------------------------------------------------------------------
func _ResetFlicker() -> void:
	_FlickerTimer = 0.0
	_FlickerVisible = true
#---------------------------------------------------------------------------------------------------
# 无敌状态接口
func AddInvincible(Source: String) -> void:
	if not _InvincibleSources.has(Source):
		_InvincibleSources.append(Source)

func RemoveInvincible(Source: String) -> void:
	_InvincibleSources.erase(Source)
	# 无敌结束时立即恢复可见
	if not IsInvincible():
		_ResetFlicker()
		_SetModelVisible(true)

func IsInvincible() -> bool:
	return _InvincibleSources.size() > 0
#---------------------------------------------------------------------------------------------------
# 霸体状态接口
func AddArmor(Source: String) -> void:
	if not _ArmorSources.has(Source):
		_ArmorSources.append(Source)

func RemoveArmor(Source: String) -> void:
	_ArmorSources.erase(Source)

func IsArmor() -> bool:
	return _ArmorSources.size() > 0
#---------------------------------------------------------------------------------------------------
# 清空所有状态（死亡/重置时用）
func ClearAll() -> void:
	_InvincibleSources.clear()
	_ArmorSources.clear()
	_ResetFlicker()
	_SetModelVisible(true)
	if _OverlayMat != null:
		_OverlayMat.albedo_color = ConfigColorNormal
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
extends Node
class_name KsActorCompBuff
# Buff组件：维护无敌状态和霸体状态，并驱动对应的模型视觉效果
# 使用来源数组记录状态，只要数组不为空就处于对应状态
# 优先级：无敌（金黄色+闪烁）> 霸体（红色）> 普通（白色）
#---------------------------------------------------------------------------------------------------
const ConfigColorNormal: Color = Color(1.0, 1.0, 1.0, 1.0)     # 普通：白色（原色）
const ConfigColorInvincible: Color = Color(1.0, 0.85, 0.1, 1.0) # 无敌：金黄色
const ConfigColorArmor: Color = Color(1.0, 0.2, 0.2, 1.0)       # 霸体：红色
const ConfigFlickerInterval: float = 0.08                        # 闪烁间隔（秒）
#---------------------------------------------------------------------------------------------------
var _InvincibleSources: Array[String] = []  # 无敌来源列表
var _ArmorSources: Array[String] = []       # 霸体来源列表
# 外部赋值：模型根节点（用于修改 modulate）
var RefModelNode: Node3D = null
# 闪烁计时器
var _FlickerTimer: float = 0.0
var _FlickerVisible: bool = true
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if RefModelNode == null:
		return
	_UpdateVisual(delta)
#---------------------------------------------------------------------------------------------------
# 每帧更新模型视觉效果
func _UpdateVisual(delta: float) -> void:
	if IsInvincible():
		# 无敌：金黄色 + 闪烁
		_FlickerTimer -= delta
		if _FlickerTimer <= 0.0:
			_FlickerTimer = ConfigFlickerInterval
			_FlickerVisible = not _FlickerVisible
		RefModelNode.modulate = ConfigColorInvincible if _FlickerVisible else Color(0, 0, 0, 0)
	elif IsArmor():
		# 霸体：红色，不闪烁
		_ResetFlicker()
		RefModelNode.modulate = ConfigColorArmor
	else:
		# 普通：恢复原色
		_ResetFlicker()
		RefModelNode.modulate = ConfigColorNormal
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
	# 无敌结束时立即恢复可见（避免残留隐藏帧）
	if not IsInvincible() and RefModelNode != null:
		_ResetFlicker()
		RefModelNode.modulate = ConfigColorArmor if IsArmor() else ConfigColorNormal

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
	if RefModelNode != null:
		RefModelNode.modulate = ConfigColorNormal
#---------------------------------------------------------------------------------------------------

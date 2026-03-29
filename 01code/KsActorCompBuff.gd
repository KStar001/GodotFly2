#---------------------------------------------------------------------------------------------------
extends Node
class_name KsActorCompBuff
# Buff组件：维护无敌状态和霸体状态
# 使用来源数组记录状态，只要数组不为空就处于对应状态
# 任何系统（受击无敌帧、技能、道具等）通过 Add/Remove 接口管理自己的来源
#---------------------------------------------------------------------------------------------------
var _InvincibleSources: Array[String] = []  # 无敌来源列表
var _ArmorSources: Array[String] = []       # 霸体来源列表
#---------------------------------------------------------------------------------------------------
# 无敌状态接口
func AddInvincible(Source: String) -> void:
	if not _InvincibleSources.has(Source):
		_InvincibleSources.append(Source)

func RemoveInvincible(Source: String) -> void:
	_InvincibleSources.erase(Source)

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
#---------------------------------------------------------------------------------------------------

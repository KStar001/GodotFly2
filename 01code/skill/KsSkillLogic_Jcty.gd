#---------------------------------------------------------------------------------------------------
# 金蝉脱壳 专属逻辑
# A类技能，无敌帧期间关闭受击碰撞层
extends KsSkillLogic_Base
class_name KsSkillLogic_Jcty
#---------------------------------------------------------------------------------------------------
func OnSkillBegin(Player: KsPlayer, SkillData: KsSkillData) -> void:
	# 关闭受击碰撞层，进入无敌帧
	# TODO: 确认受击碰撞层编号后填入
	# Player.set_collision_mask_value(2, false)
	pass
#---------------------------------------------------------------------------------------------------
func OnSkillUpdate(Player: KsPlayer, SkillData: KsSkillData, Delta: float) -> void:
	pass
#---------------------------------------------------------------------------------------------------
func OnSkillEnd(Player: KsPlayer, SkillData: KsSkillData) -> void:
	# 恢复受击碰撞层
	# Player.set_collision_mask_value(2, true)
	pass
#---------------------------------------------------------------------------------------------------

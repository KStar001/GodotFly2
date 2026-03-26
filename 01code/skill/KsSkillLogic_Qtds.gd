#---------------------------------------------------------------------------------------------------
# 蜻蜓点水 专属逻辑
# B类技能，需要借力目标（脚底 Area 检测到飞行道具）才能触发
extends KsSkillLogic_Base
class_name KsSkillLogic_Qtds
#---------------------------------------------------------------------------------------------------
func OnSkillBegin(Player: KsPlayer, SkillData: KsSkillData) -> void:
	# 叠加向上速度
	Player.CurVerticalSpeed = SkillData.VelocityY
	# TODO: 销毁被踩中的飞行道具（由 Player 的脚底检测区域传入目标引用）
#---------------------------------------------------------------------------------------------------
func OnSkillUpdate(Player: KsPlayer, SkillData: KsSkillData, Delta: float) -> void:
	pass
#---------------------------------------------------------------------------------------------------
func OnSkillEnd(Player: KsPlayer, SkillData: KsSkillData) -> void:
	pass
#---------------------------------------------------------------------------------------------------

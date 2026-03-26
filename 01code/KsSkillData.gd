#---------------------------------------------------------------------------------------------------
# 技能数据类，对应 skill.csv 中的一行
class_name KsSkillData
#---------------------------------------------------------------------------------------------------
var SkillId: int             # 技能ID
var SkillType: int           # 技能类型：0=A类闪避 1=B类跳跃 2=C类功法
var SkillName: String        # 技能名称
var Duration: float          # 技能持续时长（逻辑时钟，不依赖动画）
var CdDuration: float        # 施放后触发的公共CD时长
var AnimName: String         # 动画名称（表现层，可为空）
# A类专用
var InvincibleTime: float    # 无敌帧时长
# B类专用
var VelocityX: float         # 施放后叠加的水平速度（正值=向前加速，如突进）
var VelocityY: float         # 施放后叠加的垂直速度
var NeedTarget: bool         # 是否需要借力目标（如蜻蜓点水）
# C类专用
var BuffType: int            # BUFF类型（0=无 1=御风 ...）
var BuffDuration: float      # BUFF持续时长
# 通用
var AntiGravity: bool        # 技能期间是否无视重力（true=不受重力影响）
#---------------------------------------------------------------------------------------------------

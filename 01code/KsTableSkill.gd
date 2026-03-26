#---------------------------------------------------------------------------------------------------
# 技能配置表（静态类）
class_name KsTableSkill
#---------------------------------------------------------------------------------------------------
# 技能数据类，对应 skill.csv 中的一行
class SkillItem:
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
	
	static func CreateFromCsvLine(line: String) -> SkillItem:
		var Parts = line.split(",")
		if Parts.size() >= 13:
			var Data = SkillItem.new()
			Data.SkillId        = int(Parts[0])
			Data.SkillType      = int(Parts[1])
			Data.SkillName      = Parts[2].strip_edges()
			Data.Duration       = float(Parts[3])
			Data.CdDuration     = float(Parts[4])
			Data.AnimName       = Parts[5].strip_edges()
			Data.VelocityX      = float(Parts[6])
			Data.VelocityY      = float(Parts[7])
			Data.NeedTarget     = Parts[8].strip_edges().to_lower() == "true"
			Data.InvincibleTime = float(Parts[9])
			Data.BuffType       = int(Parts[10])
			Data.BuffDuration   = float(Parts[11])
			Data.AntiGravity    = Parts[12].strip_edges().to_lower() == "true"
			return Data
		return null
#---------------------------------------------------------------------------------------------------
# 技能数据字典，key = SkillId，value = SkillItem
static var _DataMap: Dictionary = {}
#---------------------------------------------------------------------------------------------------
# 读取并解析 skill.csv
static func LoadDataFile() -> void:
	_DataMap.clear()
	var FilePath: String = "res://10table/skill.csv"
	var File = FileAccess.open(FilePath, FileAccess.READ)
	if File == null:
		printerr("KsTableSkill: 无法打开文件 " + FilePath)
		return
	# 跳过表头行
	File.get_line()
	# 逐行解析
	while not File.eof_reached():
		var Line: String = File.get_line().strip_edges()
		if Line.is_empty():
			continue
		var Data = SkillItem.CreateFromCsvLine(Line)
		if Data != null:
			_DataMap[Data.SkillId] = Data
	File.close()
	print("KsTableSkill: 加载完毕，共 %d 条技能数据" % _DataMap.size())
#---------------------------------------------------------------------------------------------------
# 根据 SkillId 获取技能数据，不存在返回 null
static func GetSkillById(SkillId: int) -> SkillItem:
	if _DataMap.has(SkillId):
		return _DataMap[SkillId]
	printerr("KsTableSkill: 找不到技能ID " + str(SkillId))
	return null
#---------------------------------------------------------------------------------------------------

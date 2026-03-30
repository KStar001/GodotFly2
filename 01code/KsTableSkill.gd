#---------------------------------------------------------------------------------------------------
# 技能配置表（静态类）
class_name KsTableSkill
#---------------------------------------------------------------------------------------------------
# 技能数据类，对应 skill.csv 中的一行
class SkillItem:
	var SkillId: int             # 技能ID
	var SkillType: int           # 技能类型：0=A类闪避 1=B类跳跃 2=C类功法
	var SkillName: String        # 技能名称
	var Duration: float          # 技能持续时长
	var CdDuration: float        # 施放后触发的公共CD时长
	var SkillIcon: String        # 技能图标名（如 icon_tyz，完整路径 res://04skillimg/icon_xxx.png）
	# 水平速度
	var VelocityX: float         # 技能叠加水平速度（0=无效，非0=叠加）
	var VelocityXLock: bool      # true=最终水平速度锁定为 VelocityX（VelocityX可为0）
	# 垂直速度
	var VelocityY: float         # 技能叠加垂直速度（0=无效，非0=叠加）
	var VelocityYLock: bool      # true=最终垂直速度锁定为 VelocityY，不受下落速度上限限制
	var VelocityYClear: bool     # true=施放瞬间把Y轴速度清零
	# 其他
	var NeedTarget: bool         # 是否需要借力目标（如蜻蜓点水）
	# 序列帧特效
	var FxResPath: String        # SpriteFrames 资源路径（空=无特效）
	var FxOffsetX: float         # 特效本地X偏移
	var FxOffsetY: float         # 特效本地Y偏移（负值=脚底）
	var FxOffsetZ: float         # 特效本地Z偏移（正值=靠近摄像机）
	var FxLoop: bool             # 特效是否循环播放

	static func CreateFromCsvLine(line: String) -> SkillItem:
		var Parts = line.split(",")
		if Parts.size() >= 17:
			var Data = SkillItem.new()
			Data.SkillId        = int(Parts[0])
			Data.SkillType      = int(Parts[1])
			Data.SkillName      = Parts[2].strip_edges()
			Data.Duration       = float(Parts[3])
			Data.CdDuration     = float(Parts[4])
			Data.SkillIcon      = Parts[5].strip_edges()
			Data.VelocityX      = float(Parts[6])
			Data.VelocityXLock  = Parts[7].strip_edges().to_lower() == "true"
			Data.VelocityY      = float(Parts[8])
			Data.VelocityYLock  = Parts[9].strip_edges().to_lower() == "true"
			Data.VelocityYClear = Parts[10].strip_edges().to_lower() == "true"
			Data.NeedTarget     = Parts[11].strip_edges().to_lower() == "true"
			Data.FxResPath      = Parts[12].strip_edges()
			Data.FxOffsetX      = float(Parts[13])
			Data.FxOffsetY      = float(Parts[14])
			Data.FxOffsetZ      = float(Parts[15])
			Data.FxLoop         = Parts[16].strip_edges().to_lower() == "true"
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
# 根据技能类型获取所有该类型技能列表
static func GetAllSkillsByType(SkillType: int) -> Array:
	var Result: Array = []
	for SkillData in _DataMap.values():
		if SkillData.SkillType == SkillType:
			Result.append(SkillData)
	return Result
#---------------------------------------------------------------------------------------------------

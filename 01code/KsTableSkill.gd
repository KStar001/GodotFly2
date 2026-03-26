#---------------------------------------------------------------------------------------------------
class_name KsTableSkill
# 技能配置表（静态类）
# 读取 10table/skill.csv，解析为 KsSkillData 字典，供全局查询
# 用法：KsTableSkill.GetSkillById(1001)
# 无需实例化，首次调用时自动加载
#---------------------------------------------------------------------------------------------------
# 技能数据字典，key = SkillId，value = KsSkillData
static var _DataMap: Dictionary = {}
static var _Loaded: bool = false
#---------------------------------------------------------------------------------------------------
# 确保数据已加载（懒加载，首次调用时自动触发）
static func _EnsureLoaded() -> void:
	if _Loaded:
		return
	_Loaded = true
	_LoadTable()
#---------------------------------------------------------------------------------------------------
# 读取并解析 skill.csv
static func _LoadTable() -> void:
	_DataMap.clear()
	var FilePath: String = "res://10table/skill.csv"
	var File = FileAccess.open(FilePath, FileAccess.READ)
	if File == null:
		push_error("KsTableSkill: 无法打开文件 " + FilePath)
		return
	# 跳过表头行
	File.get_line()
	# 逐行解析
	while not File.eof_reached():
		var Line: String = File.get_line().strip_edges()
		if Line.is_empty():
			continue
		var Data: KsSkillData = _ParseLine(Line)
		if Data != null:
			_DataMap[Data.SkillId] = Data
	File.close()
	print("KsTableSkill: 加载完毕，共 %d 条技能数据" % _DataMap.size())
#---------------------------------------------------------------------------------------------------
# 解析一行CSV，返回 KsSkillData
static func _ParseLine(Line: String) -> KsSkillData:
	var Parts: Array = Line.split(",")
	if Parts.size() < 13:
		push_warning("KsTableSkill: 行格式不正确，跳过：" + Line)
		return null
	var Data: KsSkillData = KsSkillData.new()
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
#---------------------------------------------------------------------------------------------------
# 根据 SkillId 获取技能数据，不存在返回 null
static func GetSkillById(SkillId: int) -> KsSkillData:
	_EnsureLoaded()
	if _DataMap.has(SkillId):
		return _DataMap[SkillId]
	push_warning("KsTableSkill: 找不到技能ID " + str(SkillId))
	return null
#---------------------------------------------------------------------------------------------------
# 获取所有技能数据（返回字典副本）
static func GetAllSkill() -> Dictionary:
	_EnsureLoaded()
	return _DataMap.duplicate()
#---------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 敌人配置表（静态类）
class_name KsTableEnemy
#---------------------------------------------------------------------------------------------------
# 敌人数据类，对应 enemy.csv 中的一行
class EnemyItem:
	var EnemyId: int             # 敌人ID
	var EnemyType: int           # 敌人类型：0=机关陷阱 1=飞行道具
	var EnemyName: String        # 敌人名称
	var FxResPath: String        # SpriteFrames 资源路径
	var FxScale: float           # 贴图缩放
	var FxOffsetX: float         # 贴图X轴偏移
	var FxOffsetY: float         # 贴图Y轴偏移
	var Damage: int              # 伤害值
	var AreaWidth: float         # Area3D X轴大小
	var AreaHeight: float        # Area3D Y轴大小
	# 机关陷阱专用
	var TrapTriggerType: int     # 触发方式：0=持续伤害 1=接触触发一次
	var TrapInterval: float      # 持续伤害间隔（秒，TrapTriggerType=0时有效）
	# 飞行道具专用
	var FlySpeedX: float         # 水平飞行速度
	var FlySpeedY: float         # 垂直飞行速度（0=平飞）

	static func CreateFromCsvLine(line: String) -> EnemyItem:
		var Parts = line.split(",")
		if Parts.size() >= 14:
			var Data = EnemyItem.new()
			Data.EnemyId         = int(Parts[0])
			Data.EnemyType       = int(Parts[1])
			Data.EnemyName       = Parts[2].strip_edges()
			Data.FxResPath       = Parts[3].strip_edges()
			Data.FxScale         = float(Parts[4])
			Data.FxOffsetX       = float(Parts[5])
			Data.FxOffsetY       = float(Parts[6])
			Data.Damage          = int(Parts[7])
			Data.AreaWidth       = float(Parts[8])
			Data.AreaHeight      = float(Parts[9])
			Data.TrapTriggerType = int(Parts[10])
			Data.TrapInterval    = float(Parts[11])
			Data.FlySpeedX       = float(Parts[12])
			Data.FlySpeedY       = float(Parts[13])
			return Data
		return null
#---------------------------------------------------------------------------------------------------
static var _DataMap: Dictionary = {}
#---------------------------------------------------------------------------------------------------
static func LoadDataFile() -> void:
	_DataMap.clear()
	var FilePath: String = "res://10table/enemy.csv"
	var File = FileAccess.open(FilePath, FileAccess.READ)
	if File == null:
		printerr("KsTableEnemy: 无法打开文件 " + FilePath)
		return
	File.get_line()  # 跳过表头
	while not File.eof_reached():
		var Line: String = File.get_line().strip_edges()
		if Line.is_empty():
			continue
		var Data = EnemyItem.CreateFromCsvLine(Line)
		if Data != null:
			_DataMap[Data.EnemyId] = Data
	File.close()
	print("KsTableEnemy: 加载完毕，共 %d 条敌人数据" % _DataMap.size())
#---------------------------------------------------------------------------------------------------
static func GetEnemyById(EnemyId: int) -> EnemyItem:
	if _DataMap.has(EnemyId):
		return _DataMap[EnemyId]
	printerr("KsTableEnemy: 找不到敌人ID " + str(EnemyId))
	return null
#---------------------------------------------------------------------------------------------------

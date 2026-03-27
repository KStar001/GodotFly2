#---------------------------------------------------------------------------------------------------
# 剧情配置表（静态类）
class_name KsTableStory
#---------------------------------------------------------------------------------------------------
# 剧情步骤数据类，对应 story.csv 中的一行
class StoryItem:
	var StoryId: int        # 剧情段落ID（同一段落连续播放）
	var Step: int           # 段落内顺序
	var Type: String        # 步骤类型：image=静态图全屏 / dialog=过场对话框
	var ImageRes: String       # image类型：图片文件名；dialog类型：立绘资源名
	var Text: String        # 显示文字（image类型可留空）
	var Speaker: String     # 说话人名字（image类型留空）
	var MinTime: float      # 最少停留时长（秒），未到时长前不允许跳过；0=无限制
	var MaxTime: float      # 最多停留时长（秒），到时长后自动跳下一步；0=不自动跳

	static func CreateFromCsvLine(line: String) -> StoryItem:
		var Parts = line.split(",")
		if Parts.size() >= 8:
			var Data = StoryItem.new()
			Data.StoryId  = int(Parts[0])
			Data.Step     = int(Parts[1])
			Data.Type     = Parts[2].strip_edges()
			Data.ImageRes = Parts[3].strip_edges()
			Data.Text     = Parts[4].strip_edges()
			Data.Speaker  = Parts[5].strip_edges()
			Data.MinTime  = float(Parts[6])
			Data.MaxTime  = float(Parts[7])
			return Data
		return null
#---------------------------------------------------------------------------------------------------
# 数据存储：key = StoryId，value = 按 Step 排序的 StoryItem 数组
static var _DataMap: Dictionary = {}
#---------------------------------------------------------------------------------------------------
# 读取并解析 story.csv
static func LoadDataFile() -> void:
	_DataMap.clear()
	var FilePath: String = "res://10table/story.csv"
	var File = FileAccess.open(FilePath, FileAccess.READ)
	if File == null:
		printerr("KsTableStory: 无法打开文件 " + FilePath)
		return
	# 跳过表头行
	File.get_line()
	# 逐行解析
	while not File.eof_reached():
		var Line: String = File.get_line().strip_edges()
		if Line.is_empty():
			continue
		var Data = StoryItem.CreateFromCsvLine(Line)
		if Data == null:
			continue
		if not _DataMap.has(Data.StoryId):
			_DataMap[Data.StoryId] = []
		_DataMap[Data.StoryId].append(Data)
	# 每段按 Step 排序
	for Id in _DataMap:
		_DataMap[Id].sort_custom(func(a, b): return a.Step < b.Step)
	File.close()
	print("KsTableStory: 加载完毕，共 %d 段剧情" % _DataMap.size())
#---------------------------------------------------------------------------------------------------
# 获取指定剧情段落的所有步骤（按 Step 排序），不存在返回空数组
static func GetStoryById(StoryId: int) -> Array:
	if _DataMap.has(StoryId):
		return _DataMap[StoryId]
	printerr("KsTableStory: 找不到剧情ID " + str(StoryId))
	return []
#---------------------------------------------------------------------------------------------------

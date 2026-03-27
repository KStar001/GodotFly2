#---------------------------------------------------------------------------------------------------
extends Node
class_name KsStoryManager
# 剧情调度管理器
# 职责：拿到步骤列表 → 逐步推进 → 计时 → 通知 KsUIStory 显示 → 播完执行回调
# KsTableStory 负责数据，KsUIStory 负责显示，本类只管流程
#---------------------------------------------------------------------------------------------------
# 当前剧情步骤列表
var _StepList: Array = []
# 当前步骤索引
var _CurStepIndex: int = -1
# 当前步骤已停留时长
var _CurStepTimer: float = 0.0
# 当前步骤是否已过 MinTime（允许跳过）
var _CurStepCanSkip: bool = false
# 播放完成回调
var _OnFinish: Callable
# 是否正在播放剧情
var _IsPlaying: bool = false
# KsUIStory 节点引用（由外部赋值）
var RefUIStory: Node = null
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not _IsPlaying:
		return
	_UpdateStepTimer(delta)
#---------------------------------------------------------------------------------------------------
# 更新当前步骤计时
func _UpdateStepTimer(delta: float) -> void:
	var CurStep: KsTableStory.StoryItem = _GetCurStep()
	if CurStep == null:
		return
	_CurStepTimer += delta
	# MinTime 到了，允许跳过
	if not _CurStepCanSkip and CurStep.MinTime > 0.0:
		if _CurStepTimer >= CurStep.MinTime:
			_CurStepCanSkip = true
	# MaxTime 到了，自动跳下一步
	if CurStep.MaxTime > 0.0 and _CurStepTimer >= CurStep.MaxTime:
		_NextStep()
#---------------------------------------------------------------------------------------------------
# 播放指定剧情段落，播完后执行 OnFinish 回调
func PlayStory(StoryId: int, OnFinish: Callable) -> void:
	var Steps: Array = KsTableStory.GetStoryById(StoryId)
	if Steps.is_empty():
		printerr("KsStoryManager: 剧情ID不存在或无步骤 " + str(StoryId))
		OnFinish.call()
		return
	_StepList   = Steps
	_OnFinish   = OnFinish
	_IsPlaying  = true
	_CurStepIndex = -1
	_NextStep()
#---------------------------------------------------------------------------------------------------
# 玩家点击跳过（由 KsUIStory 点击事件调用）
func TrySkipStep() -> void:
	if not _IsPlaying:
		return
	var CurStep: KsTableStory.StoryItem = _GetCurStep()
	if CurStep == null:
		return
	# MinTime 为 0 或已过 MinTime，允许跳过
	if CurStep.MinTime <= 0.0 or _CurStepCanSkip:
		_NextStep()
#---------------------------------------------------------------------------------------------------
# 推进到下一步
func _NextStep() -> void:
	_CurStepIndex += 1
	# 所有步骤播完，结束剧情
	if _CurStepIndex >= _StepList.size():
		_EndStory()
		return
	# 重置步骤计时
	_CurStepTimer   = 0.0
	_CurStepCanSkip = false
	var CurStep: KsTableStory.StoryItem = _GetCurStep()
	# MinTime 为 0，默认直接允许跳过
	if CurStep.MinTime <= 0.0:
		_CurStepCanSkip = true
	# 通知 KsUIStory 显示当前步骤
	_ShowStep(CurStep)
#---------------------------------------------------------------------------------------------------
# 通知 KsUIStory 显示步骤内容（KsUIStory 实现前用 print 占位）
func _ShowStep(Step: KsTableStory.StoryItem) -> void:
	if RefUIStory != null and RefUIStory.has_method("ShowStep"):
		RefUIStory.ShowStep(Step)
	else:
		# 占位输出，KsUIStory 完成后移除
		print("KsStoryManager._ShowStep | type=%s image=%s speaker=%s text=%s" % [
			Step.Type, Step.ImageRes, Step.Speaker, Step.Text
		])
#---------------------------------------------------------------------------------------------------
# 剧情结束，清理状态并执行回调
func _EndStory() -> void:
	_IsPlaying    = false
	_StepList     = []
	_CurStepIndex = -1
	_CurStepTimer = 0.0
	_CurStepCanSkip = false
	# 通知 KsUIStory 隐藏界面
	if RefUIStory != null and RefUIStory.has_method("HideStory"):
		RefUIStory.HideStory()
	# 执行外部回调
	if _OnFinish.is_valid():
		_OnFinish.call()
#---------------------------------------------------------------------------------------------------
# 获取当前步骤数据，越界返回 null
func _GetCurStep() -> KsTableStory.StoryItem:
	if _CurStepIndex >= 0 and _CurStepIndex < _StepList.size():
		return _StepList[_CurStepIndex]
	return null
#---------------------------------------------------------------------------------------------------
# 是否正在播放剧情
func IsPlaying() -> bool:
	return _IsPlaying
#---------------------------------------------------------------------------------------------------

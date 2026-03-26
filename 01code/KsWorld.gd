#---------------------------------------------------------------------------------------------------
extends Node
#---------------------------------------------------------------------------------------------------
# 游戏阶段
enum EGameStep
{
	StepNone,    # 等待游戏初始化
	StepGaming,  # 游戏中
}
#---------------------------------------------------------------------------------------------------
# 当前游戏阶段
var CurGameStep: EGameStep = EGameStep.StepNone
# 当前客户端主角
var CurPlayer: KsPlayer = null
# 当前摄像机
var CurCamera: KsCamera = null
# 当前HUD
var CurUIHud: KsUIHud = null
# 输入缓冲模块
var CompInput: KsInput = null
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	randomize()
	_LoadAllTable()
	_InitInput()
	await get_tree().create_timer(0.5).timeout
	ChangeGameStep(EGameStep.StepGaming)
#---------------------------------------------------------------------------------------------------
func _LoadAllTable() -> void:
	KsTableSkill.LoadDataFile()
#---------------------------------------------------------------------------------------------------
func _InitInput() -> void:
	CompInput = KsInput.new()
	add_child(CompInput)
	await get_tree().process_frame
	if CurUIHud == null:
		return
	# 直接通过 KsUIHud 的节点引用连接按钮，不再 find_child 搜索
	CurUIHud.NodeJumpButton.pressed.connect(func(): CompInput.OnCmdPressed(KsInput.ECmdType.Jump))
	CurUIHud.NodeSkillBButton.pressed.connect(func(): CompInput.OnCmdPressed(KsInput.ECmdType.SkillB))
	CurUIHud.NodeSkillCButton.pressed.connect(func(): CompInput.OnCmdPressed(KsInput.ECmdType.SkillC))
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	_UpdateDebugLabel()
#---------------------------------------------------------------------------------------------------
func _UpdateDebugLabel() -> void:
	if CurUIHud == null or CompInput == null:
		return
	var Text: String = CompInput.GetDebugText()
	if CurPlayer != null and CurPlayer.CompSkill != null:
		Text += "\n" + CurPlayer.CompSkill.GetDebugText()
	CurUIHud.UpdateDebugText(Text)
#---------------------------------------------------------------------------------------------------
func ChangeGameStep(NewStep: EGameStep) -> void:
	if CurGameStep == NewStep:
		return
	var OldStep = CurGameStep
	CurGameStep = NewStep
	match OldStep:
		EGameStep.StepGaming:
			_GameStepEnd_Gaming()
	match NewStep:
		EGameStep.StepGaming:
			_GameStepBegin_Gaming()
#---------------------------------------------------------------------------------------------------
func _GameStepBegin_Gaming() -> void:
	if CompInput != null:
		CompInput.RefPlayer = CurPlayer
#---------------------------------------------------------------------------------------------------
func _GameStepEnd_Gaming() -> void:
	pass
#---------------------------------------------------------------------------------------------------
func SetMainPlayer(Player: KsPlayer) -> void:
	CurPlayer = Player
#---------------------------------------------------------------------------------------------------
func SetMainCamera(Camera: KsCamera) -> void:
	CurCamera = Camera
#---------------------------------------------------------------------------------------------------
func SetMainUIHud(UIHud: KsUIHud) -> void:
	CurUIHud = UIHud
#---------------------------------------------------------------------------------------------------

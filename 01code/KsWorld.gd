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
# 输入缓冲模块
var CompInput: KsInput = null
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	randomize()
	_InitInput()
	await get_tree().create_timer(0.5).timeout
	ChangeGameStep(EGameStep.StepGaming)
#---------------------------------------------------------------------------------------------------
func _InitInput() -> void:
	CompInput = KsInput.new()
	add_child(CompInput)
	await get_tree().process_frame
	# 连接跳跃按钮
	var JumpBtn = get_tree().root.find_child("JumpButton", true, false)
	if JumpBtn != null:
		JumpBtn.pressed.connect(func(): CompInput.OnCmdPressed(KsInput.ECmdType.Jump))
	# 连接梯云纵按钮
	var SkillBBtn = get_tree().root.find_child("SkillBButton", true, false)
	if SkillBBtn != null:
		SkillBBtn.pressed.connect(func(): CompInput.OnCmdPressed(KsInput.ECmdType.SkillB))
	# 连接御风术按钮
	var SkillCBtn = get_tree().root.find_child("SkillCButton", true, false)
	if SkillCBtn != null:
		SkillCBtn.pressed.connect(func(): CompInput.OnCmdPressed(KsInput.ECmdType.SkillC))
	# 连接HUD debug Label
	var DebugLabel = get_tree().root.find_child("DebugLabel", true, false)
	if DebugLabel != null:
		CompInput.set_meta("DebugLabel", DebugLabel)
#---------------------------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	# 键盘空格键跳跃（调试用）
	if Input.is_action_just_pressed("ui_accept"):
		if CompInput != null:
			CompInput.OnCmdPressed(KsInput.ECmdType.Jump)
	_UpdateDebugLabel()
#---------------------------------------------------------------------------------------------------
func _UpdateDebugLabel() -> void:
	if CompInput == null:
		return
	if not CompInput.has_meta("DebugLabel"):
		return
	var DebugLabel = CompInput.get_meta("DebugLabel")
	if not is_instance_valid(DebugLabel):
		return
	var Text: String = CompInput.GetDebugText()
	if CurPlayer != null and CurPlayer.CompSkill != null:
		Text += "\n" + CurPlayer.CompSkill.GetDebugText()
	DebugLabel.text = Text
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

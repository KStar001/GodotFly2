#---------------------------------------------------------------------------------------------------
extends Node3D
class_name KsSpike
#---------------------------------------------------------------------------------------------------
# 配置参数
const ConfigRiseHeight: float = 1.6        # 刺出高度（米，对应2D 160px）
const ConfigRiseTime: float = 0.15         # 刺出耗时（秒）
const ConfigStayTime: float = 0.5          # 顶部停留时间（秒）
const ConfigRetractTime: float = 0.4       # 缩回耗时（秒）
const ConfigWarnTime: float = 1.5          # 预警时间（秒）
const ConfigCoolTime: float = 1.0          # 冷却时间（秒）
#---------------------------------------------------------------------------------------------------
enum ESpikeState
{
	SpikeState_Warning,    # 预警中
	SpikeState_Rising,     # 刺出中
	SpikeState_Staying,    # 顶部停留
	SpikeState_Retracting, # 缩回中
	SpikeState_Cooling,    # 冷却中
}
var CurState: ESpikeState = ESpikeState.SpikeState_Warning
var CurTimer: float = 0.0
var CurBaseY: float = 0.0   # 初始Y（隐藏位置）
var CurTopY: float = 0.0    # 刺出最高点Y
#---------------------------------------------------------------------------------------------------
@onready var NodeVisual: MeshInstance3D = $Visual
@onready var NodeHitBox: Area3D = $HitBox
@onready var NodeParticles: GPUParticles3D = $WarningParticles
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	CurBaseY = position.y
	CurTopY = position.y + ConfigRiseHeight
	NodeVisual.visible = false
	NodeHitBox.monitoring = false
	NodeParticles.emitting = true
	CurTimer = ConfigWarnTime
#---------------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	CurTimer -= delta
	match CurState:
		ESpikeState.SpikeState_Warning:
			_UpdateState_Warning()
		ESpikeState.SpikeState_Rising:
			_UpdateState_Rising(delta)
		ESpikeState.SpikeState_Staying:
			_UpdateState_Staying()
		ESpikeState.SpikeState_Retracting:
			_UpdateState_Retracting(delta)
		ESpikeState.SpikeState_Cooling:
			_UpdateState_Cooling()
#---------------------------------------------------------------------------------------------------
func _UpdateState_Warning() -> void:
	if CurTimer > 0.0:
		return
	NodeVisual.visible = true
	NodeHitBox.monitoring = true
	NodeParticles.emitting = false
	_ChangeState(ESpikeState.SpikeState_Rising, ConfigRiseTime)
#---------------------------------------------------------------------------------------------------
func _UpdateState_Rising(delta: float) -> void:
	var Progress: float = 1.0 - clamp(CurTimer / ConfigRiseTime, 0.0, 1.0)
	position.y = lerp(CurBaseY, CurTopY, Progress)
	if CurTimer <= 0.0:
		position.y = CurTopY
		_ChangeState(ESpikeState.SpikeState_Staying, ConfigStayTime)
#---------------------------------------------------------------------------------------------------
func _UpdateState_Staying() -> void:
	if CurTimer > 0.0:
		return
	NodeHitBox.monitoring = false
	_ChangeState(ESpikeState.SpikeState_Retracting, ConfigRetractTime)
#---------------------------------------------------------------------------------------------------
func _UpdateState_Retracting(delta: float) -> void:
	var Progress: float = 1.0 - clamp(CurTimer / ConfigRetractTime, 0.0, 1.0)
	position.y = lerp(CurTopY, CurBaseY, Progress)
	if CurTimer <= 0.0:
		position.y = CurBaseY
		NodeVisual.visible = false
		_ChangeState(ESpikeState.SpikeState_Cooling, ConfigCoolTime)
#---------------------------------------------------------------------------------------------------
func _UpdateState_Cooling() -> void:
	if CurTimer > 0.0:
		return
	NodeParticles.emitting = true
	_ChangeState(ESpikeState.SpikeState_Warning, ConfigWarnTime)
#---------------------------------------------------------------------------------------------------
func _ChangeState(NewState: ESpikeState, Duration: float) -> void:
	CurState = NewState
	CurTimer = Duration
#---------------------------------------------------------------------------------------------------
# HitBox 检测到玩家，触发强制弹起，然后销毁自身
func _on_HitBox_body_entered(body: Node3D) -> void:
	if body is KsPlayer:
		body.DoSpikeJump()
		queue_free()
#---------------------------------------------------------------------------------------------------

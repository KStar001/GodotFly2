#---------------------------------------------------------------------------------------------------
extends CanvasLayer
class_name KsUIHud
#---------------------------------------------------------------------------------------------------
# 节点引用
@onready var NodeJumpButton: Button   = $JumpButton
@onready var NodeSkillBButton: Button = $SkillBButton
@onready var NodeSkillCButton: Button = $SkillCButton
@onready var NodeDebugLabel: Label    = $DebugLabel
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	KsWorld.SetMainUIHud(self)
#---------------------------------------------------------------------------------------------------
# 更新调试文本
func UpdateDebugText(Text: String) -> void:
	NodeDebugLabel.text = Text
#---------------------------------------------------------------------------------------------------

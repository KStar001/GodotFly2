extends MarginContainer
class_name KsUISafePanel
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 获取安全区域和窗口大小
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()  # 注意：这是窗口大小
	
	# 基础边距（也可以从主题获取）
	var top: int = 8
	var left: int = 8
	var bottom: int = 8
	var right: int = 8

	# 只有当窗口足够大时才应用安全区域
	if window_size.x >= safe_area.size.x and window_size.y >= safe_area.size.y:
		# 计算缩放因子
		var x_factor: float = size.x / window_size.x
		var y_factor: float = size.y / window_size.y

		# 计算需要的边距
		top = max(top, safe_area.position.y * y_factor)
		left = max(left, safe_area.position.x * x_factor)
		bottom = max(bottom, abs(safe_area.end.y - window_size.y) * y_factor)
		right = max(right, abs(safe_area.end.x - window_size.x) * x_factor)

	# 应用边距
	add_theme_constant_override("margin_top", int(top))
	add_theme_constant_override("margin_left", int(left))
	add_theme_constant_override("margin_bottom", int(bottom))
	add_theme_constant_override("margin_right", int(right))
#---------------------------------------------------------------------------------------------------

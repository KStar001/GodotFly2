extends MarginContainer
class_name KsUISafePanel
#---------------------------------------------------------------------------------------------------
const _BASE_MARGIN: int = 8
#---------------------------------------------------------------------------------------------------
func _ready() -> void:
	# 延迟一帧，确保布局尺寸已稳定
	call_deferred("_RefreshSafeMargins")
#---------------------------------------------------------------------------------------------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_RefreshSafeMargins()
#---------------------------------------------------------------------------------------------------
func _RefreshSafeMargins() -> void:
	# 获取系统安全区域与窗口尺寸
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return

	# 使用当前控件实际尺寸做缩放换算
	var panel_size: Vector2 = size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = get_viewport_rect().size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return

	var top: float = _BASE_MARGIN
	var left: float = _BASE_MARGIN
	var bottom: float = _BASE_MARGIN
	var right: float = _BASE_MARGIN

	# 把系统安全区域（窗口像素）映射到当前控件坐标系
	if window_size.x >= safe_area.size.x and window_size.y >= safe_area.size.y:
		var x_factor: float = panel_size.x / float(window_size.x)
		var y_factor: float = panel_size.y / float(window_size.y)
		top = max(top, safe_area.position.y * y_factor)
		left = max(left, safe_area.position.x * x_factor)
		bottom = max(bottom, abs(safe_area.end.y - window_size.y) * y_factor)
		right = max(right, abs(safe_area.end.x - window_size.x) * x_factor)

	# 应用边距
	add_theme_constant_override("margin_top", int(round(top)))
	add_theme_constant_override("margin_left", int(round(left)))
	add_theme_constant_override("margin_bottom", int(round(bottom)))
	add_theme_constant_override("margin_right", int(round(right)))
#---------------------------------------------------------------------------------------------------

extends Control

var page_label
var nav_page_lbl
var patient_list
var current_page = 1
var total_pages = 1
var prev_btn
var next_btn
var is_loading = false

# Search state
var search_input: LineEdit
var search_btn: Button
var clear_btn: Button
var search_query: String = ""
var is_search_mode: bool = false


func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	await get_tree().process_frame
	await get_tree().process_frame

	position = Vector2.ZERO
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.93, 0.95, 0.97)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	# ── Header ──
	var header_bg = ColorRect.new()
	header_bg.color = Color(0.15, 0.35, 0.65)
	header_bg.custom_minimum_size = Vector2(0, 108)
	header_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header_bg)

	# Title label (top half of header)
	page_label = Label.new()
	page_label.text = "Connecting..."
	page_label.add_theme_color_override("font_color", Color.WHITE)
	page_label.add_theme_font_size_override("font_size", 20)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.anchor_left   = 0.0
	page_label.anchor_right  = 1.0
	page_label.anchor_top    = 0.0
	page_label.anchor_bottom = 0.0
	page_label.offset_top    = 0.0
	page_label.offset_bottom = 54.0
	page_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_bg.add_child(page_label)

	# ── Search row (bottom half of header) ──
	var search_row = HBoxContainer.new()
	search_row.anchor_left   = 0.0
	search_row.anchor_right  = 1.0
	search_row.anchor_top    = 0.0
	search_row.anchor_bottom = 0.0
	search_row.offset_top    = 58.0
	search_row.offset_bottom = 100.0
	search_row.offset_left   = 16.0
	search_row.offset_right  = -16.0
	search_row.add_theme_constant_override("separation", 8)
	search_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_bg.add_child(search_row)

	# Search LineEdit
	search_input = LineEdit.new()
	search_input.placeholder_text = "Search by name, email, phone, doctor, department…"
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.custom_minimum_size = Vector2(0, 38)
	search_input.add_theme_font_size_override("font_size", 15)
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(1, 1, 1, 0.15)
	input_style.corner_radius_top_left    = 8
	input_style.corner_radius_top_right   = 8
	input_style.corner_radius_bottom_left = 8
	input_style.corner_radius_bottom_right = 8
	input_style.content_margin_left  = 12
	input_style.content_margin_right = 12
	input_style.content_margin_top   = 6
	input_style.content_margin_bottom = 6
	input_style.border_width_left   = 1
	input_style.border_width_right  = 1
	input_style.border_width_top    = 1
	input_style.border_width_bottom = 1
	input_style.border_color = Color(1, 1, 1, 0.4)
	search_input.add_theme_stylebox_override("normal", input_style)
	search_input.add_theme_color_override("font_color", Color.WHITE)
	search_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.55))
	search_input.text_submitted.connect(_on_search_submitted)
	search_row.add_child(search_input)

	# Search button
	search_btn = Button.new()
	search_btn.text = "🔍  Search"
	search_btn.custom_minimum_size = Vector2(130, 38)
	search_btn.add_theme_font_size_override("font_size", 15)
	_style_search_btn(search_btn, Color(0.08, 0.52, 0.32), Color(0.05, 0.42, 0.26))
	search_btn.pressed.connect(_on_search_pressed)
	search_row.add_child(search_btn)

	# Clear button (hidden until searching)
	clear_btn = Button.new()
	clear_btn.text = "✕  Clear"
	clear_btn.custom_minimum_size = Vector2(110, 38)
	clear_btn.add_theme_font_size_override("font_size", 15)
	_style_search_btn(clear_btn, Color(0.65, 0.18, 0.18), Color(0.52, 0.12, 0.12))
	clear_btn.pressed.connect(_on_clear_pressed)
	clear_btn.visible = false
	search_row.add_child(clear_btn)

	# ── Scroll ──
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	patient_list = GridContainer.new()
	patient_list.columns = 2
	patient_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	patient_list.add_theme_constant_override("h_separation", 12)
	patient_list.add_theme_constant_override("v_separation", 12)
	scroll.add_child(patient_list)

	# ── Nav bar ──
	var nav_bg = ColorRect.new()
	nav_bg.color = Color(1.0, 1.0, 1.0)
	nav_bg.custom_minimum_size = Vector2(0, 80)
	nav_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(nav_bg)

	var border = ColorRect.new()
	border.color = Color(0.82, 0.85, 0.88)
	border.custom_minimum_size = Vector2(0, 1)
	border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.set_anchors_preset(Control.PRESET_TOP_WIDE)
	nav_bg.add_child(border)

	prev_btn = Button.new()
	prev_btn.text = "◀   Previous"
	prev_btn.disabled = true
	prev_btn.custom_minimum_size = Vector2(200, 52)
	prev_btn.add_theme_font_size_override("font_size", 18)
	prev_btn.anchor_left   = 0.5
	prev_btn.anchor_right  = 0.5
	prev_btn.anchor_top    = 0.5
	prev_btn.anchor_bottom = 0.5
	prev_btn.offset_left   = -260.0
	prev_btn.offset_right  = -60.0
	prev_btn.offset_top    = -26.0
	prev_btn.offset_bottom = 26.0
	_style_button(prev_btn, false)
	prev_btn.pressed.connect(_on_prev)
	nav_bg.add_child(prev_btn)

	nav_page_lbl = Label.new()
	nav_page_lbl.text = "- / -"
	nav_page_lbl.add_theme_font_size_override("font_size", 17)
	nav_page_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	nav_page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_page_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	nav_page_lbl.anchor_left   = 0.5
	nav_page_lbl.anchor_right  = 0.5
	nav_page_lbl.anchor_top    = 0.5
	nav_page_lbl.anchor_bottom = 0.5
	nav_page_lbl.offset_left   = -50.0
	nav_page_lbl.offset_right  = 50.0
	nav_page_lbl.offset_top    = -20.0
	nav_page_lbl.offset_bottom = 20.0
	nav_page_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav_bg.add_child(nav_page_lbl)

	next_btn = Button.new()
	next_btn.text = "Next   ▶"
	next_btn.disabled = true
	next_btn.custom_minimum_size = Vector2(200, 52)
	next_btn.add_theme_font_size_override("font_size", 18)
	next_btn.anchor_left   = 0.5
	next_btn.anchor_right  = 0.5
	next_btn.anchor_top    = 0.5
	next_btn.anchor_bottom = 0.5
	next_btn.offset_left   = 60.0
	next_btn.offset_right  = 260.0
	next_btn.offset_top    = -26.0
	next_btn.offset_bottom = 26.0
	_style_button(next_btn, true)
	next_btn.pressed.connect(_on_next)
	nav_bg.add_child(next_btn)

	if not ApiManager.patients_loaded.is_connected(_show_list):
		ApiManager.patients_loaded.connect(_show_list)
	if not ApiManager.failed.is_connected(_on_fail):
		ApiManager.failed.connect(_on_fail)

	ApiManager.get_all(current_page)


# ── Search helpers ──────────────────────────────────────────────────────────

func _on_search_submitted(text: String) -> void:
	# Pressing Enter in the LineEdit triggers search too
	_on_search_pressed()


func _on_search_pressed() -> void:
	var q = search_input.text.strip_edges()
	if q.is_empty() or is_loading:
		return
	search_query   = q
	is_search_mode = true
	current_page   = 1
	clear_btn.visible = true
	_fetch_current()


func _on_clear_pressed() -> void:
	if is_loading:
		return
	search_query      = ""
	is_search_mode    = false
	current_page      = 1
	search_input.text = ""
	clear_btn.visible = false
	_fetch_current()


func _fetch_current() -> void:
	is_loading = true
	prev_btn.disabled = true
	next_btn.disabled = true
	nav_page_lbl.text = "Loading..."
	if is_search_mode:
		ApiManager.search_patients(search_query, current_page)
	else:
		ApiManager.get_all(current_page)


# ── Existing nav ────────────────────────────────────────────────────────────

func _on_prev():
	if is_loading or current_page <= 1:
		return
	current_page -= 1
	_fetch_current()


func _on_next():
	if is_loading or current_page >= total_pages:
		return
	current_page += 1
	_fetch_current()


func _on_fail(msg):
	is_loading = false
	page_label.text = "Failed: " + msg
	prev_btn.disabled = current_page <= 1
	next_btn.disabled = current_page >= total_pages


func _show_list(data):
	is_loading   = false
	current_page = data.get("page", 1)
	total_pages  = data.get("total_pages", 1)
	var total    = data.get("total", 0)

	if is_search_mode:
		page_label.text = "Search: \"%s\"  —  %d result(s)  (page %d of %d)" % [
			search_query, total, current_page, total_pages
		]
	else:
		page_label.text = "Page %d of %d  —  %d patients total" % [
			current_page, total_pages, total
		]

	nav_page_lbl.text = "Page %d / %d" % [current_page, total_pages]
	prev_btn.disabled = current_page <= 1
	next_btn.disabled = current_page >= total_pages

	for c in patient_list.get_children():
		c.queue_free()
	for p in data.get("patients", []):
		patient_list.add_child(_make_card(p))


# ── Button styling ──────────────────────────────────────────────────────────

func _style_search_btn(btn: Button, normal_color: Color, pressed_color: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left     = 8
		sb.corner_radius_top_right    = 8
		sb.corner_radius_bottom_left  = 8
		sb.corner_radius_bottom_right = 8
		sb.content_margin_left  = 14
		sb.content_margin_right = 14
		sb.content_margin_top   = 6
		sb.content_margin_bottom = 6
		match state:
			"normal":  sb.bg_color = normal_color
			"hover":   sb.bg_color = normal_color.lightened(0.1)
			"pressed": sb.bg_color = pressed_color
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color",         Color.WHITE)
	btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)


func _style_button(btn: Button, is_primary: bool) -> void:
	var normal = StyleBoxFlat.new()
	normal.corner_radius_top_left     = 10
	normal.corner_radius_top_right    = 10
	normal.corner_radius_bottom_left  = 10
	normal.corner_radius_bottom_right = 10
	normal.content_margin_left  = 20
	normal.content_margin_right = 20
	normal.content_margin_top   = 10
	normal.content_margin_bottom = 10
	if is_primary:
		normal.bg_color = Color(0.15, 0.45, 0.85)
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		normal.bg_color = Color(1.0, 1.0, 1.0)
		normal.border_width_left   = 2
		normal.border_width_right  = 2
		normal.border_width_top    = 2
		normal.border_width_bottom = 2
		normal.border_color = Color(0.15, 0.45, 0.85)
		btn.add_theme_color_override("font_color", Color(0.15, 0.45, 0.85))
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.corner_radius_top_left     = 10
	hover.corner_radius_top_right    = 10
	hover.corner_radius_bottom_left  = 10
	hover.corner_radius_bottom_right = 10
	hover.content_margin_left  = 20
	hover.content_margin_right = 20
	hover.content_margin_top   = 10
	hover.content_margin_bottom = 10
	if is_primary:
		hover.bg_color = Color(0.1, 0.35, 0.72)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		hover.bg_color = Color(0.9, 0.94, 1.0)
		hover.border_width_left   = 2
		hover.border_width_right  = 2
		hover.border_width_top    = 2
		hover.border_width_bottom = 2
		hover.border_color = Color(0.15, 0.45, 0.85)
		btn.add_theme_color_override("font_hover_color", Color(0.1, 0.35, 0.72))
	btn.add_theme_stylebox_override("hover", hover)

	var pressed_sb = StyleBoxFlat.new()
	pressed_sb.corner_radius_top_left     = 10
	pressed_sb.corner_radius_top_right    = 10
	pressed_sb.corner_radius_bottom_left  = 10
	pressed_sb.corner_radius_bottom_right = 10
	pressed_sb.content_margin_left  = 20
	pressed_sb.content_margin_right = 20
	pressed_sb.content_margin_top   = 10
	pressed_sb.content_margin_bottom = 10
	if is_primary:
		pressed_sb.bg_color = Color(0.08, 0.28, 0.60)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	else:
		pressed_sb.bg_color = Color(0.82, 0.89, 1.0)
		pressed_sb.border_width_left   = 2
		pressed_sb.border_width_right  = 2
		pressed_sb.border_width_top    = 2
		pressed_sb.border_width_bottom = 2
		pressed_sb.border_color = Color(0.1, 0.35, 0.72)
		btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.28, 0.60))
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	var disabled_sb = StyleBoxFlat.new()
	disabled_sb.corner_radius_top_left     = 10
	disabled_sb.corner_radius_top_right    = 10
	disabled_sb.corner_radius_bottom_left  = 10
	disabled_sb.corner_radius_bottom_right = 10
	disabled_sb.content_margin_left  = 20
	disabled_sb.content_margin_right = 20
	disabled_sb.content_margin_top   = 10
	disabled_sb.content_margin_bottom = 10
	disabled_sb.bg_color = Color(0.88, 0.88, 0.88)
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	btn.add_theme_stylebox_override("disabled", disabled_sb)


# ── Card building (unchanged) ───────────────────────────────────────────────

func _make_card(p: Dictionary) -> MarginContainer:
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.08)
	style.shadow_size  = 6
	style.content_margin_left   = 18
	style.content_margin_right  = 18
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)
	margin.add_child(card)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	var b64: String = p.get("image_base64", "")
	if b64 and b64 != "null" and b64 != "":
		var bytes = Marshalls.base64_to_raw(b64)
		var img = Image.new()
		var err = img.load_jpg_from_buffer(bytes)
		if err != OK:
			err = img.load_png_from_buffer(bytes)
		if err == OK:
			var tex = TextureRect.new()
			tex.texture = ImageTexture.create_from_image(img)
			tex.custom_minimum_size = Vector2(110, 110)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(tex)
		else:
			hbox.add_child(_placeholder())
	else:
		hbox.add_child(_placeholder())

	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_constant_override("separation", 6)
	hbox.add_child(details)

	_add_label(details, "%s  (ID: %d)" % [p.get("name",""), p.get("id",0)], 20, Color(0.1, 0.1, 0.1))
	_add_label(details, "Dr. %s   |   %s" % [p.get("doctor_name",""), p.get("department","")], 15, Color(0.15, 0.35, 0.75))
	_add_label(details, "Email: %s" % p.get("email",""), 14, Color(0.3, 0.3, 0.3))
	_add_label(details, "Phone: %s" % p.get("phone",""), 14, Color(0.3, 0.3, 0.3))
	_add_label(details, "Age: %s   |   Height: %s cm   |   Weight: %s kg" % [
		p.get("age",""), p.get("height",""), p.get("weight","")
	], 14, Color(0.4, 0.4, 0.4))

	return margin


func _placeholder() -> Panel:
	var ph = Panel.new()
	ph.custom_minimum_size = Vector2(110, 110)
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.88, 0.92)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	ph.add_theme_stylebox_override("panel", style)
	return ph


func _add_label(parent, text: String, size: int, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)

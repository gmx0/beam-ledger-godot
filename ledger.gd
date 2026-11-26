extends Control

const ORDERS = [
	["01  /  LANTERN GLASS", Vector2i(2, 1), 2, 3],
	["02  /  STILL MIRROR", Vector2i(3, 0), 4, 5],
	["03  /  BLUE SEAL", Vector2i(4, -2), 6, 7]
]
const PARTICLES = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, -1)]
const PRICE = [1, 1, 2]
const NAMES = ["A  ·  ARC     (+1,  0)", "B  ·  VEIL    ( 0, +1)", "C  ·  HINGE   (+2, −1)"]
const AQUA = Color("#77f1d4")
const AMBER = Color("#f7ca78")
const INK = Color("#e3f5f7")
const MUTED = Color("#a9c2cb")
const RED = Color("#ff9d91")
var loadout: Array[int] = [0, 0, 0]
var energy := 2
var heat := 0
var credits := 31
var order := 0
var state := "live"
var notice := "Fit the target, then fire inside the resonance band."
var tone := AQUA
var flare := 0.0
var phase := 0.0
var forecast: Label
var brief: Label
var stats: Label
var report: Label
var log_title: Label
var energy_text: Label
var load_labels: Array[Label] = []
var inc: Array[Button] = []
var dec: Array[Button] = []
var energy_down: Button
var energy_up: Button
var clear_button: Button
var vent_button: Button
var fire_button: Button
var ring: Control

func _ready():
	theme = Theme.new()
	theme.default_font_size = 17
	for name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#153544") if name == "hover" else Color("#102b37")
		if name == "pressed": style.bg_color = Color("#20544e")
		if name == "disabled": style.bg_color = Color("#0d202b")
		style.border_color = AQUA if name == "focus" else Color("#325562")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 12
		style.content_margin_right = 12
		if name == "focus": style.draw_center = false
		theme.set_stylebox(name, "Button", style)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("#78939c"))
	theme.set_color("font_hover_color", "Button", AQUA)
	theme.set_constant("separation", "VBoxContainer", 8)
	theme.set_constant("separation", "HBoxContainer", 8)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := label(header, "BEAM LEDGER", 32, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(header, "Restart", "restart", restart)
	label(column, "NIGHT SHIFT  /  THREE ORDERS  /  FICTIONAL LAB UNITS", 15, AQUA)
	stats = label(column, "", 19, AMBER)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	column.add_child(body)
	var left := panel(body)
	var right := panel(body)
	label(left, "01  /  BEAM LOADER", 19, AQUA)
	label(left, "Add up to 3 particles. Their two numbers add.", 16, MUTED)
	for i in 3:
		var row := HBoxContainer.new()
		left.add_child(row)
		label(row, NAMES[i], 17, INK).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dec.append(button(row, "−", "minus%d" % i, change_load.bind(i, -1)))
		var count := label(row, "0", 18, AQUA)
		count.custom_minimum_size.x = 22
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		load_labels.append(count)
		inc.append(button(row, "+", "plus%d" % i, change_load.bind(i, 1)))
	var energy_row := HBoxContainer.new()
	left.add_child(energy_row)
	energy_text = label(energy_row, "", 17, INK)
	energy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_down = button(energy_row, "− energy", "energy_down", change_energy.bind(-1))
	energy_up = button(energy_row, "+ energy", "energy_up", change_energy.bind(1))
	forecast = label(left, "", 17, MUTED)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	clear_button = button(actions, "Clear load", "clear", clear_load)
	vent_button = button(actions, "Vent · 3 CR", "vent", vent)
	fire_button = button(actions, "Fire beam", "fire", fire)
	fire_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(left, "Vent removes 45 heat. Reaching 100 trips the lab.", 15, MUTED)
	brief = label(right, "", 20, INK)
	ring = Control.new()
	ring.custom_minimum_size = Vector2(300, 190)
	ring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(ring)
	ring.draw.connect(draw_ring)
	log_title = label(right, "", 15, AQUA)
	report = label(right, "", 17, INK)
	report.custom_minimum_size.y = 60
	label(column, "Dispatch all three orders before the ring trips or the contract goes unfunded.", 16, MUTED)
	refresh()

func panel(parent: Container) -> VBoxContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a1c27")
	style.border_color = Color("#294a57")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	for edge in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + edge, 16.0)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	var box := VBoxContainer.new()
	p.add_child(box)
	return box

func label(parent: Node, value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func button(parent: Node, title: String, id: String, action: Callable) -> Button:
	var b := Button.new()
	b.name = id
	b.text = title
	b.custom_minimum_size = Vector2(48, 39)
	parent.add_child(b)
	b.pressed.connect(action)
	return b

func count_particles(parts: Array[int]) -> int:
	return parts[0] + parts[1] + parts[2]

func signature(parts: Array[int]) -> Vector2i:
	return PARTICLES[0] * parts[0] + PARTICLES[1] * parts[1] + PARTICLES[2] * parts[2]

func cost(parts: Array[int], level: int) -> int:
	return 2 + parts[0] * PRICE[0] + parts[1] * PRICE[1] + parts[2] * PRICE[2] + floori(float(level) / 3.0)

func rise(parts: Array[int], level: int) -> int:
	return 15 + level * 5 + count_particles(parts) * 4

func min_valid_cost() -> int:
	var target: Vector2i = ORDERS[order][1]
	var cheapest := 999
	for a in 4:
		for b in (4-a):
			for c in (4-a-b):
				var mix: Array[int] = [a, b, c]
				if signature(mix) == target:
					cheapest = mini(cheapest, cost(mix, ORDERS[order][2]))
	return cheapest

func change_load(i: int, amount: int):
	if state != "live" or loadout[i] + amount < 0 or count_particles(loadout) + amount > 3: return
	loadout[i] += amount
	refresh()

func change_energy(amount: int):
	if state != "live": return
	energy = clampi(energy + amount, 1, 9)
	refresh()

func clear_load():
	loadout = [0, 0, 0]
	refresh()

func vent():
	if state != "live" or heat == 0 or credits < 3: return
	credits -= 3
	heat = maxi(0, heat - 45)
	notice = "Rings vented. Check the projected heat before firing again."
	tone = AQUA
	check_contract()
	refresh()

func fire():
	if state != "live" or count_particles(loadout) == 0 or cost(loadout, energy) > credits: return
	credits -= cost(loadout, energy)
	heat += rise(loadout, energy)
	flare = 1.0
	if heat >= 100:
		state = "trip"
		notice = "Thermal interlock tripped. This shot was not dispatched."
		tone = RED
	else:
		var order_data: Array = ORDERS[order]
		var sig_ok: bool = signature(loadout) == order_data[1]
		var band_ok: bool = energy >= order_data[2] and energy <= order_data[3]
		if sig_ok and band_ok:
			order += 1
			tone = AQUA
			notice = "Order shipped. Load and energy controls remain as set."
			if order == ORDERS.size():
				state = "won"
				notice = "All three orders dispatched. Night shift complete."
		else:
			tone = AMBER
			if not sig_ok and not band_ok: notice = "Rejected: signature and energy band both missed."
			elif not sig_ok: notice = "Rejected: signature mismatch. Energy was in band."
			else: notice = "Rejected: signature matched. Energy was outside the band."
		check_contract()
	refresh()

func check_contract():
	if state == "live" and credits < min_valid_cost():
		state = "funds"
		notice += "\nNo valid mix is affordable for the current order."
		tone = RED

func restart():
	loadout = [0, 0, 0]
	energy = 2
	heat = 0
	credits = 31
	order = 0
	state = "live"
	notice = "Fit the target, then fire inside the resonance band."
	tone = AQUA
	flare = 0.0
	refresh()

func refresh():
	var live := state == "live"
	var count := count_particles(loadout)
	var pair := signature(loadout)
	stats.text = "CREDITS   %02d      |      RING HEAT   %02d / 100      |      SHIPPED   %d / 3" % [credits, heat, order]
	for i in 3:
		load_labels[i].text = str(loadout[i])
		inc[i].disabled = not live or count >= 3
		dec[i].disabled = not live or loadout[i] == 0
	energy_text.text = "Energy   %d / 9" % energy
	energy_down.disabled = not live or energy <= 1
	energy_up.disabled = not live or energy >= 9
	clear_button.disabled = not live or count == 0
	vent_button.disabled = not live or heat == 0 or credits < 3
	fire_button.disabled = not live or count == 0 or credits < cost(loadout, energy)
	var projected := heat + rise(loadout, energy)
	forecast.text = "Load %d/3    •    Signature (%+d, %+d)\nShot %d CR    •    Projected heat %s" % [count, pair.x, pair.y, cost(loadout, energy), "—" if count == 0 else str(projected)]
	if live and count > 0 and cost(loadout, energy) > credits: forecast.text += "\nThis load is too expensive. Edit it to try again."
	elif live and count > 0 and projected >= 100: forecast.text += "\nCaution: this shot will trip the lab."
	if order < ORDERS.size():
		var current: Array = ORDERS[order]
		var target: Vector2i = current[1]
		brief.text = "%s\nTarget (%+d, %+d)  /  Energy %d–%d" % [current[0], target.x, target.y, current[2], current[3]]
	else: brief.text = "SHIFT CLOSED\nThree deliveries confirmed"
	log_title.text = {"live":"DISPATCH LOG", "trip":"SHUTDOWN  /  THERMAL", "funds":"SHUTDOWN  /  CONTRACT", "won":"SHIFT COMPLETE"}[state]
	log_title.add_theme_color_override("font_color", tone)
	report.text = notice

func _process(delta: float):
	phase += delta * 0.9
	flare = maxf(0.0, flare - delta * 2.4)
	ring.queue_redraw()

func draw_ring():
	var center := ring.size * 0.5
	var radius := minf(ring.size.x, ring.size.y) * 0.36
	ring.draw_circle(center, radius * 0.96, Color("#102e3b"))
	for i in 3:
		ring.draw_arc(center, radius - i * 11.0, 0.0, TAU, 80, Color("#315669"), 1.0, true)
	for i in 24:
		var ray := Vector2.from_angle(TAU * i / 24.0)
		var filled := i < ceili(heat * 0.24)
		ring.draw_line(center + ray * (radius + 4), center + ray * (radius + 11), AMBER if filled else Color("#315669"), 2, true)
	for i in count_particles(loadout):
		var point := center + Vector2.from_angle(phase + i * TAU / 3.0) * (radius - 11)
		ring.draw_circle(point, 4, AQUA)
	ring.draw_line(center - Vector2(13, 0), center + Vector2(13, 0), MUTED, 1.0, true)
	ring.draw_line(center - Vector2(0, 13), center + Vector2(0, 13), MUTED, 1.0, true)
	if flare > 0.0:
		ring.draw_arc(center, radius * (1.0 - flare * 0.7), 0.0, TAU, 64, Color(tone, flare), 2.0, true)

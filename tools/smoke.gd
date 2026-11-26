extends SceneTree

var viewport: SubViewport
var game: Control

func _initialize():
	call_deferred("run")

func require(ok: bool, message: String):
	if not ok:
		printerr("FAILED: ", message)
		OS.kill(OS.get_process_id())

func control(id: String) -> Button:
	return game.find_child(id, true, false) as Button

func tap(id: String, times := 1):
	for i in times:
		await process_frame
		await process_frame
		var b := control(id)
		require(is_instance_valid(b) and not b.disabled, id + " not clickable")
		var point := b.get_global_transform_with_canvas() * (b.size * 0.5)
		require(Rect2(Vector2.ZERO, Vector2(viewport.size)).has_point(point), id + " clipped")
		for down in [true, false]:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.position = point
			e.global_position = point
			e.pressed = down
			viewport.push_input(e, true)

func clean_restart():
	await tap("restart")
	require(game.state == "live" and game.order == 0 and game.credits == 31 and game.heat == 0 and game.energy == 2 and game.loadout == [0, 0, 0], "restart resets every field")
	require(control("fire").disabled and control("vent").disabled, "no empty fire or cold vent")

func run():
	viewport = SubViewport.new()
	viewport.size = Vector2i(1040, 680)
	root.add_child(viewport)
	game = load("res://main.tscn").instantiate()
	viewport.add_child(game)
	await clean_restart()
	await tap("plus0")
	await tap("fire")
	require(game.notice.contains("signature mismatch") and game.order == 0, "signature-only miss")
	await tap("plus0")
	await tap("plus1")
	require(control("plus2").disabled, "three-slot cap")
	await tap("energy_down")
	await tap("fire")
	require(game.notice.contains("signature matched") and game.order == 0, "energy-only miss")
	await clean_restart()
	await tap("plus0", 2)
	await tap("plus1")
	await tap("energy_up")
	await tap("fire")
	require(game.order == 1, "upper inclusive boundary")
	await clean_restart()
	await tap("plus0")
	await tap("energy_up", 7)
	await tap("fire", 2)
	require(game.state == "trip" and game.order == 0 and control("fire").disabled, "overheat trip precedes dispatch")
	await clean_restart()
	await tap("plus0")
	for i in 4:
		await tap("fire")
		await tap("vent")
	require(game.credits == 7 and game.heat == 0 and game.state == "live", "cheap legal recipe still available")
	await tap("clear")
	await tap("plus2")
	await tap("plus1", 2)
	await tap("energy_up", 7)
	require(control("fire").disabled and game.forecast.text.contains("Edit it") and game.state == "live", "unaffordable load is editable, not terminal")
	await tap("clear")
	await tap("plus0")
	await tap("energy_down", 7)
	await tap("fire")
	require(game.state == "funds" and game.credits == 4 and game.heat < 100 and game.order == 0, "positive-credit contract exhaustion")
	await clean_restart()
	await tap("plus0", 2)
	await tap("plus1")
	await tap("fire")
	require(game.order == 1, "lower inclusive boundary")
	await tap("minus1")
	await tap("plus0")
	await tap("energy_up", 2)
	await tap("fire")
	require(game.order == 2, "second order")
	await tap("vent")
	await tap("clear")
	await tap("plus2", 2)
	await tap("energy_up", 2)
	await tap("fire")
	require(game.state == "won" and game.order == 3 and game.credits == 9 and game.heat == 92 and control("fire").disabled, "win and terminal guard")
	await clean_restart()
	print("BEAM LEDGER: routed player input passes both boundaries, two misses, thermal trip, editable expensive load, positive-credit exhaustion, full win, restart.")
	quit()

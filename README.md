# Beam Ledger

A small 2D accelerator puzzle in Godot 4.6. Three dispatch orders are due before the night shift ends.

1. Add or remove Arc, Veil, and Hinge particles with the **+ / −** buttons. Their two signature values add together. The loader holds three particles.
2. Adjust **energy** until it falls inside the current order's displayed band, endpoints included. **Fire beam** when the signature and band agree.
3. Check the forecast before firing. A shot that reaches 100 heat is lost. **Vent** drops heat by up to 45 and costs 3 credits. Wrong shots still cost credits and generate heat.
4. Dispatch all three orders. **Restart** is always available. Controls also work with Godot's standard Tab and Enter button navigation.

## Run

Import `project.godot` in Godot 4.6.3 and press F6 from the main scene or F5 from anywhere. No add-ons. The game uses fictional units, not real accelerator operation.

For the Web export, extract the ZIP and run `python3 -m http.server 8000` in that directory, then open `http://localhost:8000`. For the Linux x86-64 export, extract and run `./beam-ledger.x86_64` (set its executable bit if your unzip tool strips it).

## Tests

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tools/smoke.gd
```

The smoke test routes actual pointer clicks through the game viewport. It checks correct and incorrect recipes, both inclusive energy boundaries, the price guard, thermal and credit shutdowns, a complete win, and restart. Web and Linux pack behavior was checked headlessly in Godot, not in a graphical browser or on Windows.

Fresh game code and programmatically drawn graphics; no third-party game assets. Standard Godot export settings and notice scaffolding follow the prior prototype. Godot notices are in `GODOT_NOTICES.txt`.

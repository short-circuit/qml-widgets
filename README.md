# qml-touch-widgets

Edge-swipe gesture widgets for touchscreen convertibles running
Quickshell + Hyprland.

## Gestures

| Edge | Gesture | Action |
|------|---------|--------|
| Bottom (25px) | Swipe up (>80px) | Toggle on-screen keyboard |
| Left (18px) | Swipe up/down | Volume ±5% per 25px |
| Top (18px) | Swipe left/right | Brightness ±5% per 30px |

## Usage

```bash
qs -p ~/git/qml-widgets
```

Or for NixOS, add this flake as an input and run via exec-once:

```nix
hl.exec_cmd("qs -p ${inputs.qml-touch-widgets}/share/qml-touch-widgets")
```

## How it works

Each gesture is a `PanelWindow` with `WlrLayershell.layer: Overlay`,
anchored to the corresponding screen edge. The panels are 18–25px
thick — barely enough for a deliberate edge swipe but invisible to
normal interaction. `WlrLayershell.keyboardFocus: None` ensures
they never steal keyboard focus.

Touch coordinates are relative to each panel. `MouseArea` captures
single-finger drags; accumulated pixel distance maps to step changes
in volume/brightness.

Orientation-aware: WlrLayershell anchors follow Hyprland's monitor
transform, so "bottom" stays bottom after screen rotation.

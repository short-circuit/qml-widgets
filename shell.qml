import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// ============================================================
// Touch Gesture Widgets
// Edge-swipe to control OSK, volume, and brightness.
// Runs as: qs -p <this-dir>
// ============================================================

// ─── 1. Bottom edge: swipe up → on-screen keyboard ─────────
PanelWindow {
    id: oskTrigger

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 25

    WlrLayershell.namespace: "touch-widgets:osk"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    property real startY: 0
    property bool armed: false

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => { startY = mouse.y; armed = true }
        onPositionChanged: (mouse) => {
            if (armed && mouse.y - startY < -80) {
                armed = false
                toggleOsk.start()
            }
        }
        onReleased: { armed = false }
    }

    Process {
        id: toggleOsk
        command: ["qs", "-c", "ii", "ipc", "call", "osk", "toggle"]
        running: false
    }
}

// ─── 2. Left edge: vertical swipe → volume ─────────────────
PanelWindow {
    id: volumeControl

    anchors.top: true
    anchors.left: true
    anchors.bottom: true
    implicitWidth: 18

    WlrLayershell.namespace: "touch-widgets:volume"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    readonly property real stepPx: 25  // pixels per volume step

    property real accum: 0
    property real lastY: 0
    property bool active: false

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => { lastY = mouse.y; accum = 0; active = true }
        onPositionChanged: (mouse) => {
            if (!active) return
            var delta = lastY - mouse.y
            accum += delta
            lastY = mouse.y

            while (accum >= stepPx) { accum -= stepPx; volUp.start() }
            while (accum <= -stepPx) { accum += stepPx; volDown.start() }
        }
        onReleased: { active = false }
    }

    Process { id: volUp;   command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]; running: false }
    Process { id: volDown; command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]; running: false }
}

// ─── 3. Top edge: horizontal swipe → brightness ────────────
PanelWindow {
    id: brightnessControl

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 18

    WlrLayershell.namespace: "touch-widgets:brightness"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    readonly property real stepPx: 30  // pixels per brightness step

    property real accum: 0
    property real lastX: 0
    property bool active: false

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => { lastX = mouse.x; accum = 0; active = true }
        onPositionChanged: (mouse) => {
            if (!active) return
            var delta = mouse.x - lastX
            accum += delta
            lastX = mouse.x

            while (accum >= stepPx) { accum -= stepPx; briUp.start() }
            while (accum <= -stepPx) { accum += stepPx; briDown.start() }
        }
        onReleased: { active = false }
    }

    Process { id: briUp;   command: ["brightnessctl", "set", "5%+"]; running: false }
    Process { id: briDown; command: ["brightnessctl", "set", "5%-"]; running: false }
}

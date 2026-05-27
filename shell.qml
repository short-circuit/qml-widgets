import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    // ── Bottom edge: swipe up → on-screen keyboard ──────────
    PanelWindow {
        id: oskTrigger

        anchors {
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: 0
        implicitHeight: 25
        WlrLayershell.namespace: "touch-widgets:osk"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        property real startY: 0
        property bool armed: false

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                oskTrigger.startY = mouse.y;
                oskTrigger.armed = true;
            }
            onPositionChanged: (mouse) => {
                if (oskTrigger.armed && mouse.y - oskTrigger.startY < -80) {
                    oskTrigger.armed = false;
                    toggleOsk.running = true;
                }
            }
            onReleased: {
                oskTrigger.armed = false;
            }
        }

        Process {
            id: toggleOsk
            command: ["qs", "-c", "ii", "ipc", "call", "osk", "toggle"]
            running: false
        }
    }

    // ── Left edge: swipe up/down → volume ───────────────────
    PanelWindow {
        id: volumeControl

        anchors {
            top: true
            left: true
            bottom: true
        }

        exclusiveZone: 0
        implicitWidth: 18
        WlrLayershell.namespace: "touch-widgets:volume"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        property real accum: 0
        property real lastY: 0
        property bool active: false

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                volumeControl.lastY = mouse.y;
                volumeControl.accum = 0;
                volumeControl.active = true;
            }
            onPositionChanged: (mouse) => {
                if (!volumeControl.active)
                    return;
                var delta = volumeControl.lastY - mouse.y;
                volumeControl.accum += delta;
                volumeControl.lastY = mouse.y;

                while (volumeControl.accum >= 25) {
                    volumeControl.accum -= 25;
                    volUp.running = true;
                }
                while (volumeControl.accum <= -25) {
                    volumeControl.accum += 25;
                    volDown.running = true;
                }
            }
            onReleased: {
                volumeControl.active = false;
            }
        }

        Process {
            id: volUp
            command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]
            running: false
        }

        Process {
            id: volDown
            command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
            running: false
        }
    }

    // ── Top edge: swipe left/right → brightness ─────────────
    PanelWindow {
        id: brightnessControl

        anchors {
            top: true
            left: true
            right: true
        }

        exclusiveZone: 0
        implicitHeight: 18
        WlrLayershell.namespace: "touch-widgets:brightness"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        property real accum: 0
        property real lastX: 0
        property bool active: false

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => {
                brightnessControl.lastX = mouse.x;
                brightnessControl.accum = 0;
                brightnessControl.active = true;
            }
            onPositionChanged: (mouse) => {
                if (!brightnessControl.active)
                    return;
                var delta = mouse.x - brightnessControl.lastX;
                brightnessControl.accum += delta;
                brightnessControl.lastX = mouse.x;

                while (brightnessControl.accum >= 30) {
                    brightnessControl.accum -= 30;
                    briUp.running = true;
                }
                while (brightnessControl.accum <= -30) {
                    brightnessControl.accum += 30;
                    briDown.running = true;
                }
            }
            onReleased: {
                brightnessControl.active = false;
            }
        }

        Process {
            id: briUp
            command: ["brightnessctl", "set", "5%+"]
            running: false
        }

        Process {
            id: briDown
            command: ["brightnessctl", "set", "5%-"]
            running: false
        }
    }
}

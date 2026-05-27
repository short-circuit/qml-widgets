import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

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
                startY = mouse.y;
                armed = true;
            }
            onPositionChanged: (mouse) => {
                if (armed && mouse.y - startY < -80) {
                    armed = false;
                    toggleOsk.start();
                }
            }
            onReleased: {
                armed = false;
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
                lastY = mouse.y;
                accum = 0;
                active = true;
            }
            onPositionChanged: (mouse) => {
                if (!active)
                    return;
                var delta = lastY - mouse.y;
                accum += delta;
                lastY = mouse.y;

                while (accum >= 25) {
                    accum -= 25;
                    volUp.start();
                }
                while (accum <= -25) {
                    accum += 25;
                    volDown.start();
                }
            }
            onReleased: {
                active = false;
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
                lastX = mouse.x;
                accum = 0;
                active = true;
            }
            onPositionChanged: (mouse) => {
                if (!active)
                    return;
                var delta = mouse.x - lastX;
                accum += delta;
                lastX = mouse.x;

                while (accum >= 30) {
                    accum -= 30;
                    briUp.start();
                }
                while (accum <= -30) {
                    accum += 30;
                    briDown.start();
                }
            }
            onReleased: {
                active = false;
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

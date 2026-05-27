import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    // ── State ─────────────────────────────────────────────────
    property string dockEdge: "bottom"   // bottom | left | right
    property bool hotkeyVisible: false
    property var currentProfile: null
    property var profiles: ({})
    property var positionFile: Quickshell.environmentVariables["HOME"] +
        "/.local/state/touch-hotkeys/position.json"

    // ── Position persistence ──────────────────────────────────
    function savePosition() {
        var dir = Quickshell.environmentVariables["HOME"] + "/.local/state/touch-hotkeys";
        var json = JSON.stringify({edge: dockEdge});
        // Single sh -c command: pass values as positional args ($1, $2, $3)
        // to avoid shell injection from JSON content
        saver.command = ["sh", "-c",
            "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"",
            "sh", dir, json, positionFile];
        saver.running = true;
    }

    Process { id: saver; running: false }

    Process {
        id: posReader
        command: ["cat", positionFile]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text.trim());
                    if (d.edge) root.dockEdge = d.edge;
                } catch(e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                /* first run — no position file yet */
            }
        }
    }

    // ── Hotkey profiles loader ────────────────────────────────
    Process {
        id: profileLoader
        command: ["cat", Quickshell.environmentVariables["HOME"] +
            "/.config/quickshell/touch-hotkeys/profiles.json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text.trim());
                    root.profiles = d.profiles || {};
                    root.updateProfile(); // re-evaluate for current window
                } catch(e) {
                    console.log("touch-hotkeys: failed to parse profiles:", e);
                }
            }
        }
    }

    // ── ydotool key sender ────────────────────────────────────

    // ydotool keycodes: 1 = press, 0 = release
    // Key sequence: press and release each key in order
    function sendKeys(keycodes) {
        var args = ["key", "--key-delay", "10"];
        for (var i = 0; i < keycodes.length; i++) {
            args.push(keycodes[i] + ":1");  // press
        }
        for (var i = keycodes.length - 1; i >= 0; i--) {
            args.push(keycodes[i] + ":0");  // release (reverse order)
        }
        ydotool.command = ["ydotool"].concat(args);
        ydotool.running = true;
    }

    Process {
        id: ydotool
        running: false
    }

    // ── Focus tracking ────────────────────────────────────────
    onCurrentProfileChanged: {
        hotkeyVisible = currentProfile != null;
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            updateProfile();
        }
    }

    function updateProfile() {
        var cls = ToplevelManager.activeToplevel?.class || "";
        if (cls.length === 0) {
            currentProfile = null;
            return;
        }
        // Try exact match first, then wildcard-like match for WM_CLASS variants
        var profile = profiles[cls];
        if (!profile) {
            // Try alternative window class formats (e.g. "Navigator" for firefox)
            for (var key in profiles) {
                if (cls.indexOf(key) >= 0 || key.indexOf(cls) >= 0) {
                    profile = profiles[key];
                    break;
                }
            }
        }
        currentProfile = profile;
    }

    // ── Toggle hotkey bar via IPC ─────────────────────────────
    IpcHandler {
        target: "touch-hotkeys"
        function toggle(): void {
            root.hotkeyVisible = !root.hotkeyVisible;
        }
        function show(): void {
            root.hotkeyVisible = true;
        }
        function hide(): void {
            root.hotkeyVisible = false;
        }
    }

    // ── Position cycle helper ─────────────────────────────────
    function cyclePosition() {
        var order = ["bottom", "left", "right"];
        var idx = order.indexOf(dockEdge);
        dockEdge = order[(idx + 1) % order.length];
        savePosition();
    }

    // ── Main panel ────────────────────────────────────────────
    PanelWindow {
        id: panel

        anchors {
            bottom: dockEdge === "bottom" ? parent.bottom : undefined
            left:   dockEdge === "left"   ? parent.left   : undefined
            right:  dockEdge === "right"  ? parent.right  : undefined
        }

        exclusiveZone: 0
        WlrLayershell.namespace: "touch-hotkeys:bar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        visible: hotkeyVisible

        implicitWidth: dockEdge === "bottom" ? (parent?.width ?? 800) : 320
        implicitHeight: dockEdge === "bottom" ? content.implicitHeight + Theme.padding * 2 : 400

        // ── Background ────────────────────────────────────────
        Rectangle {
            id: bg
            anchors.fill: parent
            color: Theme.surfaceContainer
            radius: Theme.rounding
            border.width: 1
            border.color: Theme.outlineVariant
        }

        // ── Content ──────────────────────────────────────────
        ColumnLayout {
            id: content
            anchors {
                fill: parent
                margins: Theme.padding
            }
            spacing: Theme.spacing

            // ── Header ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing

                Text {
                    text: currentProfile?.label ?? ""
                    color: Theme.onSurface
                    font.pixelSize: Theme.fontSize + 2
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Position cycle button
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Theme.buttonRounding
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: "⇱"
                        color: Theme.onSurface
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cyclePosition();
                    }
                }

                // Close button
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Theme.buttonRounding
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.onSurface
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: hotkeyVisible = false;
                    }
                }
            }

            // ── Scrollable button area ────────────────────────
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: sectionsColumn.implicitHeight
                clip: true

                Column {
                    id: sectionsColumn
                    width: parent.width
                    spacing: Theme.sectionGap

                    Repeater {
                        model: currentProfile?.sections ?? []

                        Column {
                            width: parent.width
                            spacing: Theme.spacing

                            // Section label
                            Text {
                                text: modelData.name ?? ""
                                color: Theme.onSurfaceVariant
                                font.pixelSize: Theme.sectionFontSize
                                font.capitalization: Font.AllUppercase
                                leftPadding: 2
                            }

                            // Buttons
                            Flow {
                                width: parent.width
                                spacing: Theme.spacing

                                Repeater {
                                    model: modelData.buttons ?? []

                                    Rectangle {
                                        implicitWidth: Math.max(
                                            Theme.buttonMinWidth,
                                            labelBtn.implicitWidth + Theme.padding * 2)
                                        implicitHeight: Theme.buttonHeight
                                        radius: Theme.buttonRounding
                                        color: Theme.surfaceContainerHigh

                                        Text {
                                            id: labelBtn
                                            anchors.centerIn: parent
                                            text: modelData.label ?? ""
                                            color: Theme.onSurface
                                            font.pixelSize: Theme.fontSize
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (modelData.keys) {
                                                    root.sendKeys(modelData.keys);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

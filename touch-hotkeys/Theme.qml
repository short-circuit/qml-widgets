pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    // Material3 colors — fallback defaults matching illogical-impulse's dark theme
    readonly property color background:           _background
    readonly property color surface:              _surface
    readonly property color surfaceContainer:     _surfaceContainer
    readonly property color surfaceBright:        _surfaceBright
    readonly property color surfaceDim:           _surfaceDim
    readonly property color surfaceContainerLow:  _surfaceContainerLow
    readonly property color surfaceContainerHigh: _surfaceContainerHigh
    readonly property color onSurface:            _onSurface
    readonly property color onSurfaceVariant:     _onSurfaceVariant
    readonly property color primary:              _primary
    readonly property color onPrimary:            _onPrimary
    readonly property color primaryContainer:     _primaryContainer
    readonly property color secondary:            _secondary
    readonly property color outline:              _outline
    readonly property color outlineVariant:       _outlineVariant
    readonly property color error:                _error
    readonly property color shadow:               _shadow
    readonly property color scrim:                _scrim

    // Internal mutable values (updated from JSON)
    property color _background:           "#141313"
    property color _surface:              "#141313"
    property color _surfaceContainer:     "#201f20"
    property color _surfaceBright:        "#3a3939"
    property color _surfaceDim:           "#141313"
    property color _surfaceContainerLow:  "#1c1b1c"
    property color _surfaceContainerHigh: "#2b2a2a"
    property color _onSurface:            "#e6e1e1"
    property color _onSurfaceVariant:     "#cbc5ca"
    property color _primary:              "#cbc4cb"
    property color _onPrimary:            "#343336"
    property color _primaryContainer:     "#565f6a"
    property color _secondary:            "#cbc4cb"
    property color _outline:              "#948f94"
    property color _outlineVariant:       "#49464a"
    property color _error:                "#ba1a1a"
    property color _shadow:               "#000000"
    property color _scrim:                "#000000"

    // Layout constants
    readonly property int rounding: 12
    readonly property int buttonRounding: 8
    readonly property int spacing: 6
    readonly property int padding: 10
    readonly property int buttonHeight: 42
    readonly property int buttonMinWidth: 48
    readonly property int sectionGap: 12
    readonly property int fontSize: 13
    readonly property int sectionFontSize: 11

    // Path to matugen-generated colors
    readonly property string colorFilePath: homeDir() + "/.local/state/quickshell/user/generated/colors.json"

    function homeDir() {
        var env = Quickshell.environmentVariables;
        return env["HOME"] || "/home/shortcircuit";
    }

    function loadColors() {
        reader.command = ["sh", "-c",
            "test -f \"$1\" && cat \"$1\" || true", "sh", colorFilePath];
        reader.running = true;
    }

    function applyColors(json) {
        if (json.background)           _background           = json.background;
        if (json.surface)              _surface              = json.surface;
        if (json.surface_container)    _surfaceContainer     = json.surface_container;
        if (json.surface_bright)       _surfaceBright        = json.surface_bright;
        if (json.surface_dim)          _surfaceDim           = json.surface_dim;
        if (json.surface_container_low) _surfaceContainerLow = json.surface_container_low;
        if (json.surface_container_high) _surfaceContainerHigh = json.surface_container_high;
        if (json.on_surface)           _onSurface            = json.on_surface;
        if (json.on_surface_variant)   _onSurfaceVariant     = json.on_surface_variant;
        if (json.primary)              _primary              = json.primary;
        if (json.on_primary)           _onPrimary            = json.on_primary;
        if (json.primary_container)    _primaryContainer     = json.primary_container;
        if (json.secondary)            _secondary            = json.secondary;
        if (json.outline)              _outline              = json.outline;
        if (json.outline_variant)      _outlineVariant       = json.outline_variant;
        if (json.error)                _error                = json.error;
        if (json.shadow)               _shadow               = json.shadow;
        if (json.scrim)                _scrim                = json.scrim;
    }

    Process {
        id: reader
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var text = this.text.trim();
                    if (text.length > 0) {
                        var json = JSON.parse(text);
                        theme.applyColors(json);
                        theme._found = true;
                    }
                } catch (e) {
                    console.log("touch-hotkeys: failed to parse theme colors:", e);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (!theme._found) {
                    console.log("touch-hotkeys: theme file not found, using defaults");
                    theme._found = true; // log once, then stop spamming
                }
            }
        }
    }

    property bool _found: false

    Timer {
        id: reloadTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            // Re-read colors periodically (catches matugen file updates)
            loadColors();
        }
    }
}

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Loader {
        id: wallpaperSelectorLoader
        // Keep the gallery and its image delegates alive so previews are
        // decoded before the first Super+W press.
        active: true

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaperSelector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.wallpaperSelectorOpen
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None
            color: "transparent"
            visible: true

            // A full-monitor transparent layer lets the compact surface be
            // genuinely centered while its input mask remains surface-only.
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: GlobalStates.wallpaperSelectorOpen ? content : null
            }

            Connections {
                target: GlobalStates
                function onWallpaperSelectorOpenChanged() {
                    if (GlobalStates.wallpaperSelectorOpen) {
                        GlobalFocusGrab.addDismissable(panelWindow);
                    } else {
                        GlobalFocusGrab.removeDismissable(panelWindow);
                    }
                }
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }

            WallpaperSelectorContent {
                id: content
                anchors.centerIn: parent
                width: Math.min(Appearance.sizes.wallpaperSelectorWidth,
                    panelWindow.width - Appearance.sizes.hyprlandGapsOut * 4)
                height: Math.min(Appearance.sizes.wallpaperSelectorHeight,
                    panelWindow.height - Appearance.sizes.hyprlandGapsOut * 4)
            }
        }
    }

    function toggleWallpaperSelector() {
        if (Config.options.wallpaperSelector.useSystemFileDialog) {
            Wallpapers.openFallbackPicker(Appearance.m3colors.darkmode);
            return;
        }
        GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggleWallpaperSelector();
        }

        function random(): void {
            Wallpapers.randomFromCurrentFolder();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: {
            root.toggleWallpaperSelector();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: {
            Wallpapers.randomFromCurrentFolder();
        }
    }
}

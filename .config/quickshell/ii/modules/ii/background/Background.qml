pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot

        required property var modelData

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        property int workspaceChunkSize: Config?.options.bar.workspaces.shown ?? 10
        property int totalWorkspaces: Math.ceil(lastWorkspaceId / workspaceChunkSize) * workspaceChunkSize
        // Wallpaper
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        readonly property real parallaxRation: Config.options.background.parallax.workspaceZoom
        property bool frontWallpaperActive: true
        property var incomingWallpaper: null
        property var outgoingWallpaper: null
        readonly property var activeWallpaper: frontWallpaperActive ? frontWallpaper : backWallpaper
        // Colors
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Overlay : WlrLayer.Bottom
        // WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        onWallpaperPathChanged: bgRoot.stageWallpaper(bgRoot.wallpaperPath)

        function stageWallpaper(path) {
            if (!path || bgRoot.wallpaperIsVideo || bgRoot.wallpaperSafetyTriggered) return;
            const target = bgRoot.frontWallpaperActive ? backWallpaper : frontWallpaper;
            target.pendingPath = path;
            target.pendingActivation = true;
            target.opacity = 0;
            // Clear first so selecting a recently used image still emits a
            // complete loading cycle before the crossfade starts.
            target.source = "";
            Qt.callLater(() => target.source = path);
        }

        function activateStagedWallpaper(target) {
            if (!target.pendingActivation || target.status !== Image.Ready || target.sourceSize.width <= 0) return;
            target.pendingActivation = false;
            bgRoot.incomingWallpaper = target;
            bgRoot.outgoingWallpaper = target === frontWallpaper ? backWallpaper : frontWallpaper;
            wallpaperCrossfade.restart();
        }

        Component.onCompleted: {
            if (!bgRoot.wallpaperIsVideo && !bgRoot.wallpaperSafetyTriggered) {
                frontWallpaper.source = bgRoot.wallpaperPath;
                frontWallpaper.opacity = 1;
            }
        }

        Item {
            anchors.fill: parent

            Item {
                id: wallpaperStack
                anchors.fill: parent
                visible: !blurLoader.active && !bgRoot.wallpaperIsVideo && !bgRoot.wallpaperSafetyTriggered

                WallpaperLayer { id: frontWallpaper }
                WallpaperLayer { id: backWallpaper }
            }

            // Use a plain Image here: StyledImage intentionally binds
            // sourceSize to width for icons, which would make a full-screen
            // wallpaper's natural dimensions recursively depend on its crop.
            component WallpaperLayer: Image {
                property bool pendingActivation: false
                property string pendingPath: ""
                readonly property real naturalWidth: sourceSize.width > 0 ? sourceSize.width : bgRoot.screen.width
                readonly property real naturalHeight: sourceSize.height > 0 ? sourceSize.height : bgRoot.screen.height
                readonly property real minSuitableScale: Math.max(bgRoot.screen.width / naturalWidth, bgRoot.screen.height / naturalHeight)
                readonly property real effectiveScale: minSuitableScale * bgRoot.parallaxRation
                readonly property real overflowX: Math.max(0, width - bgRoot.screen.width)
                readonly property real overflowY: Math.max(0, height - bgRoot.screen.height)
                readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && naturalHeight > naturalWidth) || Config.options.background.parallax.vertical
                property int workspaceIndex: (bgRoot.monitor.activeWorkspace?.id ?? 1) - 1
                readonly property real workspaceFraction: bgRoot.totalWorkspaces <= 1
                    ? 0.5 : Math.max(0, Math.min(1, workspaceIndex / (bgRoot.totalWorkspaces - 1)))
                readonly property real usedFractionX: {
                    let value = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && !verticalParallax) value = workspaceFraction;
                    if (Config.options.background.parallax.enableSidebar) {
                        const sidebarFraction = bgRoot.parallaxRation / bgRoot.workspaceChunkSize / 2;
                        value += sidebarFraction * GlobalStates.sidebarRightOpen - sidebarFraction * GlobalStates.sidebarLeftOpen;
                    }
                    return Math.max(0, Math.min(1, value));
                }
                readonly property real usedFractionY: Config.options.background.parallax.enableWorkspace && verticalParallax
                    ? workspaceFraction : 0.5

                opacity: 0
                cache: false
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                width: naturalWidth * effectiveScale
                height: naturalHeight * effectiveScale
                x: bgRoot.screen.width > width ? (bgRoot.screen.width - width) / 2 : -overflowX * usedFractionX
                y: bgRoot.screen.height > height ? (bgRoot.screen.height - height) / 2 : -overflowY * usedFractionY
                onStatusChanged: bgRoot.activateStagedWallpaper(this)
                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ParallelAnimation {
                id: wallpaperCrossfade
                NumberAnimation {
                    target: bgRoot.incomingWallpaper
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 520
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    target: bgRoot.outgoingWallpaper
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 420
                    easing.type: Easing.OutCubic
                }
                onFinished: {
                    bgRoot.frontWallpaperActive = bgRoot.incomingWallpaper === frontWallpaper;
                    bgRoot.outgoingWallpaper.source = "";
                    bgRoot.outgoingWallpaper = null;
                    bgRoot.incomingWallpaper = null;
                }
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                anchors.fill: wallpaperStack
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: wallpaperStack
                    radius: GlobalStates.screenLocked ? Config.options.lock.blur.radius : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            WidgetCanvas {
                id: widgetCanvas
                width: parent.width
                height: parent.height
                readonly property real parallaxFactor: {
                    var f = Config.options.background.parallax.widgetsFactor;
                    return f / bgRoot.parallaxRation;
                }
                readonly property real baseWallpaperOffsetX: (bgRoot.screen.width - bgRoot.activeWallpaper.width) / 2
                readonly property real baseWallpaperOffsetY: (bgRoot.screen.height - bgRoot.activeWallpaper.height) / 2
                readonly property real wallpaperTotalOffsetX: bgRoot.activeWallpaper.x - baseWallpaperOffsetX
                readonly property real wallpaperTotalOffsetY: bgRoot.activeWallpaper.y - baseWallpaperOffsetY
                readonly property bool locked: GlobalStates.screenLocked
                x: wallpaperTotalOffsetX * parallaxFactor * !locked
                y: wallpaperTotalOffsetY * parallaxFactor * !locked

                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.weather.enable
                    sourceComponent: WeatherWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.clock.enable
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }
            }
        }
    }
}

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    property bool useDarkMode: Appearance.m3colors.darkmode
    readonly property list<string> featuredWallpaperNames: [
        "Anime-Girl1.png",
        "Anime-Girl2.png",
        "Anime-Girl3.png"
    ]
    property var galleryEntries: []
    property bool gridMode: false
    // 0 = current wallpaper home, 1 = all wallpapers, 2 = favorites
    property int viewMode: 1
    readonly property string currentWallpaperPath: Config.options.background.wallpaperPath
    readonly property string currentWallpaperName: currentWallpaperPath.split("/").pop() || Translation.tr("Current wallpaper")
    readonly property int gridColumns: Math.max(1, Math.floor(grid.width / 205))
    enabled: GlobalStates.wallpaperSelectorOpen
    visible: opacity > 0
    opacity: GlobalStates.wallpaperSelectorOpen ? 1 : 0
    scale: GlobalStates.wallpaperSelectorOpen ? 1 : 0.965
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation {
            duration: GlobalStates.wallpaperSelectorOpen ? 170 : 120
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: GlobalStates.wallpaperSelectorOpen ? 210 : 130
            easing.type: Easing.OutCubic
        }
    }

    function updateThumbnails() {
        Wallpapers.generateThumbnail("xx-large");
    }

    function revealSelection(immediate = false) {
        if (grid.currentIndex < 0 || grid.count === 0) return;
        if (root.gridMode) {
            galleryScrollAnimation.stop();
            grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
            return;
        }
        const itemStart = grid.currentIndex * grid.cellWidth;
        const centered = itemStart - (grid.width - grid.cellWidth) / 2;
        const targetX = Math.max(0, Math.min(Math.max(0, grid.contentWidth - grid.width), centered));
        if (immediate) {
            galleryScrollAnimation.stop();
            grid.contentX = targetX;
        } else {
            galleryScrollAnimation.from = grid.contentX;
            galleryScrollAnimation.to = targetX;
            galleryScrollAnimation.restart();
        }
    }

    function moveSelection(delta) {
        if (grid.count === 0) return;
        grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex + delta));
        root.revealSelection();
    }

    function moveSelectionForKey(key) {
        if (!root.gridMode) {
            if (key === Qt.Key_Left || key === Qt.Key_Up) root.moveSelection(-1);
            else root.moveSelection(1);
            return;
        }
        if (key === Qt.Key_Left) root.moveSelection(-1);
        else if (key === Qt.Key_Right) root.moveSelection(1);
        else if (key === Qt.Key_Up) root.moveSelection(-root.gridColumns);
        else if (key === Qt.Key_Down) root.moveSelection(root.gridColumns);
    }

    function rebuildGallery() {
        const featured = ({ });
        const remaining = [];
        const seenPaths = new Set();

        for (let i = 0; i < Wallpapers.folderModel.count; i++) {
            const entry = {
                fileName: Wallpapers.folderModel.get(i, "fileName"),
                filePath: Wallpapers.folderModel.get(i, "filePath"),
                fileIsDir: Wallpapers.folderModel.get(i, "fileIsDir")
            };

            const normalizedPath = Wallpapers.normalizedPath(entry.filePath);
            if (!normalizedPath.length || seenPaths.has(normalizedPath)) continue;
            seenPaths.add(normalizedPath);
            entry.filePath = normalizedPath;

            if (root.viewMode === 2 && !Wallpapers.isFavorite(entry.filePath)) continue;

            if (root.featuredWallpaperNames.indexOf(entry.fileName) !== -1) {
                featured[entry.fileName] = entry;
            } else {
                remaining.push(entry);
            }
        }

        const orderedFeatured = [];
        for (const name of root.featuredWallpaperNames) {
            if (featured[name] !== undefined) orderedFeatured.push(featured[name]);
        }
        root.galleryEntries = orderedFeatured.concat(remaining);
    }

    function switchView(mode) {
        const targetMode = Math.max(0, Math.min(2, mode));
        galleryScrollAnimation.stop();
        root.viewMode = targetMode;
        galleryRebuildTimer.stop();

        grid.contentX = 0;
        grid.contentY = 0;

        if (targetMode === 0) {
            grid.currentIndex = -1;
            root.forceActiveFocus();
            return;
        }

        root.rebuildGallery();
        grid.currentIndex = root.galleryEntries.length > 0 ? 0 : -1;
        if (grid.currentIndex >= 0) root.revealSelection(true);
        Qt.callLater(() => filterField.forceActiveFocus());
    }

    function activateCurrent() {
        if (grid.currentIndex < 0 || grid.currentIndex >= grid.count) return;
        const path = root.galleryEntries[grid.currentIndex]?.filePath ?? "";
        if (path && path.length > 0) Wallpapers.select(path, root.useDarkMode);
    }

    function prepareForOpen() {
        filterField.text = "";
        Wallpapers.searchQuery = "";
        root.switchView(1);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            root.moveSelectionForKey(event.key);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            root.moveSelectionForKey(event.key);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace && filterField.text.length > 0) {
            filterField.text = filterField.text.slice(0, -1);
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.text && event.text.length > 0 && !(event.modifiers & Qt.ControlModifier)) {
            filterField.text += event.text;
            filterField.cursorPosition = filterField.text.length;
            filterField.forceActiveFocus();
            event.accepted = true;
        }
    }

    StyledRectangularShadow { target: gallerySurface }

    Rectangle {
        id: gallerySurface
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 7

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 38
                spacing: 6

                RippleButton {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    buttonRadius: Appearance.rounding.small
                    toggled: root.viewMode === 0
                    onClicked: root.switchView(0)
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "home"
                        iconSize: 20
                        color: root.viewMode === 0 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    }
                    StyledToolTip { text: Translation.tr("Current wallpaper") }
                }

                ToolbarTextField {
                    id: filterField
                    visible: root.viewMode !== 0
                    Layout.preferredWidth: 310
                    Layout.minimumHeight: 38
                    Layout.preferredHeight: 38
                    Layout.maximumHeight: 38
                    implicitHeight: 38
                    font.pixelSize: Appearance.font.pixelSize.small
                    placeholderText: Translation.tr("Search wallpapers")

                    onTextChanged: {
                        Wallpapers.searchQuery = text;
                        galleryRebuildTimer.restart();
                    }

                    Keys.onPressed: event => {
                        // Search keeps keyboard focus for immediate typing, but
                        // navigation keys always operate the wallpaper view.
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Up ||
                            event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                            root.moveSelectionForKey(event.key);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home) {
                            grid.currentIndex = grid.count > 0 ? 0 : -1;
                            if (grid.currentIndex >= 0) root.revealSelection();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End) {
                            grid.currentIndex = grid.count - 1;
                            if (grid.currentIndex >= 0) root.revealSelection();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activateCurrent();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            GlobalStates.wallpaperSelectorOpen = false;
                            event.accepted = true;
                        }
                    }
                }

                RippleButton {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    buttonRadius: Appearance.rounding.small
                    toggled: root.gridMode
                    onClicked: {
                        root.gridMode = !root.gridMode;
                        root.switchView(1);
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.gridMode ? "view_carousel" : "grid_view"
                        iconSize: 20
                        color: root.gridMode ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                    }
                    StyledToolTip {
                        text: root.gridMode ? Translation.tr("Carousel view") : Translation.tr("Gallery view")
                    }
                }


                RippleButton {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    buttonRadius: Appearance.rounding.small
                    toggled: root.viewMode === 2
                    onClicked: {
                        root.switchView(root.viewMode === 2 ? 1 : 2);
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.viewMode === 2 ? "favorite" : "favorite_border"
                        iconSize: 20
                        color: root.viewMode === 2 ? "white" : Appearance.colors.colOnLayer1
                    }
                    StyledToolTip { text: Translation.tr("Favorite wallpapers") }
                }
            }

            Item {
                id: galleryRegion
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    id: homeView
                    anchors.fill: parent
                    visible: root.viewMode === 0

                    Image {
                        id: currentWallpaperPreview
                        anchors.fill: parent
                        source: root.currentWallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        mipmap: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0.35; color: "transparent" }
                            GradientStop { position: 1.0; color: "#B8000000" }
                        }
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 18
                        spacing: 4

                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentWallpaperName
                            elide: Text.ElideRight
                            color: "white"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: currentWallpaperPreview.status === Image.Ready
                                ? `${currentWallpaperPreview.sourceSize.width} × ${currentWallpaperPreview.sourceSize.height}  •  ${Wallpapers.wallpapers.length} wallpapers  •  ${Wallpapers.favorites.length} favorites`
                                : Translation.tr("Current desktop wallpaper")
                            color: "#D8FFFFFF"
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.currentWallpaperPath
                            elide: Text.ElideMiddle
                            color: "#BFFFFFFF"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }

                    RippleButton {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 14
                        width: 40
                        height: 40
                        buttonRadius: 20
                        colBackground: Qt.rgba(0.04, 0.04, 0.05, 0.72)
                        onClicked: Wallpapers.toggleFavorite(root.currentWallpaperPath)
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: Wallpapers.isFavorite(root.currentWallpaperPath) ? "favorite" : "favorite_border"
                            iconSize: 22
                            color: Wallpapers.isFavorite(root.currentWallpaperPath) ? "white" : "#A6FFFFFF"
                        }
                        StyledToolTip {
                            text: Wallpapers.isFavorite(root.currentWallpaperPath)
                                ? Translation.tr("Remove favorite") : Translation.tr("Add favorite")
                        }
                    }
                }

                GridView {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    visible: root.viewMode !== 0
                    model: root.galleryEntries
                    currentIndex: count > 0 ? 0 : -1
                    cellWidth: root.gridMode ? width / root.gridColumns : Math.min(292, width / 2.9)
                    cellHeight: root.gridMode ? height / 2 : height
                    flow: root.gridMode ? GridView.LeftToRight : GridView.TopToBottom
                    layoutDirection: Qt.LeftToRight
                    flickableDirection: root.gridMode ? Flickable.VerticalFlick : Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: false
                    highlightMoveDuration: 180
                    highlightFollowsCurrentItem: true
                    cacheBuffer: root.gridMode ? cellHeight * 4 : cellWidth * 5

                    highlight: Rectangle {
                        color: "transparent"
                        radius: Appearance.rounding.normal
                        border.width: 3
                        border.color: Appearance.colors.colPrimary
                        z: 20
                        opacity: grid.currentIndex >= 0 ? 1 : 0
                        scale: 0.985
                        Behavior on opacity { NumberAnimation { duration: 130 } }
                    }

                    NumberAnimation {
                        id: galleryScrollAnimation
                        target: grid
                        property: "contentX"
                        duration: 260
                        easing.type: Easing.OutCubic
                    }

                    onCountChanged: {
                        if (count > 0 && currentIndex < 0) currentIndex = 0;
                    }

                    delegate: WallpaperDirectoryItem {
                        required property var modelData
                        required property int index
                        fileModelData: modelData
                        // The outline follows keyboard and pointer selection.
                        selected: false
                        width: grid.cellWidth
                        height: grid.cellHeight
                        showLabel: false
                        margins: 3
                        padding: 0
                        radius: Appearance.rounding.normal
                        colText: Appearance.colors.colOnLayer0
                        colBackground: index === grid.currentIndex
                            ? Appearance.colors.colSecondaryContainer
                            : ColorUtils.transparentize(Appearance.colors.colLayer1, 0.55)

                        onEntered: grid.currentIndex = index
                        onActivated: {
                            grid.currentIndex = index;
                            root.activateCurrent();
                        }
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: galleryRegion.width
                            height: galleryRegion.height
                            radius: gallerySurface.radius - 8
                        }
                    }
                }

            }
        }
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() { root.updateThumbnails(); }
        function onChanged() { GlobalStates.wallpaperSelectorOpen = false; }
        function onFavoritesChanged() {
            if (root.viewMode === 2) galleryRebuildTimer.restart();
        }
    }

    Connections {
        target: Wallpapers.folderModel
        function onCountChanged() { galleryRebuildTimer.restart(); }
    }


    onViewModeChanged: {
        if (viewMode === 0) root.forceActiveFocus();
    }

    Timer {
        id: galleryRebuildTimer
        interval: 35
        repeat: false
        onTriggered: {
            root.rebuildGallery();
            grid.currentIndex = root.galleryEntries.length > 0 ? 0 : -1;
            if (grid.currentIndex >= 0) root.revealSelection(true);
        }
    }

    Component.onCompleted: galleryRebuildTimer.start()

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                root.prepareForOpen();
            }
        }
    }
}
